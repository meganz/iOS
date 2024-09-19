#import "PasscodeTableViewController.h"

#import "LTHPasscodeViewController.h"
#import <LocalAuthentication/LAContext.h>

#import "Helper.h"
#import "NSString+MNZCategory.h"

#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface PasscodeTableViewController () {
    BOOL wasPasscodeAlreadyEnabled;
}

@property (weak, nonatomic) IBOutlet UILabel *turnOnOffPasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *turnOnOffPasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *changePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *biometricsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *biometricsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *requirePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *requirePasscodeDetailLabel;

@end

@implementation PasscodeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = LocalizedString(@"passcode", @"");
    [self.navigationItem setTitle:title];
    [self setMenuCapableBackButtonWithMenuTitle:title];
    [self.turnOnOffPasscodeLabel setText:LocalizedString(@"passcode", @"")];
    [self.changePasscodeLabel setText:LocalizedString(@"changePasscodeLabel", @"Section title where you can change the app's passcode")];
    self.requirePasscodeLabel.text = LocalizedString(@"Require Passcode", @"Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes");

    self.biometricsLabel.text = LocalizedString(@"Touch ID", @"");
    
    LAContext *context = [[LAContext alloc] init];
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        if (context.biometryType == LABiometryTypeFaceID) {
            self.biometricsLabel.text = LocalizedString(@"Face ID", @"");
        }
    }
    
    wasPasscodeAlreadyEnabled = [LTHPasscodeViewController doesPasscodeExist];
    [[LTHPasscodeViewController sharedUser] setHidesCancelButton:NO];
    
    [LTHPasscodeViewController.sharedUser updateColorWithDesignToken];
    LTHPasscodeViewController.sharedUser.navigationBarTintColor = [UIColor surface1Background];
    LTHPasscodeViewController.sharedUser.navigationTintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    LTHPasscodeViewController.sharedUser.navigationTitleColor = UIColor.labelColor;
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureView];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}
        
#pragma mark - Private

- (void)configureView {
    BOOL doesPasscodeExist = [LTHPasscodeViewController doesPasscodeExist];
    [self.turnOnOffPasscodeSwitch setOn:doesPasscodeExist];
    if (doesPasscodeExist) {
        [self.biometricsSwitch setOn:[[LTHPasscodeViewController sharedUser] allowUnlockWithBiometrics]];
        
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        if (!wasPasscodeAlreadyEnabled) {
            wasPasscodeAlreadyEnabled = YES;
        }
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        self.requirePasscodeDetailLabel.text = LTHPasscodeViewController.timerDuration > RequirePasscodeAfterImmediatelly ? [NSString mnz_stringFromCallDuration:LTHPasscodeViewController.timerDuration] : LocalizedString(@"Immediately", @"");
    } else {
        [self.biometricsSwitch setOn:NO];
    }
    
    [self.tableView reloadData];
}

- (void)updateAppearance {
    self.requirePasscodeDetailLabel.textColor = UIColor.secondaryLabelColor;
    
    self.tableView.separatorColor = [UIColor mnz_separator];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];

    self.turnOnOffPasscodeLabel.textColor = UIColor.mnz_primaryTextColor;
    self.changePasscodeLabel.textColor = UIColor.mnz_primaryTextColor;
    self.requirePasscodeLabel.textColor = UIColor.mnz_primaryTextColor;
    self.requirePasscodeDetailLabel.textColor = UIColor.mnz_secondaryTextColor;

    [self.tableView reloadData];
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
        _requirePasscodeDetailLabel.text = @"";
    }
    
}

- (IBAction)biometricsSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setAllowUnlockWithBiometrics:sender.isOn];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL doesPasscodeExist = [LTHPasscodeViewController doesPasscodeExist];
    [self.changePasscodeLabel setEnabled:doesPasscodeExist];
    [self.biometricsSwitch setEnabled:doesPasscodeExist];
    [self.biometricsLabel setEnabled:doesPasscodeExist];
    self.requirePasscodeLabel.enabled = doesPasscodeExist;
    self.requirePasscodeDetailLabel.enabled = doesPasscodeExist;

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 1;
    
    switch (section) {
        case 0:
            if ([self isTouchIDAvailable]) {
                numberOfRows = 3;
            } else {
                numberOfRows = 2;
            }
            break;
    }
    
    return numberOfRows;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_backgroundElevated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 1)) {
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
        }
    }
    
    if (indexPath.section == 1) {
        if (LTHPasscodeViewController.doesPasscodeExist) {
            PasscodeTimeDurationTableViewController *passcodeTimeDurationTableViewController = [PasscodeTimeDurationTableViewController.alloc initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:passcodeTimeDurationTableViewController animated:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
