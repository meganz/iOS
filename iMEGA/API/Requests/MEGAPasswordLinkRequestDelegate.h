
#import "MEGABaseRequestDelegate.h"

@interface MEGAPasswordLinkRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks;
- (instancetype)initForDecryptionWithCompletion:(void (^)(MEGARequest *request))completion onError:(void (^)(MEGARequest *request))onError;

@end
