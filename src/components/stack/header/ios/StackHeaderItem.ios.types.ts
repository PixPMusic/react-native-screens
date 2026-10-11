import type { ReactElement } from 'react';
import type { ColorValue } from 'react-native';
import type { PlatformIconIOS } from '../../../shared/types';
import type { StackHeaderMenuIOS } from './StackHeaderMenu.ios.types';
import type { StackHeaderItemAxisBehaviorIOS } from '../StackHeaderConfig.ios.types';
import type { StackHeaderItemVisibilityPriorityIOS } from '../StackHeaderConfig.ios.types';

export type StackHeaderItemPlacement =
  | 'leading'
  | 'trailing'
  | 'toolbar'
  | 'title'
  | 'subtitle'
  | 'largeSubtitle';

export type StackHeaderItemProps = {
  placement: StackHeaderItemPlacement;
  itemId?: string | undefined;
  identifier?: string | undefined;
  hidesSharedBackground?: boolean | undefined;
  /** Uses UIKit's search placement item on iOS 26 and later. */
  searchBarPlacement?: boolean | undefined;
  axisBehavior?: StackHeaderItemAxisBehaviorIOS | undefined;
  visibilityPriority?: StackHeaderItemVisibilityPriorityIOS | undefined;
  variant?: 'plain' | 'done' | 'prominent' | undefined;
  tintColor?: ColorValue | undefined;
  width?: number | undefined;
  /** Preferred native button height. Zero uses the default. */
  height?: number | undefined;
  title?: string | undefined;
  icon?: PlatformIconIOS | undefined;
  render?: (() => ReactElement) | undefined;
  menu?: StackHeaderMenuIOS | undefined;
  menuRepresentation?: StackHeaderMenuIOS | undefined;
  disabled?: boolean | undefined;
  onPress?: (() => void) | undefined;
};
