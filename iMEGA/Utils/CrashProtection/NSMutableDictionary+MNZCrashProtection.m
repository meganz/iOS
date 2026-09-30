// MRC: compiled with -fno-objc-arc

#if __has_feature(objc_arc)
#error "NSMutableDictionary+MNZCrashProtection.m must be compiled without ARC (-fno-objc-arc)."
#endif

#import <Foundation/Foundation.h>
#import "MNZCrashProtectionReporter.h"
#import "MNZMethodSwizzler.h"

@implementation NSMutableDictionary (MNZCrashProtection)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class dictionaryClass = NSClassFromString(@"__NSDictionaryM");
        [MNZMethodSwizzler swizzleInstanceMethod:@selector(setObject:forKeyedSubscript:)
                                           withMethod:@selector(mnz_setObject:forKeyedSubscript:)
                                         inClass:dictionaryClass];
        [MNZMethodSwizzler swizzleInstanceMethod:@selector(setObject:forKey:)
                                           withMethod:@selector(mnz_setObject:forKey:)
                                         inClass:dictionaryClass];
    });
}

/// Never call it directly: on `__NSDictionaryM` that goes straight to the original and
/// skips the nil key check, and on any other `NSMutableDictionary` subclass it is still this method, so
/// calling itself recurses forever.
- (void)mnz_setObject:(id)object forKeyedSubscript:(id<NSCopying>)key {
    if (key == nil) {
        NSString * const reason = @"-[NSMutableDictionary setObject:forKeyedSubscript:]: key cannot be nil";
        NSAssert(NO, reason);
        [MNZCrashProtectionReporter reportWithReason:reason];
        return;
    }

    [self mnz_setObject:object forKeyedSubscript:key];
}

/// Never call it directly, for the same reasons as `mnz_setObject:forKeyedSubscript:`.
///
/// Unlike subscripting, `setObject:forKey:` takes a nil object as a mistake rather than a removal, so a nil
/// object is dropped too, and whatever the key already holds is kept.
- (void)mnz_setObject:(id)object forKey:(id<NSCopying>)key {
    if (key == nil || object == nil) {
        NSString * const reason = key == nil
            ? @"-[NSMutableDictionary setObject:forKey:]: key cannot be nil"
            : @"-[NSMutableDictionary setObject:forKey:]: object cannot be nil";
        NSAssert(NO, reason);
        [MNZCrashProtectionReporter reportWithReason:reason];
        return;
    }

    [self mnz_setObject:object forKey:key];
}

@end
