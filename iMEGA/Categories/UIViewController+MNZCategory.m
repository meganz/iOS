
#import "UIViewController+MNZCategory.h"
#import <objc/runtime.h>

@implementation UIViewController (MNZCategory)

- (id<UIViewControllerPreviewing> )previewingContext {
    return objc_getAssociatedObject(self, @selector(previewingContext));
}

- (void)setPreviewingContext:(id<UIViewControllerPreviewing> )previewingContext {
    objc_setAssociatedObject(self, @selector(previewingContext), previewingContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)configPreviewingRegistration {
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        if (!self.previewingContext
            && [self conformsToProtocol:@protocol(UIViewControllerPreviewingDelegate)]) {
            self.previewingContext = [self registerForPreviewingWithDelegate:(id<UIViewControllerPreviewingDelegate> )self
                                                                  sourceView:self.view];
        }
    } else {
        [self unregisterForPreviewingWithContext:self.previewingContext];
        self.previewingContext = nil;
    }

}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(presentViewController:animated:completion:);
        SEL swizzledSelector = @selector(swizzled_presentViewController:animated:completion:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL methodExists = !class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));

        if (methodExists) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        } else {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        }
    });
}

- (void)swizzled_presentViewController:(nonnull UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {

    if (@available(iOS 13.0, *)) {
        if (viewController.modalPresentationStyle == UIModalPresentationAutomatic || viewController.modalPresentationStyle == UIModalPresentationPageSheet || viewController.modalPresentationStyle == UIModalPresentationFormSheet) {
            viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        }
    }

    [self swizzled_presentViewController:viewController animated:animated completion:completion];
}


@end
