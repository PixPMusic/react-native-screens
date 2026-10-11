#import "RNSSplitScreenController.h"

#import <React/RCTAssert.h>
#import "RNSHeaderCoordinator.h"
#import "RNSContainerItemSupport.h"
#import "RNSSplitHostComponentView.h"
#import "RNSSplitHostController.h"
#import "RNSSplitScreenComponentView.h"

@implementation RNSSplitScreenController {
  RNSSplitScreenComponentView *_splitScreenComponentView;
  RNSContainerItemSupport *_containerItemSupport;
  CADisplayLink *_columnLayoutDisplayLink;
  CFTimeInterval _columnLayoutAnimationEnd;
  UIEdgeInsets _columnAnimationInitialSafeAreaInsets;
  UIEdgeInsets _columnAnimationOriginalAdditionalInsets;

  CGFloat _columnAnimationPrimaryStartEdge;
  BOOL _columnAnimationTracksLeadingEdge;
  BOOL _updatingColumnLayout;
}

- (instancetype)initWithSplitScreenComponentView:(RNSSplitScreenComponentView *)splitScreenComponentView
{
  if (self = [super init]) {
    _splitScreenComponentView = splitScreenComponentView;
    _containerItemSupport = [RNSContainerItemSupport new];
    _headerCoordinator = [[RNSHeaderCoordinator alloc] initWithScreenController:self];
  }

  return self;
}

// Register nested stacks so column navigation can consult their removal guards.
- (void)registerNestedContainer:(id<RNSContainer>)container
{
  [_containerItemSupport registerNestedContainer:container];
}

- (void)unregisterNestedContainer:(id<RNSContainer>)container
{
  [_containerItemSupport unregisterNestedContainer:container];
}

- (nullable id<RNSContainer>)resolveNestedContainer
{
  return [_containerItemSupport resolveNestedContainer];
}

- (nullable UIScrollView *)findContentScrollView
{
  return [_containerItemSupport findContentScrollViewWithCachedScrollView:nil
                                                            heuristicRoot:_splitScreenComponentView];
}

/**
 * @brief Searching for the SplitHost controller
 *
 * It checks whether the parent controller is our host controller.
 * If we're outside the structure, e. g. for inspector represented as a modal,
 * we're searching for that controller using a reference that Screen keeps for Host component view.
 *
 * @return If found - a RNSSplitHostController instance, otherwise nil.
 */
- (nullable RNSSplitHostController *)findSplitHostController
{
  if ([self.splitViewController isKindOfClass:RNSSplitHostController.class]) {
    return (RNSSplitHostController *)self.splitViewController;
  }

  RNSSplitHostComponentView *splitHost = _splitScreenComponentView.splitHost;
  if (splitHost != nil) {
    return splitHost.splitHostController;
  }

  return nil;
}

- (BOOL)isInSplitHostSubtree
{
  return [self.splitViewController isKindOfClass:RNSSplitHostController.class];
}

#pragma mark - Signals

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  // For modals, which are presented outside the SplitHost subtree (and RN hierarchy),
  // we're attaching our touch handler and we don't need to apply any offset corrections,
  // because it's positioned relatively to our RNSSplitScreenComponentView
  if (![self isInSplitHostSubtree]) {
    // A screen leaving its column has no navigation controller anymore; its frame is meaningless then.
    if (self.navigationController == nil) {
      return;
    }
    [_delegate splitScreenController:self didChangeColumnFrame:self.view.frame];
    return;
  }

  UIView *ancestorView = [self findSplitHostController].view;
  RCTAssert(ancestorView != nil, @"[RNScreens] Expected to find RNSSplitHost component for RNSSplitScreen component");

  [self reportColumnFrameInContextOfView:ancestorView];
}

- (void)columnPositioningDidChangeInSplitViewController:(UISplitViewController *)splitViewController
{
  [self reportColumnFrameInContextOfView:splitViewController.view];
}

- (BOOL)isColumnLayoutAnimating
{
  return _columnLayoutDisplayLink != nil;
}

