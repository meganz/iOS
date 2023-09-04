#import "MEGARequestDelegate.h"

@interface MEGAPasswordLinkRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks;
- (instancetype)initForDecryptionWithCompletion:(void (^)(MEGARequest *request))completion onError:(void (^)(MEGARequest *request))onError;

@end
