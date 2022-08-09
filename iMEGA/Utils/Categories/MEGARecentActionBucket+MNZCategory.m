#import "MEGARecentActionBucket+MNZCategory.h"
#import <objc/runtime.h>

static const void *mnz_isExpendedKey = &mnz_isExpendedKey;

@implementation MEGARecentActionBucket (MNZCategory)

#pragma mark - properties

- (void)setMnz_isExpanded:(BOOL)mnz_isExpended {
    NSNumber *number = [NSNumber numberWithBool:mnz_isExpended];
    objc_setAssociatedObject(self, mnz_isExpendedKey, number , OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)mnz_isExpanded {
    NSNumber *number = objc_getAssociatedObject(self, mnz_isExpendedKey);
    return [number boolValue];
}

@end