- (void)prepareColumnLayoutAnimationWithDuration:(NSTimeInterval)duration
{
  if (self.view.window == nil || ![self isInSplitHostSubtree])
    return;
  RNSSplitHostController *host = [self findSplitHostController];
  UIView *primaryView = [host viewControllerForColumn:UISplitViewControllerColumnPrimary].viewIfLoaded;
  CGRect primaryFrame = [primaryView convertRect:primaryView.bounds toView:host.view];
  if (_columnLayoutDisplayLink != nil && primaryView.layer.presentationLayer != nil &&
      host.view.layer.presentationLayer != nil) {
    primaryFrame = [primaryView.layer.presentationLayer convertRect:primaryView.layer.presentationLayer.bounds
                                                            toLayer:host.view.layer.presentationLayer];
  }
  _columnLayoutAnimationEnd = CACurrentMediaTime() + duration;
  _columnAnimationInitialSafeAreaInsets = self.view.safeAreaInsets;
  if (_columnLayoutDisplayLink == nil)
    _columnAnimationOriginalAdditionalInsets = self.additionalSafeAreaInsets;
  _columnAnimationTracksLeadingEdge = CGRectGetMidX(primaryFrame) < CGRectGetMidX(host.view.bounds);
  _columnAnimationPrimaryStartEdge =
      _columnAnimationTracksLeadingEdge ? CGRectGetMaxX(primaryFrame) : CGRectGetMinX(primaryFrame);
  if (_columnLayoutDisplayLink == nil) {
    _columnLayoutDisplayLink = [CADisplayLink displayLinkWithTarget:self
                                                           selector:@selector(updateAnimatedColumnLayout:)];
    [_columnLayoutDisplayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
  }
}

- (void)reportColumnFrameInContextOfView:(UIView *)ancestorView
{
  if (_updatingColumnLayout)
    return;
  _updatingColumnLayout = YES;
  // The navigation controller is the column; its screen also moves during pushes and pops.
  UIView *columnView = self.navigationController.view ?: self.view;
  CGRect frame = [columnView convertRect:columnView.bounds toView:ancestorView];
  if (_columnLayoutDisplayLink != nil) {
    RNSSplitHostController *host = [self findSplitHostController];
    UIView *primaryView = [host viewControllerForColumn:UISplitViewControllerColumnPrimary].viewIfLoaded;
    CGRect primaryFrame = [primaryView convertRect:primaryView.bounds toView:ancestorView];
    const CGFloat targetEdge =
        _columnAnimationTracksLeadingEdge ? CGRectGetMaxX(primaryFrame) : CGRectGetMinX(primaryFrame);
    const CGFloat edgeChange = targetEdge - _columnAnimationPrimaryStartEdge;
    CALayer *primaryLayer = primaryView.layer.presentationLayer;
    CALayer *hostLayer = ancestorView.layer.presentationLayer;
    if (fabs(edgeChange) > 0.5 && primaryLayer != nil && hostLayer != nil) {
      CGRect visiblePrimaryFrame = [primaryLayer convertRect:primaryLayer.bounds toLayer:hostLayer];
      const CGFloat visibleEdge =
          _columnAnimationTracksLeadingEdge ? CGRectGetMaxX(visiblePrimaryFrame) : CGRectGetMinX(visiblePrimaryFrame);
      const CGFloat remaining = 1 - MIN(1, MAX(0, (visibleEdge - _columnAnimationPrimaryStartEdge) / edgeChange));
      // The underlaid detail reserves the sidebar through its safe area, not its width.
      // Remove our previous adjustment before deriving UIKit's destination inset.
      UIEdgeInsets currentAdditional = self.additionalSafeAreaInsets;
      UIEdgeInsets targetInsets = self.view.safeAreaInsets;
      targetInsets.left -= currentAdditional.left - _columnAnimationOriginalAdditionalInsets.left;
      targetInsets.right -= currentAdditional.right - _columnAnimationOriginalAdditionalInsets.right;
      UIEdgeInsets additional = _columnAnimationOriginalAdditionalInsets;
      additional.left += (_columnAnimationInitialSafeAreaInsets.left - targetInsets.left) * remaining;
      additional.right += (_columnAnimationInitialSafeAreaInsets.right - targetInsets.right) * remaining;
      if (!UIEdgeInsetsEqualToEdgeInsets(currentAdditional, additional)) {
        // These insets already follow UIKit's presentation edge; do not animate them a second time.
        [UIView performWithoutAnimation:^{
          self.additionalSafeAreaInsets = additional;
          [self.view layoutIfNeeded];
        }];
      }
    }
    // UIKit's model frame is already the destination. Yoga needs the visible column size.
    CALayer *columnLayer = columnView.layer.presentationLayer;
    if (columnLayer != nil && hostLayer != nil) {
      frame = [columnLayer convertRect:columnLayer.bounds toLayer:hostLayer];
    }
  }
  [_delegate splitScreenController:self didChangeColumnFrame:frame];
  _updatingColumnLayout = NO;
}

- (void)columnSafeAreaInsetsDidChange
{
  UIView *ancestorView = [self findSplitHostController].viewIfLoaded;
  if (ancestorView != nil && self.navigationController != nil) {
    [self reportColumnFrameInContextOfView:ancestorView];
  }
}

- (void)updateAnimatedColumnLayout:(CADisplayLink *)displayLink
{
  if (self.view.window == nil || UIAccessibilityIsReduceMotionEnabled() ||
      CACurrentMediaTime() >= _columnLayoutAnimationEnd) {
    [self stopAnimatedColumnLayout];
  }
  UIView *ancestorView = [self findSplitHostController].viewIfLoaded;
  if (ancestorView != nil && self.navigationController != nil) {
    [self reportColumnFrameInContextOfView:ancestorView];
  }
}

- (void)stopAnimatedColumnLayout
{
  if (_columnLayoutDisplayLink == nil)
    return;
  [_columnLayoutDisplayLink invalidate];
  const BOOL wasUpdating = _updatingColumnLayout;
  _updatingColumnLayout = YES;
  [UIView performWithoutAnimation:^{
    self.additionalSafeAreaInsets = _columnAnimationOriginalAdditionalInsets;
    [self.view layoutIfNeeded];
  }];
  UIView *ancestorView = [self findSplitHostController].viewIfLoaded;
  UIView *columnView = self.navigationController.view;
  if (self.view.window != nil && ancestorView != nil && columnView != nil) {
    // Flush the destination inset before ending immediate column updates.
    CGRect frame = [columnView convertRect:columnView.bounds toView:ancestorView];
    [_delegate splitScreenController:self didChangeColumnFrame:frame];
  }
  _columnLayoutDisplayLink = nil;
  _updatingColumnLayout = wasUpdating;
}

#pragma mark - Events

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  // Without a header config the column keeps the system navigation bar, so the coordinator is not consulted.
  if (_splitScreenComponentView.headerConfig != nil) {
    [_headerCoordinator updateNavigationBarVisibilityAnimated:animated];
#if !TARGET_OS_TV
    [_headerCoordinator updateBackButtonMenuEnabled];
#endif // !TARGET_OS_TV
  }
  [_delegate splitScreenControllerWillAppear:self];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [_delegate splitScreenControllerDidAppear:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [_delegate splitScreenControllerWillDisappear:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self stopAnimatedColumnLayout];
  [_delegate splitScreenControllerDidDisappear:self];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
  [super didMoveToParentViewController:parent];

  if (parent != nil) {
    return;
  }

#if !TARGET_OS_TV
  [_headerCoordinator clearAppliedBackButtonConfig];
#endif // !TARGET_OS_TV

  // A screen React still expects on the stack left it natively (e.g. the back button); a detached one was popped on
  // React's request.
  BOOL isNativeDismiss = _splitScreenComponentView.activityMode == RNSStackScreenActivityModeAttached;
  [_delegate splitScreenController:self didDismissNatively:isNativeDismiss];
}

@end
