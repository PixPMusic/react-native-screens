#import "RNSSplitAppearanceApplicator.h"

#import <React/RCTAssert.h>
#import "RNSDefines.h"
#import "RNSScreenWindowTraits.h"
#import "RNSSplitHostController.h"

@implementation RNSSplitAppearanceApplicator

- (void)updateAppearanceIfNeeded:(id<RNSSplitHostAppearanceProvider>)provider
             splitHostController:(RNSSplitHostController *)splitHostController
           appearanceCoordinator:(RNSSplitAppearanceCoordinator *)appearanceCoordinator
{
  __weak auto weakSelf = self;

  [appearanceCoordinator updateIfNeeded:RNSSplitAppearanceUpdateFlagsGeneralUpdate
                         updateCallback:^{
                           auto strongSelf = weakSelf;
                           if (strongSelf == nil) {
                             return;
                           }

                           [strongSelf updateSplitViewConfigurationFor:provider withController:splitHostController];
                         }];

  [appearanceCoordinator updateIfNeeded:RNSSplitAppearanceUpdateFlagsSecondaryScreenNavBarUpdate
                         updateCallback:^{
                           auto strongSelf = weakSelf;
                           if (strongSelf == nil) {
                             return;
                           }

                           [splitHostController refreshSecondaryNavBar];
                         }];

  [appearanceCoordinator updateIfNeeded:RNSSplitAppearanceUpdateFlagsDisplayModeUpdate
                         updateCallback:^{
                           auto strongSelf = weakSelf;
                           if (strongSelf == nil) {
                             return;
                           }

                           [strongSelf updateSplitViewDisplayModeFor:provider withController:splitHostController];
                         }];

  [appearanceCoordinator updateIfNeeded:RNSSplitAppearanceUpdateFlagsOrientationUpdate
                         updateCallback:^{
                           [RNSScreenWindowTraits enforceDesiredDeviceOrientation];
                         }];
}

/**
 * @brief Function that applies all basic updates.
 *
 * It calls all setters on RNSSplitHostController that doesn't require any custom logic and conditions to be met.
 *
 * @param provider The provider of the appearance configuration.
 * @param splitHostController The controller associated with the SplitView component which receives updates and
 * manages the native layer.
 */
