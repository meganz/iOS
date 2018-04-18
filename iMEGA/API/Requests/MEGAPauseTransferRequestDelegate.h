
#import "MEGABaseRequestDelegate.h"

@interface MEGAPauseTransferRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
