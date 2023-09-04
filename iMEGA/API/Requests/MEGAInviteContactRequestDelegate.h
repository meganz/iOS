#import "MEGARequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAInviteContactRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests;
- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests presentSuccessOver:(UIViewController *)viewController completion:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
