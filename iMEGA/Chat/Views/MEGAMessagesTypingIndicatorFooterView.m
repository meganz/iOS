#import "MEGAMessagesTypingIndicatorFooterView.h"

@implementation MEGAMessagesTypingIndicatorFooterView



#pragma mark - Class methods

+ (UINib *)nib {
    return [UINib nibWithNibName:NSStringFromClass([MEGAMessagesTypingIndicatorFooterView class])
                          bundle:[NSBundle bundleForClass:[MEGAMessagesTypingIndicatorFooterView class]]];
}

+ (NSString *)footerReuseIdentifier {
    return NSStringFromClass([MEGAMessagesTypingIndicatorFooterView class]);
}

@end
