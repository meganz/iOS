
#import "UITextField+MNZCategory.h"

#import <objc/runtime.h>

@implementation UITextField (MNZCategory)

- (BOOL (^)(UITextField *))shouldReturnCompletion {
    return objc_getAssociatedObject(self, @selector(shouldReturnCompletion));
}

- (void)setShouldReturnCompletion:(BOOL (^)(UITextField *))newShouldReturnCompletion {
    [self setDelegate];
    
    objc_setAssociatedObject(self, @selector(shouldReturnCompletion), newShouldReturnCompletion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void)setDelegate {
    if (self.delegate != (id<UITextFieldDelegate>)self.class) {
        objc_setAssociatedObject(self, _cmd, self.delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.delegate = (id<UITextFieldDelegate>)self.class;
    }
}

#pragma mark - UITextFieldDelegate

+ (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.shouldReturnCompletion) {
        return textField.shouldReturnCompletion(textField);
    }
    
    return YES;
}

@end
