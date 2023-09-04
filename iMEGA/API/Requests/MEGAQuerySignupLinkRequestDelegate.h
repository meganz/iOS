#import "MEGARequestDelegate.h"

#import "URLType.h"

@interface MEGAQuerySignupLinkRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType;

@end
