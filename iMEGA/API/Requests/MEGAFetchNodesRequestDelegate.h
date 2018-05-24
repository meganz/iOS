
#import "MEGABaseRequestDelegate.h"

@interface MEGAFetchNodesRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
