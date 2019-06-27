
#import "MEGABaseRequestDelegate.h"

#import "URLType.h"

@interface MEGAQueryRecoveryLinkRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithRequestCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType;

@end
