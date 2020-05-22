
#import "MasterKeyViewController.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

#import "Helper.h"

#import "NSURL+MNZCategory.h"

@interface MasterKeyViewController ()

@property (weak, nonatomic) IBOutlet UIView *illustrationView;
@property (weak, nonatomic) IBOutlet UIButton *carbonCopyMasterKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *saveMasterKey;

@property (weak, nonatomic) IBOutlet UIView *whyDoINeedARecoveryKeyTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *whyDoINeedARecoveryKeyView;
@property (weak, nonatomic) IBOutlet UILabel *whyDoINeedARecoveryKeyLabel;

@end

@implementation MasterKeyViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
    
    [self.carbonCopyMasterKeyButton setTitle:AMLocalizedString(@"copy", @"List option shown on the details of a file or folder") forState:UIControlStateNormal];
    
    [self.saveMasterKey setTitle:AMLocalizedString(@"save", @"Button title to 'Save' the selected option") forState:UIControlStateNormal];
    
    self.whyDoINeedARecoveryKeyLabel.text = AMLocalizedString(@"whyDoINeedARecoveryKey", @"Question button to present a view where it's explained what is the Recovery Key");
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[UIDevice currentDevice] iPhone4X]) {
        self.tabBarController.tabBar.hidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([[UIDevice currentDevice] iPhone4X]) {
        self.tabBarController.tabBar.hidden = NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.illustrationView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    [self.carbonCopyMasterKeyButton mnz_setupBasic:self.traitCollection];
    [self.saveMasterKey mnz_setupPrimary:self.traitCollection];
    
    self.whyDoINeedARecoveryKeyTopSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.whyDoINeedARecoveryKeyView.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    self.whyDoINeedARecoveryKeyLabel.textColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)copyMasterKeyTouchUpInside:(UIButton *)sender {
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        [Helper showMasterKeyCopiedAlert];
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)saveMasterKeyTouchUpInside:(UIButton *)sender {
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        [Helper showExportMasterKeyInView:self completion:nil];
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)whyDoINeedARecoveryKeyTouchUpInside:(UIButton *)sender {
    [[NSURL URLWithString:@"https://mega.nz/security"] mnz_presentSafariViewController];
}

@end
