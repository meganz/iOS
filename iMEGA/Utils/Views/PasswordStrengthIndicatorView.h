
#import <UIKit/UIKit.h>

@interface PasswordStrengthIndicatorView : UIView

@property (weak, nonatomic) IBOutlet UIView *customView;

- (void)updateViewWithPasswordStrength:(PasswordStrength)passwordStrength updateDescription:(BOOL)updateDescription;

@end
