#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Reports a crash the crash protection prevented to Crashlytics, as a non-fatal named
/// `mega.ios.ocException`.
@interface MNZCrashProtectionReporter : NSObject

/// Records one prevented crash, with the stack of the caller.
///
/// Safe to call from wherever a crash was caught, whatever queue or lock that code holds: the stack is
/// taken in place, and Crashlytics is called later on a queue of its own. At most a few reports are sent
/// per launch, shared by every caller, so one hit in a loop does not flood Crashlytics.
///
/// @param reason What was prevented, e.g. the method and why it would have thrown.
+ (void)reportWithReason:(NSString *)reason;

@end

NS_ASSUME_NONNULL_END
