#import "MNZCrashProtectionReporter.h"

#import <stdatomic.h>

@import FirebaseCrashlytics;

static NSString * const MNZObjcExceptionEventName = @"mega.ios.ocException";

/// Enough reports to tell where prevented crashes come from, without flooding Crashlytics.
static const int MNZMaxReportsPerLaunch = 5;
static atomic_int reportCount = 0;

@implementation MNZCrashProtectionReporter

+ (void)reportWithReason:(NSString *)reason {
    if (atomic_fetch_add(&reportCount, 1) >= MNZMaxReportsPerLaunch) {
        return;
    }

    // Taken here so the report points at the caller, not at the queue it is sent from.
    NSArray<NSNumber *> *returnAddresses = [NSThread callStackReturnAddresses];

    // Crashlytics is not called in place: the caller can hold a lock or a queue — Firebase's
    // GULMutableDictionary writes on its own serial queue — and Crashlytics takes locks of its own
    // while recording, so calling it here could deadlock.
    dispatch_async([self reportingQueue], ^{
        NSMutableArray<FIRStackFrame *> *stackTrace = [NSMutableArray arrayWithCapacity:returnAddresses.count];
        for (NSNumber *address in returnAddresses) {
            [stackTrace addObject:[FIRStackFrame stackFrameWithAddress:address.unsignedIntegerValue]];
        }

        FIRExceptionModel *exceptionModel = [FIRExceptionModel exceptionModelWithName:MNZObjcExceptionEventName reason:reason];
        exceptionModel.stackTrace = stackTrace;
        [[FIRCrashlytics crashlytics] recordExceptionModel:exceptionModel];
    });
}

+ (dispatch_queue_t)reportingQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("mega.ios.ocException.reporting", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@end
