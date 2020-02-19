
#import <UIKit/UIKit.h>

@protocol LaunchViewControllerDelegate <NSObject>

- (void)setupFinished;
- (void)readyToShowRecommendations;

@end

@interface LaunchViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) CAShapeLayer *circularShapeLayer;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, weak) id<LaunchViewControllerDelegate> delegate;

@end
