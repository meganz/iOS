
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

- (void)openURL:(NSURL *)url {
    if (url == nil) {
        return;
    }
    
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder respondsToSelector:@selector(openURL:)]) {
            [responder performSelector:@selector(openURL:) withObject:url];
        }
        
        responder = responder.nextResponder;
    }
}

@end
