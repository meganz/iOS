
#import <UIKit/UIKit.h>

@interface PasswordStrengthIndicatorView : UIView

@property (weak, nonatomic) IBOutlet UIView *customView;

- (void)updateViewWith:(PasswordStrength)passwordStrength;

@end
