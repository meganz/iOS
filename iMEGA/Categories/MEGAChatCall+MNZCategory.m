
#import "MEGAChatCall+MNZCategory.h"

#import <objc/runtime.h>

static const void *uuidTagKey = &uuidTagKey;

@implementation MEGAChatCall (MNZCategory)

#pragma mark - Properties

- (NSUUID *)uuid {
    return objc_getAssociatedObject(self, uuidTagKey);
}

- (void)setUuid:(NSUUID *)uuid {
    objc_setAssociatedObject(self, &uuidTagKey, uuid, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
