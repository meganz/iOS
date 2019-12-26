#import <UIKit/UIKit.h>

@interface MEGANavigationController : UINavigationController <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

- (void)addRightCancelButton;
- (void)addLeftDismissButtonWithText:(NSString *)text;

@end
