#import <UIKit/UIKit.h>

@protocol MEGANavigationControllerDelegate <NSObject>
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController;
@end


@interface MEGANavigationController : UINavigationController <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

- (void)addRightCancelButton;
- (void)addLeftDismissButtonWithText:(NSString *)text;

@property (weak, nonatomic) id<MEGANavigationControllerDelegate> navigationDelegate;

@end
