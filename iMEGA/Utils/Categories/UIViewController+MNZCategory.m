#import "UIViewController+MNZCategory.h"
#import <objc/runtime.h>

@implementation UIViewController (MNZCategory)

- (void)openURL:(NSURL *)url {
    if (url == nil) {
        return;
    }
    
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass: UIApplication.class]) {
            [((UIApplication *)responder) openURL:url options:@{} completionHandler:nil];
        }
        
        responder = responder.nextResponder;
    }
}

@end
