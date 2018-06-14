
#import "DisablingTwoFactorAuthenticationTableViewController.h"

#import "MEGASdkManager.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "TwoFactorAuthentication.h"
#import "TwoFactorAuthenticationViewController.h"

@interface DisablingTwoFactorAuthenticationTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *twoFactorAuthenticationSwitch;

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation DisablingTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.twoFactorAuthenticationLabel.text = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.twoFactorAuthenticationSwitch.on = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        
        self.twoFactorAuthenticationSwitch.on = self.twoFactorAuthenticationEnabled;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

#pragma mark - IBActions

- (IBAction)twoFactorAuthenticationSwitchValueChanged:(UISwitch *)sender {
    if (!sender.isOn) {
        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationDisable;
        
        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
    }
}

@end
