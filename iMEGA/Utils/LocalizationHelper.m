#import "LocalizationHelper.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

NSString *LocalizedString(NSString *key, NSString *comment) {
    return [LocalizationObjC localizedValueForKey:key comment:comment];
}

