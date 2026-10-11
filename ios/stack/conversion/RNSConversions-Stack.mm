#import "RNSConversions-Stack.h"
#import "RNSDefines.h"

namespace rnscreens::conversion {

namespace react = facebook::react;

#if RNS_IPHONE_OS_VERSION_AVAILABLE(16_0) && !TARGET_OS_TV
UINavigationItemStyle UINavigationItemStyleFromReactRNSHeaderConfigIOSNavigationItemStyle(
    react::RNSHeaderConfigIOSNavigationItemStyle style)
{
  switch (style) {
    case react::RNSHeaderConfigIOSNavigationItemStyle::Navigator:
      return UINavigationItemStyleNavigator;
    case react::RNSHeaderConfigIOSNavigationItemStyle::Browser:
      return UINavigationItemStyleBrowser;
    case react::RNSHeaderConfigIOSNavigationItemStyle::Editor:
      return UINavigationItemStyleEditor;
  }
}
#endif

template <>
RNSStackScreenActivityMode convert(react::RNSStackScreenActivityMode mode)
{
  return static_cast<RNSStackScreenActivityMode>(mode);
}

template <>
RNSHeaderItemPlacement convert(react::RNSHeaderItemIOSPlacement placement)
{
  switch (placement) {
    case react::RNSHeaderItemIOSPlacement::Leading:
      return RNSHeaderItemPlacementLeading;
    case react::RNSHeaderItemIOSPlacement::Trailing:
      return RNSHeaderItemPlacementTrailing;
    case react::RNSHeaderItemIOSPlacement::Toolbar:
      return RNSHeaderItemPlacementToolbar;
    case react::RNSHeaderItemIOSPlacement::Title:
      return RNSHeaderItemPlacementTitle;
    case react::RNSHeaderItemIOSPlacement::Subtitle:
      return RNSHeaderItemPlacementSubtitle;
    case react::RNSHeaderItemIOSPlacement::LargeSubtitle:
      return RNSHeaderItemPlacementLargeSubtitle;
  }
}

UIBarButtonItemStyle UIBarButtonItemStyleFromReactRNSHeaderItemIOSVariant(react::RNSHeaderItemIOSVariant variant)
{
  switch (variant) {
    case react::RNSHeaderItemIOSVariant::Plain:
      return UIBarButtonItemStylePlain;
    case react::RNSHeaderItemIOSVariant::Done:
      return UIBarButtonItemStyleDone;
    case react::RNSHeaderItemIOSVariant::Prominent:
#if RNS_IPHONE_OS_VERSION_AVAILABLE(26_0)
      if (@available(iOS 26.0, *)) {
        return UIBarButtonItemStyleProminent;
      }
#endif // RNS_IPHONE_OS_VERSION_AVAILABLE(26_0)
      // Bold text look, closest counterpart of prominent style before iOS 26
      return UIBarButtonItemStyleDone;
  }
}

template <>
RNSHeaderItemSpacerPlacement convert(react::RNSHeaderItemSpacerIOSPlacement placement)
{
  switch (placement) {
    case react::RNSHeaderItemSpacerIOSPlacement::Leading:
      return RNSHeaderItemSpacerPlacementLeading;
    case react::RNSHeaderItemSpacerIOSPlacement::Trailing:
      return RNSHeaderItemSpacerPlacementTrailing;
    case react::RNSHeaderItemSpacerIOSPlacement::Toolbar:
      return RNSHeaderItemSpacerPlacementToolbar;
  }
}

template <>
UINavigationItemBackButtonDisplayMode convert(react::RNSHeaderConfigIOSBackButtonDisplayMode displayMode)
{
  switch (displayMode) {
    case react::RNSHeaderConfigIOSBackButtonDisplayMode::Default:
      return UINavigationItemBackButtonDisplayModeDefault;
    case react::RNSHeaderConfigIOSBackButtonDisplayMode::Generic:
      return UINavigationItemBackButtonDisplayModeGeneric;
    case react::RNSHeaderConfigIOSBackButtonDisplayMode::Minimal:
      return UINavigationItemBackButtonDisplayModeMinimal;
  }
}

#if RNS_IPHONE_OS_VERSION_AVAILABLE(27_0)

UIBarMinimizationBehavior UIBarMinimizationBehaviorFromReactRNSHeaderConfigIOSMinimizationBehavior(
    react::RNSHeaderConfigIOSMinimizationBehavior minimizationBehavior)
{
  switch (minimizationBehavior) {
    case react::RNSHeaderConfigIOSMinimizationBehavior::Automatic:
      return UIBarMinimizationBehaviorAutomatic;
    case react::RNSHeaderConfigIOSMinimizationBehavior::Never:
      return UIBarMinimizationBehaviorNever;
    case react::RNSHeaderConfigIOSMinimizationBehavior::OnScrollDown:
      return UIBarMinimizationBehaviorOnScrollDown;
    case react::RNSHeaderConfigIOSMinimizationBehavior::OnScrollUp:
      return UIBarMinimizationBehaviorOnScrollUp;
  }
}

UIBarMinimizationRestorationBehavior UIBarMinimizationRestorationBehaviorFromReactRNSHeaderConfigIOSRestorationBehavior(
    react::RNSHeaderConfigIOSRestorationBehavior restorationBehavior)
{
  switch (restorationBehavior) {
    case react::RNSHeaderConfigIOSRestorationBehavior::Automatic:
      return UIBarMinimizationRestorationBehaviorAutomatic;
    case react::RNSHeaderConfigIOSRestorationBehavior::AtScrollEdge:
      return UIBarMinimizationRestorationBehaviorAtScrollEdge;
  }
}

#endif // Check for iOS >= 27

RNSStackScreenActivityMode RNSStackScreenActivityModeFromReactRNSStackScreenActivityMode(
    react::RNSStackScreenActivityMode mode)
{
  return convert<RNSStackScreenActivityMode>(mode);
}
RNSHeaderItemVisibilityPriority RNSHeaderItemVisibilityPriorityFromReactRNSHeaderItemIOSVisibilityPriority(
    react::RNSHeaderItemIOSVisibilityPriority visibilityPriority)
{
  switch (visibilityPriority) {
    case react::RNSHeaderItemIOSVisibilityPriority::Low:
      return RNSHeaderItemVisibilityPriorityLow;
    case react::RNSHeaderItemIOSVisibilityPriority::Standard:
      return RNSHeaderItemVisibilityPriorityStandard;
    case react::RNSHeaderItemIOSVisibilityPriority::High:
      return RNSHeaderItemVisibilityPriorityHigh;
  }
}

#if RNS_IPHONE_OS_VERSION_AVAILABLE(27_0) && !TARGET_OS_TV && !TARGET_OS_VISION
API_AVAILABLE(ios(27.0))
UIBarButtonItemVisibilityPriority UIBarButtonItemVisibilityPriorityFromRNSHeaderItemVisibilityPriority(
    RNSHeaderItemVisibilityPriority visibilityPriority)
{
  switch (visibilityPriority) {
    case RNSHeaderItemVisibilityPriorityLow:
      return UIBarButtonItemVisibilityPriorityLow;
    case RNSHeaderItemVisibilityPriorityStandard:
      return UIBarButtonItemVisibilityPriorityStandard;
    case RNSHeaderItemVisibilityPriorityHigh:
      return UIBarButtonItemVisibilityPriorityHigh;
  }
}
#endif // RNS_IPHONE_OS_VERSION_AVAILABLE(27_0) && !TARGET_OS_TV && !TARGET_OS_VISION

}; // namespace rnscreens::conversion
