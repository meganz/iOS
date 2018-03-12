
#import "MEGABaseRequestDelegate.h"

@interface MEGASetAttrUserRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(void))completion;

@end
