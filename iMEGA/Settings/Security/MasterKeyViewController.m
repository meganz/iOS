
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

@property (weak, nonatomic) IBOutlet UIButton *whyDoINeedARecoveryKeyButton;

@end

@implementation MasterKeyViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
    
    [self.carbonCopyMasterKeyButton setTitle:NSLocalizedString(@"copy", @"List option shown on the details of a file or folder") forState:UIControlStateNormal];
    
    [self.saveMasterKey setTitle:NSLocalizedString(@"save", @"Button title to 'Save' the selected option") forState:UIControlStateNormal];
    
    self.whyDoINeedARecoveryKeyButton.titleLabel.text = NSLocalizedString(@"whyDoINeedARecoveryKey", @"Question button to present a view where it's explained what is the Recovery Key");
    
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
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.illustrationView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    [self.carbonCopyMasterKeyButton mnz_setupBasic:self.traitCollection];
    [self.saveMasterKey mnz_setupPrimary:self.traitCollection];
    
    self.whyDoINeedARecoveryKeyButton.titleLabel.textColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
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
