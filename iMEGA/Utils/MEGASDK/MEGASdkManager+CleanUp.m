#import "MEGASdkManager+CleanUp.h"
#import "MEGAGenericRequestDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"

@implementation MEGASdkManager (CleanUp)

+ (void)localLogout {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [MEGASdkManager.sharedMEGASdk localLogoutWithDelegate:[MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        [MEGASdkManager.sharedMEGAChatSdk localLogoutWithDelegate:[MEGAChatGenericRequestDelegate.alloc initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
            dispatch_semaphore_signal(semaphore);
        }]];
    }]];
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, timeout);
}

+ (void)localLogoutAndCleanUp {
    [MEGASdkManager localLogout];
    [MEGASdkManager deleteSharedSdks];
}

@end
