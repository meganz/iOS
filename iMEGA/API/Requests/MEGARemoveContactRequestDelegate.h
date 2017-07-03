
#import "MEGABaseRequestDelegate.h"

@interface MEGARemoveContactRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion;

@end
