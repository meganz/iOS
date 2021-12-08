
#import "CopyableLabel.h"

@implementation CopyableLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    self.userInteractionEnabled = YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:)) {
        return YES;
    } else {
        return [super canPerformAction:action withSender:sender];
    }
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (BOOL)becomeFirstResponder {
    if ([super becomeFirstResponder]) {
        self.highlighted = YES;
        return YES;
    }
    return NO;
}


- (void)copy:(id)sender {
    UIPasteboard.generalPasteboard.string = self.text;
    self.highlighted = NO;
    [self resignFirstResponder];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self isFirstResponder]) {
        self.highlighted = NO;
        [UIMenuController.sharedMenuController hideMenuFromView:self];
        [UIMenuController.sharedMenuController update];
        [self resignFirstResponder];
    } else if ([self becomeFirstResponder]) {
        [UIMenuController.sharedMenuController showMenuFromView:self rect:self.bounds];
    }
}

@end
