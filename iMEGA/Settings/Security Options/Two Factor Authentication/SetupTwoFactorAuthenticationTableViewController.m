
#import "SetupTwoFactorAuthenticationTableViewController.h"

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

#import "CustomModalAlertViewController.h"
#import "EnablingTwoFactorAuthenticationTableViewController.h"
#import "MEGASdkManager.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "TwoFactorAuthentication.h"
#import "TwoFactorAuthenticationViewController.h"

@interface SetupTwoFactorAuthenticationTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *twoFactorAuthenticationSwitch;

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation SetupTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.twoFactorAuthenticationLabel.text = AMLocalizedString(@"twoFactorAuthentication", @"");
    
}

- (void)viewWillAppear:(BOOL)animated {
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        
        self.twoFactorAuthenticationSwitch.on = self.twoFactorAuthenticationEnabled;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

#pragma mark - IBActions

- (IBAction)twoFactorAuthenticationTouchUpInside:(UIButton *)sender {
    if (self.twoFactorAuthenticationSwitch.isOn) {
        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationDisable;
        
        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
    } else {
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        customModalAlertVC.image = nil;
        customModalAlertVC.viewTitle = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthentication", @"");
        customModalAlertVC.detail = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthenticationDescription", @"");
        customModalAlertVC.action = AMLocalizedString(@"beginSetup", @"");
        customModalAlertVC.dismiss = AMLocalizedString(@"cancel", @"");
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] multiFactorAuthGetCodeWithDelegate:self];
            
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        customModalAlertVC.onDismiss = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        [UIApplication.mnz_visibleViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        [SVProgressHUD showErrorWithStatus:error.name];
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeMultiFactorAuthGet: {
            [SVProgressHUD dismiss];
            
            EnablingTwoFactorAuthenticationTableViewController *enablingTwoFactorAuthenticationTVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"EnablingTwoFactorAuthenticationTableViewControllerID"];
            enablingTwoFactorAuthenticationTVC.seed = request.text; //Returns the Base32 secret code needed to configure multi-factor authentication.
            
            [self.navigationController pushViewController:enablingTwoFactorAuthenticationTVC animated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
