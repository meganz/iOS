#import "MEGAMessagesTypingIndicatorFoorterView.h"

@implementation MEGAMessagesTypingIndicatorFoorterView



#pragma mark - Class methods

+ (UINib *)nib {
    return [UINib nibWithNibName:NSStringFromClass([MEGAMessagesTypingIndicatorFoorterView class])
                          bundle:[NSBundle bundleForClass:[MEGAMessagesTypingIndicatorFoorterView class]]];
}

+ (NSString *)footerReuseIdentifier {
    return NSStringFromClass([MEGAMessagesTypingIndicatorFoorterView class]);
}

@end
