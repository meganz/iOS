#import "MNZMethodSwizzler.h"

#import <objc/runtime.h>

@implementation MNZMethodSwizzler

+ (BOOL)swizzleInstanceMethod:(SEL)originalSelector
                   withMethod:(SEL)swizzledSelector
                      inClass:(Class)cls {
    if (cls == Nil) {
        return NO;
    }

    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    if (originalMethod == NULL || swizzledMethod == NULL) {
        return NO;
    }

    if (strcmp(method_getTypeEncoding(originalMethod), method_getTypeEncoding(swizzledMethod)) != 0) {
        return NO;
    }

    IMP originalImplementation = method_getImplementation(originalMethod);
    IMP swizzledImplementation = method_getImplementation(swizzledMethod);

    class_replaceMethod(cls, swizzledSelector, originalImplementation, method_getTypeEncoding(originalMethod));
    class_replaceMethod(cls, originalSelector, swizzledImplementation, method_getTypeEncoding(swizzledMethod));
    return YES;
}

@end
