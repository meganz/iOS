#import "MEGARequestDelegate.h"

#import "URLType.h"

NS_SWIFT_SENDABLE
@interface MEGAQueryRecoveryLinkRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithRequestCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType;

@end
