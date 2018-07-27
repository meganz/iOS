
#import "EnablingTwoFactorAuthenticationViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import "TwoFactorAuthenticationViewController.h"

@interface EnablingTwoFactorAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UILabel *firstSectionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *seedQrImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seedQrImageViewWidthLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seedQrImageViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet UITextView *seedTextView;

@property (weak, nonatomic) IBOutlet UIButton *openInButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation EnablingTwoFactorAuthenticationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (([[UIDevice currentDevice] iPhone4X])) {
        self.seedQrImageViewHeightLayoutConstraint.constant = 140.f;
        self.seedQrImageViewWidthLayoutConstraint.constant = 140.f;
    }
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.firstSectionLabel.text = AMLocalizedString(@"scanOrCopyTheSeed", @"");
    
    NSString *qrString = [NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", [[MEGASdkManager sharedMEGASdk] myEmail], self.seed];
    self.seedQrImageView.image = [UIImage mnz_qrImageFromString:qrString withSize:self.seedQrImageView.frame.size color:UIColor.blackColor];
    
    self.seedTextView.text = [self seedSplitInGroupsOfFourCharacters];
    self.seedTextView.layer.borderColor = [UIColor mnz_grayE3E3E3].CGColor;
    
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

- (void)noAuthenticatorAppInstaledAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"noAuthenticatorAppInstalled", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
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
                [self noAuthenticatorAppInstaledAlert];
            }
        }];
    } else {
        if ([[UIApplication sharedApplication] openURL:url]) {
            MEGALogInfo(@"URL opened on authenticator app");
        } else {
            MEGALogInfo(@"URL NOT opened");
            [self noAuthenticatorAppInstaledAlert];
        }
    }
}

- (IBAction)nextTouchUpInside:(UIButton *)sender {
    TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
    twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationEnable;
    
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
