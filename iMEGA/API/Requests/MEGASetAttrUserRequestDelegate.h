#import "MEGARequestDelegate.h"

@interface MEGASetAttrUserRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(void))completion;

@end
