#import "MEGARequestDelegate.h"

@interface MEGAFetchNodesRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
