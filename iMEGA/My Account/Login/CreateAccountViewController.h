#import <UIKit/UIKit.h>

@interface CreateAccountViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIButton *termsCheckboxButton;
@property (weak, nonatomic) IBOutlet UIButton *termsForLosingPasswordCheckboxButton;

@property (strong, nonatomic) NSString *emailString;

@end
