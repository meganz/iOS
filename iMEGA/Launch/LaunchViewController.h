#import <UIKit/UIKit.h>

@interface LaunchViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) CAShapeLayer *circularShapeLayer;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
