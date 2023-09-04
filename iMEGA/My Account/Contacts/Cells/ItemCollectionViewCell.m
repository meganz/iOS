#import "ItemCollectionViewCell.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#elif MNZ_WIDGET_EXTENSION
#import "MEGAWidgetExtension-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation ItemCollectionViewCell
@end
