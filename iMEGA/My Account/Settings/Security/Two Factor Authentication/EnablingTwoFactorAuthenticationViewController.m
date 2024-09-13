#import "EnablingTwoFactorAuthenticationViewController.h"

#import "SVProgressHUD.h"

#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import "TwoFactorAuthenticationViewController.h"

@import MEGAL10nObjc;

@interface EnablingTwoFactorAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UILabel *firstSectionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *seedQrImageView;
@property (weak, nonatomic) IBOutlet UITextView *seedTextView;
@property (weak, nonatomic) IBOutlet UIView *seedTextViewView;

@property (weak, nonatomic) IBOutlet UIButton *openInButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation EnablingTwoFactorAuthenticationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = LocalizedString(@"twoFactorAuthentication", @"");
    self.navigationItem.title = title;
    [self setMenuCapableBackButtonWithMenuTitle:title];
    
    self.firstSectionLabel.userInteractionEnabled = YES;
    self.firstSectionLabel.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firstSectionLabelTapped:)]];
    
    self.seedTextView.text = [self seedSplitInGroupsOfFourCharacters];
    
    [self.openInButton setTitle:LocalizedString(@"openIn", @"Title shown under the action that allows you to open a file in another app") forState:UIControlStateNormal];
    [self.nextButton setTitle:LocalizedString(@"next", @"") forState:UIControlStateNormal];
    
    [self.seedTextView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnTextView:)]];
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    [self setupFirstSectionLabelTextAndImage];

    NSString *qrString = [NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", MEGASdk.shared.myEmail, self.seed];

    self.view.backgroundColor = [self defaultBackgroundColor];

    self.seedQrImageView.image = [UIImage mnz_qrImageFromString:qrString withSize:self.seedQrImageView.frame.size color: [self labelColor] backgroundColor:UIColor.clearColor];

    self.seedTextViewView.backgroundColor = [self defaultBackgroundColor];
    self.seedTextViewView.layer.borderColor = [self separatorColor].CGColor;

    [self.openInButton mnz_setup:self.openInButtonStyle traitCollection:self.traitCollection];
    [self.nextButton mnz_setup:self.nextButtonStyle traitCollection:self.traitCollection];
}

- (void)setupFirstSectionLabelTextAndImage {
    NSTextAttachment *imageTextAttachment = [[NSTextAttachment alloc] init];
    imageTextAttachment.image = [UIImage imageNamed:@"littleQuestionMark"];
    imageTextAttachment.bounds = CGRectMake(0, 0, 12.0f, 12.0f);
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:[LocalizedString(@"scanOrCopyTheSeed", @"A message on the setup two-factor authentication page on the mobile web client.") stringByAppendingString:@" "]];
    [mutableAttributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:imageTextAttachment]];
    self.firstSectionLabel.attributedText = mutableAttributedString;
}

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

- (void)youNeedATwoFactorAuthenticationAppAlertWithTitle:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Authenticator app required", @"Alert title shown when enabling Two-Factor Authentication when you don't have a two factor authentication app installed on the device") message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"App Store", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/search"];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
    }]];
    
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)firstSectionLabelTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self youNeedATwoFactorAuthenticationAppAlertWithTitle:LocalizedString(@"You need an authenticator app to enable 2FA on MEGA. You can download and install the Google Authenticator, Duo Mobile, Authy or Microsoft Authenticator app for your phone or tablet.", @"Alert text shown when enabling Two-Factor Authentication when you don't have a two factor authentication app installed on the device and tap on the question mark")];
    }
}

#pragma mark - IBActions

- (IBAction)openInTouchUpInside:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", [MEGASdk.shared myEmail], self.seed]];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (success) {
            MEGALogInfo(@"URL opened on authenticator app");
        } else {
            MEGALogInfo(@"URL NOT opened");
            [self youNeedATwoFactorAuthenticationAppAlertWithTitle:LocalizedString(@"youNeedATwoFactorAuthenticationApp", @"Alert text shown when enabling the two factor authentication when you don't have a two factor authentication app installed on the device")];
        }
    }];
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
        
        [SVProgressHUD showSuccessWithStatus:LocalizedString(@"copiedToTheClipboard", @"Text of the button after the links were copied to the clipboard")];
    }
}

@end
