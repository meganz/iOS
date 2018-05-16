
#import "MEGABaseRequestDelegate.h"

@interface MEGAInviteContactRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests;
- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests presentSuccessOver:(UIViewController *)viewController completion:(void (^)(void))completion;

@end
