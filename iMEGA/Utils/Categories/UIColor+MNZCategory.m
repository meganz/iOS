#import "UIColor+MNZCategory.h"

#import "MEGAChatSdk.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation UIColor (MNZCategory)

#pragma mark - Utils

+ (UIColor *)mnz_colorForChatStatus:(MEGAChatStatus)onlineStatus {
    UIColor *colorForStatusChange;
    switch (onlineStatus) {
        case MEGAChatStatusOffline:
            colorForStatusChange = [self mnz_primaryGrayForTraitCollection:UIScreen.mainScreen.traitCollection];
            break;
            
        case MEGAChatStatusAway:
            colorForStatusChange = [self systemOrangeColor];
            break;
            
        case MEGAChatStatusOnline:
            colorForStatusChange = UIColor.systemGreenColor;
            break;
            
        case MEGAChatStatusBusy:
            colorForStatusChange = [self mnz_redForTraitCollection:UIScreen.mainScreen.traitCollection];
            break;
            
        default:
            colorForStatusChange = nil;
            break;
    }
    
    return colorForStatusChange;
}

@end
