
#import "MEGABaseRequestDelegate.h"

@interface MEGASetAttrUserRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
