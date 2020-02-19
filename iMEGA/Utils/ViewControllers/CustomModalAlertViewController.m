
#import "CustomModalAlertViewController.h"

#import "AchievementsViewController.h"
#import "CopyableLabel.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "MEGAGenericRequestDelegate.h"
#import "SVProgressHUD.h"
#import "EnablingTwoFactorAuthenticationViewController.h"
#import "MEGASdkManager.h"

@interface CustomModalAlertViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UIView *linkView;
@property (weak, nonatomic) IBOutlet CopyableLabel *linkLabel;

@end

@implementation CustomModalAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUIAppearance];
    
    if (self.image) {
        self.imageView.image = self.image;
        if (self.shouldRoundImage) {
            self.imageView.layer.cornerRadius = (self.imageView.image.size.height / 4);
            self.imageView.clipsToBounds = YES;
        }
    }
    
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
    
    if (self.firstButtonTitle) {
        [self.firstButton setTitle:self.firstButtonTitle forState:UIControlStateNormal];
    } else {
        self.firstButton.hidden = YES;
    }
    
    if (self.dismissButtonTitle) {
        [self.dismissButton setTitle:self.dismissButtonTitle forState:UIControlStateNormal];
    } else {
        self.dismissButton.hidden = YES;
    }
    
    if (self.secondButtonTitle) {
        [self.secondButton setTitle:self.secondButtonTitle forState:UIControlStateNormal];
    } else {
        self.secondButton.hidden = YES;
    }
    
    if (self.link) {
        self.linkView.layer.cornerRadius = 4;
        self.linkView.layer.borderWidth = 0.5;
        self.linkView.layer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1] CGColor];
        self.linkLabel.text = self.link;
    } else {
        self.linkView.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fadeInBackgroundCompletion:nil];
}

- (void)configUIAppearance {
    self.firstButton.titleLabel.numberOfLines = 2;
    self.firstButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.firstButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

#pragma mark - Public

- (void)configureForTwoFactorAuthenticationRequestedByUser:(BOOL)requestedByUser {
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.image = [UIImage imageNamed:@"2FASetup"];
    self.viewTitle = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthentication", @"Title shown when you start the process to enable Two-Factor Authentication");
    self.detail = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthenticationDescription", @"Description text of the dialog displayed to start setup the Two-Factor Authentication");
    self.firstButtonTitle = AMLocalizedString(@"beginSetup", @"Button title to start the setup of a feature. For example 'Begin Setup' for Two-Factor Authentication");
    if (requestedByUser) {
        self.dismissButtonTitle = AMLocalizedString(@"cancel", @"");
    } else {
        self.dismissButtonTitle = AMLocalizedString(@"notNow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
    }
    
    __weak __typeof(self) weakCustom = self;
    
    self.firstCompletion = ^{
        MEGAGenericRequestDelegate *delegate = [MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                [SVProgressHUD showErrorWithStatus:error.name];
                return;
            }
            
            [SVProgressHUD dismiss];
            EnablingTwoFactorAuthenticationViewController *enablingTwoFactorAuthenticationTVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"EnablingTwoFactorAuthenticationViewControllerID"];
            enablingTwoFactorAuthenticationTVC.seed = request.text; //Returns the Base32 secret code needed to configure multi-factor authentication.
            enablingTwoFactorAuthenticationTVC.hidesBottomBarWhenPushed = YES;
            
            [UIApplication.mnz_visibleViewController.navigationController pushViewController:enablingTwoFactorAuthenticationTVC animated:YES];
        }];
        
        [weakCustom dismissViewControllerAnimated:YES completion:^{
            [SVProgressHUD show];
            [MEGASdkManager.sharedMEGASdk multiFactorAuthGetCodeWithDelegate:delegate];
        }];
    };
    
    self.dismissCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:nil];
    };
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

- (IBAction)firstButtonTouchUpInside:(UIButton *)sender {
    [self fadeOutBackgroundCompletion:^ {
        if (self.firstCompletion) self.firstCompletion();
    }];
}

- (IBAction)dismissTouchUpInside:(UIButton *)sender {
    [self fadeOutBackgroundCompletion:^ {
        if (self.dismissCompletion) {
            self.dismissCompletion();
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (IBAction)secondButtonTouchUpInside:(UIButton *)sender {
    [self fadeOutBackgroundCompletion:^ {
        if (self.secondCompletion) {
            self.secondCompletion();
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
                achievementsVC.enableCloseBarButton = YES;
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
                [UIApplication.mnz_presentingViewController presentViewController:navigation animated:YES completion:nil];
            }];
        }
    }];
}

@end
