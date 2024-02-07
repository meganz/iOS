#import <UIKit/UIKit.h>

@interface PasswordStrengthIndicatorView : UIView

@property (weak, nonatomic) IBOutlet UIView *customView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void)updateViewWithPasswordStrength:(PasswordStrength)passwordStrength updateDescription:(BOOL)updateDescription;

@end
