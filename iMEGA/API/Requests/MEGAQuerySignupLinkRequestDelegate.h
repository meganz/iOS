
#import "MEGABaseRequestDelegate.h"

#import "URLType.h"

@interface MEGAQuerySignupLinkRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType;

@end
