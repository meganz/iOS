
#import "UIViewController+MNZCategory.h"
#import <objc/runtime.h>

@implementation UIViewController (MNZCategory)

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
