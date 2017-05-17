
#import "WarningTransferQuotaViewController.h"
#import "UpgradeTableViewController.h"
#import "MEGANavigationController.h"

@interface WarningTransferQuotaViewController ()

@end

@implementation WarningTransferQuotaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - IBActions

- (IBAction)seePlansTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{        
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
        UIViewController *currentVC = [[UIApplication sharedApplication] delegate].window.rootViewController;
        [currentVC presentViewController:navigationController animated:YES completion:nil];
    }];
}

- (IBAction)dismissTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
