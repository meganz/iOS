
#import "MEGABaseRequestDelegate.h"

@interface MEGACopyRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initToAttachToChatWithCompletion:(void (^)(void))completion;

@end
