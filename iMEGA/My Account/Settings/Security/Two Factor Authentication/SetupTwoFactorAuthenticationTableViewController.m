#import "SetupTwoFactorAuthenticationTableViewController.h"

#import "UIApplication+MNZCategory.h"

#import "CustomModalAlertViewController.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGA-Swift.h"
#import "TwoFactorAuthenticationViewController.h"

#import "LocalizationHelper.h"

@interface SetupTwoFactorAuthenticationTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *twoFactorAuthenticationSwitch;

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation SetupTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = LocalizedString(@"twoFactorAuthentication", @"");
    self.navigationItem.title = title;
    [self setMenuCapableBackButtonWithMenuTitle:title];
    
    self.twoFactorAuthenticationLabel.text = LocalizedString(@"twoFactorAuthentication", @"");
    self.twoFactorAuthenticationLabel.textAlignment = NSTextAlignmentNatural;

    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        
        self.twoFactorAuthenticationSwitch.on = self.twoFactorAuthenticationEnabled;
    }];
    [MEGASdk.shared multiFactorAuthCheckWithEmail:[MEGASdk.shared myEmail] delegate:delegate];
}

#pragma mark - Private

- (void)setupColors {
    self.tableView.separatorColor = [UIColor borderStrong];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];

    self.twoFactorAuthenticationLabel.textColor = UIColor.primaryTextColor;
}

#pragma mark - IBActions

- (IBAction)twoFactorAuthenticationTouchUpInside:(UIButton *)sender {
    if (self.twoFactorAuthenticationSwitch.isOn) {
        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationDisable;
        
        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
    } else {
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        [customModalAlertVC configureForTwoFactorAuthenticationWithRequestedByUser:true];
        
        [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return LocalizedString(@"whatIsTwoFactorAuthentication", @"Text shown as explanation of what is Two-Factor Authentication");
            
        default:
            return @"";
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView *)view;
        footerView.textLabel.textColor = UIColor.mnz_secondaryTextColor;
    }
}
@end
