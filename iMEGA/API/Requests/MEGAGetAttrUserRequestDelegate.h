#import "MEGARequestDelegate.h"

@interface MEGAGetAttrUserRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;
- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion error:(void (^)(MEGARequest *request, MEGAError *error))error;

@end
