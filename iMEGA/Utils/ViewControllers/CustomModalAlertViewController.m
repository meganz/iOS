
#import "CustomModalAlertViewController.h"

#import "AchievementsViewController.h"
#import "UIApplication+MNZCategory.h"

@interface CustomModalAlertViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *bonusButton;

@end

@implementation CustomModalAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = [UIImage imageNamed:self.image];
    self.titleLabel.text = self.viewTitle;
    
    if (self.boldInDetail) {
        UIFont *sfMedium = [UIFont mnz_SFUIMediumWithSize:14];
        NSRange boldRange = [self.detail rangeOfString:self.boldInDetail];
        
        NSMutableAttributedString *detailAttributedString = [[NSMutableAttributedString alloc] initWithString:self.detail];
        
        [detailAttributedString beginEditing];
        [detailAttributedString addAttribute:NSFontAttributeName
                                       value:sfMedium
                                       range:boldRange];
        
        [detailAttributedString endEditing];
        self.detailLabel.attributedText = detailAttributedString;
    } else {
        self.detailLabel.text = self.detail;
    }
    
    [self.actionButton setTitle:self.action forState:UIControlStateNormal];
    
    if (!self.dismiss) {
        self.dismissButton.hidden = YES;
    }
    
    if (!self.bonus) {
        self.bonusButton.hidden = YES;
    }
}

#pragma mark - IBActions

- (IBAction)actionTouchUpInside:(UIButton *)sender {
    if (self.completion) self.completion();
}

- (IBAction)dismissTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)bonusTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
        achievementsVC.enableCloseBarButton = YES;
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
        [[UIApplication mnz_visibleViewController] presentViewController:navigation animated:YES completion:nil];
    }];
}

@end
