
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
@property (weak, nonatomic) IBOutlet UIView *alphaView;

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
    
    if (self.dismiss) {
        [self.dismissButton setTitle:self.dismiss forState:UIControlStateNormal];
    } else {
        self.dismissButton.hidden = YES;
    }
    
    if (self.bonus) {
        [self.bonusButton setTitle:self.bonus forState:UIControlStateNormal];
    } else {
        self.bonusButton.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fadeInBackgroundCompletion:nil];
}

#pragma mark - Private

- (void)fadeInBackgroundCompletion:(void (^ __nullable)(void))fadeInCompletion {
    [UIView animateWithDuration:.3 animations:^{
        [self.alphaView setAlpha:0.5];
    } completion:^(BOOL finished) {
        if (fadeInCompletion && finished) {
            fadeInCompletion();
        }
    }];
}

- (void)fadeOutBackgroundCompletion:(void (^ __nullable)(void))fadeOutCompletion {
    [UIView animateWithDuration:.2 animations:^{
        [self.alphaView setAlpha:.0];
    } completion:^(BOOL finished) {
        if (fadeOutCompletion && finished) {
            fadeOutCompletion();
        }
    }];
}

#pragma mark - IBActions

- (IBAction)actionTouchUpInside:(UIButton *)sender {
    [self fadeOutBackgroundCompletion:^ {
        if (self.completion) self.completion();
    }];
}

- (IBAction)dismissTouchUpInside:(UIButton *)sender {
    [self fadeOutBackgroundCompletion:^ {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)bonusTouchUpInside:(UIButton *)sender {
    [self fadeOutBackgroundCompletion:^ {
        [self dismissViewControllerAnimated:YES completion:^{
            AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
            achievementsVC.enableCloseBarButton = YES;
            UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
            [[UIApplication mnz_visibleViewController] presentViewController:navigation animated:YES completion:nil];
        }];
    }];
}

@end
