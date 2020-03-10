
#import "MEGABaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAInviteContactRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests;
- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests presentSuccessOver:(UIViewController *)viewController completion:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
