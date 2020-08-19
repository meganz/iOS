
#import "PasscodeTableViewController.h"

#import "LTHPasscodeViewController.h"
#import <LocalAuthentication/LAContext.h>

#import "Helper.h"
#import "NSString+MNZCategory.h"

#import "MEGA-Swift.h"

@interface PasscodeTableViewController () {
    BOOL wasPasscodeAlreadyEnabled;
}

@property (weak, nonatomic) IBOutlet UILabel *turnOnOffPasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *turnOnOffPasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *changePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *simplePasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *simplePasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *eraseLocalDataLabel;
@property (weak, nonatomic) IBOutlet UISwitch *eraseLocalDataSwitch;
@property (weak, nonatomic) IBOutlet UILabel *biometricsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *biometricsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *requirePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *requirePasscodeDetailLabel;

@end

@implementation PasscodeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"passcode", nil)];
    [self.turnOnOffPasscodeLabel setText:AMLocalizedString(@"passcode", nil)];
    [self.changePasscodeLabel setText:AMLocalizedString(@"changePasscodeLabel", @"Change passcode")];
    [self.simplePasscodeLabel setText:AMLocalizedString(@"simplePasscodeLabel", @"Simple passcode")];
    self.requirePasscodeLabel.text = AMLocalizedString(@"Require passcode", @"Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes");

    self.biometricsLabel.text = @"Touch ID";
    
    LAContext *context = [[LAContext alloc] init];
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        if (@available(iOS 11.0, *)) {
            if (context.biometryType == LABiometryTypeFaceID) {
                self.biometricsLabel.text = @"Face ID";
            }
        }
    }

    [self.eraseLocalDataLabel setText:AMLocalizedString(@"eraseAllLocalDataLabel", @"Erase all local data")];
    
    wasPasscodeAlreadyEnabled = [LTHPasscodeViewController doesPasscodeExist];
    [[LTHPasscodeViewController sharedUser] setHidesCancelButton:NO];
    
    LTHPasscodeViewController.sharedUser.navigationBarTintColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    LTHPasscodeViewController.sharedUser.navigationTintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    LTHPasscodeViewController.sharedUser.navigationTitleColor = UIColor.mnz_label;

    self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureView];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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

- (void)configureView {
    BOOL doesPasscodeExist = [LTHPasscodeViewController doesPasscodeExist];
    [self.turnOnOffPasscodeSwitch setOn:doesPasscodeExist];
    if (doesPasscodeExist) {
        [self.simplePasscodeSwitch setOn:[[LTHPasscodeViewController sharedUser] isSimple]];
        [self.biometricsSwitch setOn:[[LTHPasscodeViewController sharedUser] allowUnlockWithBiometrics]];
        
        if ([NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps]) {
            [self.eraseLocalDataSwitch setOn:YES];
            [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        } else {
            [self.eraseLocalDataSwitch setOn:NO];
            
            if (!wasPasscodeAlreadyEnabled) {
                [NSUserDefaults.standardUserDefaults setBool:YES forKey:MEGAPasscodeLogoutAfterTenFailedAttemps];
                [self.eraseLocalDataSwitch setOn:YES];
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                wasPasscodeAlreadyEnabled = YES;
            }
        }
        self.requirePasscodeDetailLabel.text = LTHPasscodeViewController.timerDuration > RequirePasscodeAfterImmediatelly ? [NSString mnz_stringFromCallDuration:LTHPasscodeViewController.timerDuration] : AMLocalizedString(@"Immediately", nil);
    } else {
        [self.simplePasscodeSwitch setOn:NO];
        [self.biometricsSwitch setOn:NO];
        [self.eraseLocalDataSwitch setOn:NO];
    }
    
    [self.tableView reloadData];
}

- (void)updateAppearance {
    self.requirePasscodeDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)eraseLocalData {
    BOOL eraseLocalDataEnaled = [NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps];
    
    if (eraseLocalDataEnaled) {
        [self.eraseLocalDataSwitch setOn:YES];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
    } else {
        [self.eraseLocalDataSwitch setOn:NO];
    }
}

- (BOOL)isTouchIDAvailable {
    return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
}

#pragma mark - IBActions

- (IBAction)passcodeSwitchValueChanged:(UISwitch *)sender {
    if (![LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self asModal:YES];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        [LTHPasscodeViewController saveTimerDuration:RequirePasscodeAfterThirtySeconds];
    } else {
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self asModal:YES];
    }
}

- (IBAction)simplePasscodeSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setIsSimple:self.simplePasscodeSwitch.isOn inViewController:self asModal:YES];
}

- (IBAction)eraseLocalDataSwitchValueChanged:(UISwitch *)sender {
    BOOL isEraseLocalData = ![NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps];
    
    [NSUserDefaults.standardUserDefaults setBool:isEraseLocalData forKey:MEGAPasscodeLogoutAfterTenFailedAttemps];
    if (isEraseLocalData) {
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        [self.eraseLocalDataSwitch setOn:YES animated:YES];
    } else {
        [self.eraseLocalDataSwitch setOn:NO animated:YES];
    }
}

- (IBAction)biometricsSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setAllowUnlockWithBiometrics:sender.isOn];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL doesPasscodeExist = [LTHPasscodeViewController doesPasscodeExist];
    [self.changePasscodeLabel setEnabled:doesPasscodeExist];
    [self.simplePasscodeLabel setEnabled:doesPasscodeExist];
    [self.simplePasscodeSwitch setEnabled:doesPasscodeExist];
    [self.eraseLocalDataLabel setEnabled:doesPasscodeExist];
    [self.eraseLocalDataSwitch setEnabled:doesPasscodeExist];
    [self.biometricsSwitch setEnabled:doesPasscodeExist];
    [self.biometricsLabel setEnabled:doesPasscodeExist];
    self.requirePasscodeLabel.enabled = doesPasscodeExist;
    self.requirePasscodeDetailLabel.enabled = doesPasscodeExist;

    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 1;
    
    switch (section) {
        case 0:
            if ([self isTouchIDAvailable]) {
                numberOfRows = 4;
            } else {
                numberOfRows = 3;
            }
            break;
    }
    
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter = @"";
    
    if (section == 1) {
        titleForFooter = AMLocalizedString(@"failedAttempstSectionTitle", @"Log out and erase all local data on MEGA’s app after 10 failed passcode attempts");
    }
    
    return titleForFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 1)) {
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
        }
    }
    
    if (indexPath.section == 2) {
        if (LTHPasscodeViewController.doesPasscodeExist) {
            PasscodeTimeDurationTableViewController *passcodeTimeDurationTableViewController = [PasscodeTimeDurationTableViewController.alloc initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:passcodeTimeDurationTableViewController animated:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
