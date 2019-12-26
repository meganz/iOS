
#import "EnablingTwoFactorAuthenticationViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import "TwoFactorAuthenticationViewController.h"

@interface EnablingTwoFactorAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UILabel *firstSectionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *seedQrImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seedQrImageTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seedQrImageViewWidthLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seedQrImageViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet UITextView *seedTextView;
@property (weak, nonatomic) IBOutlet UIView *seedTextViewView;

@property (weak, nonatomic) IBOutlet UIButton *openInButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation EnablingTwoFactorAuthenticationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        self.firstSectionLabel.font = [UIFont mnz_SFUIRegularWithSize:12.f];
        self.seedQrImageTopLayoutConstraint.constant = 16.f;
        self.seedQrImageViewHeightLayoutConstraint.constant = [[UIDevice currentDevice] iPhone4X] ? 100.f : 120.f;
        self.seedQrImageViewWidthLayoutConstraint.constant = [[UIDevice currentDevice] iPhone4X] ? 100.f : 120.f;
        self.seedTextView.font = [UIFont mnz_SFUIRegularWithSize:14.f];
    }
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    NSTextAttachment *imageTextAttachment = [[NSTextAttachment alloc] init];
    imageTextAttachment.image = [UIImage imageNamed:@"littleQuestionMark_Black"];
    imageTextAttachment.bounds = CGRectMake(0, 0, 12.0f, 12.0f);
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:[AMLocalizedString(@"scanOrCopyTheSeed", @"A message on the setup two-factor authentication page on the mobile web client.") stringByAppendingString:@" "]];
    [mutableAttributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:imageTextAttachment]];
    self.firstSectionLabel.attributedText = mutableAttributedString;
    self.firstSectionLabel.userInteractionEnabled = YES;
    self.firstSectionLabel.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firstSectionLabelTapped:)]];
    
    NSString *qrString = [NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", [[MEGASdkManager sharedMEGASdk] myEmail], self.seed];
    self.seedQrImageView.image = [UIImage mnz_qrImageFromString:qrString withSize:self.seedQrImageView.frame.size color:UIColor.blackColor];
    
    self.seedTextView.text = [self seedSplitInGroupsOfFourCharacters];
    self.seedTextViewView.layer.borderColor = [UIColor mnz_grayE3E3E3].CGColor;
    
    [self.openInButton setTitle:AMLocalizedString(@"openIn", @"Title shown under the action that allows you to open a file in another app") forState:UIControlStateNormal];
    [self.nextButton setTitle:AMLocalizedString(@"next", @"") forState:UIControlStateNormal];
    self.nextButton.layer.borderColor = [UIColor mnz_gray999999].CGColor;
    
    [self.seedTextView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnTextView:)]];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (NSString *)seedSplitInGroupsOfFourCharacters {
    NSString *seedSplitInGroupsOfFourCharacters = [NSString new];
    if (self.seed) {
        for (NSInteger i = 0; i < (self.seed.length / 4); i++) {
            NSRange range = NSMakeRange((i * 4), 4);
            if (range.location > self.seed.length) {
                break;
            }
            
            NSString *tempString = [self.seed substringWithRange:range];
            if (((i + 1) % 5) == 0 && i > 0) {
                seedSplitInGroupsOfFourCharacters = [seedSplitInGroupsOfFourCharacters stringByAppendingString:[NSString stringWithFormat:@"%@ \n", tempString]];
            } else {
                seedSplitInGroupsOfFourCharacters = [seedSplitInGroupsOfFourCharacters stringByAppendingString:(i == 12 ? [NSString stringWithFormat:@"%@", tempString] : [NSString stringWithFormat:@"%@ ", tempString])];
            }
        }
    }
    
    return seedSplitInGroupsOfFourCharacters;
}

- (void)youNeedATwoFactorAuthenticationAppAlertWithTitle:(NSString *)title {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"App Store" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/search"];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }]];
    
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)firstSectionLabelTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self youNeedATwoFactorAuthenticationAppAlertWithTitle:AMLocalizedString(@"You need an authenticator app to enable 2FA on MEGA. You can download and install the Google Authenticator, Duo Mobile, Authy or Microsoft Authenticator app for your phone or tablet.", @"Alert text shown when enabling Two-Factor Authentication when you don't have a two factor authentication app installed on the device and tap on the question mark")];
    }
}

#pragma mark - IBActions

- (IBAction)openInTouchUpInside:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", [[MEGASdkManager sharedMEGASdk] myEmail], self.seed]];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                MEGALogInfo(@"URL opened on authenticator app");
            } else {
                MEGALogInfo(@"URL NOT opened");
                [self youNeedATwoFactorAuthenticationAppAlertWithTitle:AMLocalizedString(@"youNeedATwoFactorAuthenticationApp", @"Alert text shown when enabling the two factor authentication when you don't have a two factor authentication app installed on the device")];
            }
        }];
    } else {
        if ([[UIApplication sharedApplication] openURL:url]) {
            MEGALogInfo(@"URL opened on authenticator app");
        } else {
            MEGALogInfo(@"URL NOT opened");
            [self youNeedATwoFactorAuthenticationAppAlertWithTitle:AMLocalizedString(@"youNeedATwoFactorAuthenticationApp", @"Alert text shown when enabling the two factor authentication when you don't have a two factor authentication app installed on the device")];
        }
    }
}

- (IBAction)nextTouchUpInside:(UIButton *)sender {
    TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
    twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationEnable;
    twoFactorAuthenticationVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPressOnTextView:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.seed;
        
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"copiedToTheClipboard", @"Text of the button after the links were copied to the clipboard")];
    }
}

@end
