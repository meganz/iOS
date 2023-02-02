#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGASdkManager (CleanUp)

+ (void)localLogout;
+ (void)localLogoutAndCleanUp;

@end

NS_ASSUME_NONNULL_END