- (void)updateSplitViewConfigurationFor:(id<RNSSplitHostAppearanceProvider>)provider
                         withController:(RNSSplitHostController *)splitHostController
{
  // Step 1 - general settings
  splitHostController.displayModeButtonVisibility = provider.displayModeButtonVisibility;
  splitHostController.preferredSplitBehavior = provider.preferredSplitBehavior;
  splitHostController.overrideUserInterfaceStyle = provider.colorScheme;
#if !TARGET_OS_TV
  splitHostController.primaryBackgroundStyle = provider.primaryBackgroundStyle;
#endif
  splitHostController.presentsWithGesture = provider.presentsWithGesture;
  splitHostController.primaryEdge = provider.primaryEdge;
  splitHostController.showsSecondaryOnlyButton = provider.showSecondaryToggleButton;

  // Step 2.1 - validating column constraints
  [self validateColumnConstraintsWithMinWidth:provider.minimumPrimaryColumnWidth
                                     maxWidth:provider.maximumPrimaryColumnWidth];

  [self validateColumnConstraintsWithMinWidth:provider.minimumSupplementaryColumnWidth
                                     maxWidth:provider.maximumSupplementaryColumnWidth];

#if RNS_IPHONE_OS_VERSION_AVAILABLE(26_0) && !TARGET_OS_TV
  if (@available(iOS 26.0, *)) {
    [self validateColumnConstraintsWithMinWidth:provider.minimumInspectorColumnWidth
                                       maxWidth:provider.maximumInspectorColumnWidth];
  }
#endif

  // Step 2.2 - applying updates to columns
  [self updatePrimaryColumnMetricsFor:provider withController:splitHostController];

  if (provider.minimumSupplementaryColumnWidth >= 0) {
    splitHostController.minimumSupplementaryColumnWidth = provider.minimumSupplementaryColumnWidth;
  }

  if (provider.maximumSupplementaryColumnWidth >= 0) {
    splitHostController.maximumSupplementaryColumnWidth = provider.maximumSupplementaryColumnWidth;
  }

  if (provider.preferredSupplementaryColumnWidthOrFraction >= 0 &&
      provider.preferredSupplementaryColumnWidthOrFraction < 1) {
    splitHostController.preferredSupplementaryColumnWidthFraction =
        provider.preferredSupplementaryColumnWidthOrFraction;
  } else if (provider.preferredSupplementaryColumnWidthOrFraction >= 1) {
    splitHostController.preferredSupplementaryColumnWidth = provider.preferredSupplementaryColumnWidthOrFraction;
  }

#if RNS_IPHONE_OS_VERSION_AVAILABLE(26_0) && !TARGET_OS_TV
  if (@available(iOS 26.0, *)) {
    if (provider.minimumSecondaryColumnWidth >= 0) {
      splitHostController.minimumSecondaryColumnWidth = provider.minimumSecondaryColumnWidth;
    }

    if (provider.preferredSecondaryColumnWidthOrFraction >= 0 && provider.preferredSecondaryColumnWidthOrFraction < 1) {
      splitHostController.preferredSecondaryColumnWidthFraction = provider.preferredSecondaryColumnWidthOrFraction;
    } else if (provider.preferredSecondaryColumnWidthOrFraction >= 1) {
      splitHostController.preferredSecondaryColumnWidth = provider.preferredSecondaryColumnWidthOrFraction;
    }

    if (provider.minimumInspectorColumnWidth >= 0) {
      splitHostController.minimumInspectorColumnWidth = provider.minimumInspectorColumnWidth;
    }

    if (provider.maximumInspectorColumnWidth >= 0) {
      splitHostController.maximumInspectorColumnWidth = provider.maximumInspectorColumnWidth;
    }

    if (provider.preferredInspectorColumnWidthOrFraction >= 0 && provider.preferredInspectorColumnWidthOrFraction < 1) {
      splitHostController.preferredInspectorColumnWidthFraction = provider.preferredInspectorColumnWidthOrFraction;
    } else if (provider.preferredInspectorColumnWidthOrFraction >= 1) {
      splitHostController.preferredInspectorColumnWidth = provider.preferredInspectorColumnWidthOrFraction;
    }
  }
#endif

  // Step 2.3 - manipulating with inspector column
  [splitHostController toggleSplitViewInspector:provider.showInspector];
}

