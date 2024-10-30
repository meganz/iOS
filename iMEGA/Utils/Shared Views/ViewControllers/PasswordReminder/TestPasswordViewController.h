#import <UIKit/UIKit.h>

@class TestPasswordViewModel;
@interface TestPasswordViewController: UIViewController

@property (assign, getter=isLoggingOut) BOOL logout;
@property (nonatomic, strong) TestPasswordViewModel *viewModel;

@end