// Keep hinge-driven column width changes in UIKit's transition instead of
// snapping to the new preferred width when React receives the updated regions.
- (void)updatePrimaryColumnMetricsFor:(id<RNSSplitHostAppearanceProvider>)provider
                       withController:(RNSSplitHostController *)splitHostController
{
  const CGFloat minimum = provider.minimumPrimaryColumnWidth;
  const CGFloat maximum = provider.maximumPrimaryColumnWidth;
  const CGFloat preferred = provider.preferredPrimaryColumnWidthOrFraction;
  const BOOL usesFraction = preferred >= 0 && preferred < 1;
  const CGFloat currentPreferred = usesFraction ? splitHostController.preferredPrimaryColumnWidthFraction
                                                : splitHostController.preferredPrimaryColumnWidth;
  const BOOL metricsChanged = (minimum >= 0 && minimum != splitHostController.minimumPrimaryColumnWidth) ||
      (maximum >= 0 && maximum != splitHostController.maximumPrimaryColumnWidth) ||
      (preferred >= 0 && preferred != currentPreferred);
  const BOOL hasConfiguredWidth =
      splitHostController.preferredPrimaryColumnWidth != UISplitViewControllerAutomaticDimension ||
      splitHostController.preferredPrimaryColumnWidthFraction != UISplitViewControllerAutomaticDimension;
  UIView *view = splitHostController.viewIfLoaded;
  const BOOL shouldAnimate = metricsChanged && hasConfiguredWidth && view.window != nil &&
      !splitHostController.isCollapsed && !UIAccessibilityIsReduceMotionEnabled();
  void (^applyMetrics)(void) = ^{
    if (minimum >= 0)
      splitHostController.minimumPrimaryColumnWidth = minimum;
    if (maximum >= 0)
      splitHostController.maximumPrimaryColumnWidth = maximum;
    if (usesFraction) {
      splitHostController.preferredPrimaryColumnWidthFraction = preferred;
    } else if (preferred >= 1) {
      splitHostController.preferredPrimaryColumnWidth = preferred;
    }
  };
  if (!shouldAnimate) {
    applyMetrics();
    return;
  }

  [view layoutIfNeeded];
  id<UIViewControllerTransitionCoordinator> coordinator = splitHostController.transitionCoordinator;
  if (coordinator != nil &&
      [coordinator
          animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [splitHostController prepareColumnLayoutAnimationWithDuration:context.transitionDuration];
            applyMetrics();
            [view layoutIfNeeded];
          }
                          completion:nil]) {
    return;
  }
  [UIView animateWithDuration:0.35
                        delay:0
                      options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction |
                      UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     [splitHostController prepareColumnLayoutAnimationWithDuration:0.35];
                     applyMetrics();
                     [view layoutIfNeeded];
                   }
                   completion:nil];
}

/**
 * @brief Function that updates `preferredDisplayMode` property on SplitView.
 *
 * `preferredDisplayMode` needs to have a dedicated flag to prevent updates from the JS, when other props updates the
 * appearance. It is crucial in the case, when `preferredDisplayMode` has changed due to some transition that was
 * executed natively, e. g. after showing/hiding a column by a swipe. In that case, any prop update incoming, would
 * reset `preferredDisplayMode` to the state from JS, what doesn't look good.
 *
 * @param provider The provider of the appearance configuration.
 * @param splitHostController The controller associated with the SplitView component which receives updates and
 * manages the native layer.
 */
- (void)updateSplitViewDisplayModeFor:(id<RNSSplitHostAppearanceProvider>)provider
                       withController:(RNSSplitHostController *)splitHostController
{
  const auto preferredDisplayMode = provider.preferredDisplayMode;
  if (splitHostController.preferredDisplayMode == preferredDisplayMode) {
    return;
  }

  UIView *view = splitHostController.viewIfLoaded;
  // Animate an already displayed split; initial configuration and compact
  // column navigation must not start a sidebar transition.
  const BOOL shouldAnimate = view.window != nil && !splitHostController.isCollapsed &&
      splitHostController.preferredDisplayMode != UISplitViewControllerDisplayModeAutomatic &&
      !UIAccessibilityIsReduceMotionEnabled();
  if (!shouldAnimate) {
    splitHostController.preferredDisplayMode = preferredDisplayMode;
    return;
  }

  [view layoutIfNeeded];
  [UIView animateWithDuration:0.35
                        delay:0
                      options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction |
                          UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     [splitHostController prepareColumnLayoutAnimationWithDuration:0.35];
                     splitHostController.preferredDisplayMode = preferredDisplayMode;
                     [view layoutIfNeeded];
                   }
                   completion:nil];
}

- (void)validateColumnConstraintsWithMinWidth:(CGFloat)minWidth maxWidth:(CGFloat)maxWidth
{
  // Compare values only if both are non-negative.
  // The default value, which is -1, indicates that the constraint was not provided.
  if (minWidth >= 0 && maxWidth >= 0) {
    RCTAssert(minWidth <= maxWidth,
              @"[RNScreens] Split column constraints are invalid: minWidth %f cannot be greater than maxWidth %f",
              minWidth,
              maxWidth);
  }
}

@end
