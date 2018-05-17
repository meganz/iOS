
#import "CopyrightWarningViewController.h"

#import "GetLinkTableViewController.h"
#import "MEGASdkManager.h"
#import "UIApplication+MNZCategory.h"

@interface CopyrightWarningViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *copyrightWarningNavigationItem;
@property (weak, nonatomic) IBOutlet UILabel *copyrightWarningLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightMessageLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *disagreeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *agreeBarButtonItem;

@end

@implementation CopyrightWarningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.copyrightWarningNavigationItem.title = AMLocalizedString(@"copyrightWarning", @"A title for the Copyright Warning");
    self.copyrightWarningLabel.text = AMLocalizedString(@"copyrightWarningToAll", @"A title for the Copyright Warning dialog. Designed to make the user feel as though this is not targeting them, but is a warning for everybody who uses our service.");
    self.copyrightMessageLabel.text = [NSString stringWithFormat:@"%@\n\n%@", AMLocalizedString(@"copyrightMessagePart1", nil), AMLocalizedString(@"copyrightMessagePart2", nil)];
    self.agreeBarButtonItem.title = AMLocalizedString(@"agree", @"button caption text that the user clicks when he agrees");
    self.disagreeBarButtonItem.title = AMLocalizedString(@"disagree", @"button caption text that the user clicks when he disagrees");
}

+ (void)presentGetLinkViewControllerForNodes:(NSArray<MEGANode *> *)nodes inViewController:(UIViewController *)viewController {
    if (nodes != nil) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"agreedCopywriteWarning"]) {
            if ([[[MEGASdkManager sharedMEGASdk] publicLinks].size intValue] > 0) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedCopywriteWarning"];
            }
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"agreedCopywriteWarning"]) {
            UINavigationController *getLinkNC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
            GetLinkTableViewController *getLinkTVC = getLinkNC.childViewControllers.firstObject;
            getLinkTVC.nodesToExport = nodes;
            [viewController presentViewController:getLinkNC animated:YES completion:nil];
        } else {
            UINavigationController *copyrightWarningNC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CopywriteWarningNavigationControllerID"];
            CopyrightWarningViewController *copyrightWarningVC = copyrightWarningNC.childViewControllers.firstObject;
            copyrightWarningVC.nodesToExport = nodes;
            [viewController presentViewController:copyrightWarningNC animated:YES completion:nil];
        }
    }
}

#pragma mark - IBActions

- (IBAction)disagreeTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)agreeTapped:(UIBarButtonItem *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedCopywriteWarning"];
    [self dismissViewControllerAnimated:YES completion:^{
        UINavigationController *getLinkNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
        GetLinkTableViewController *getLinkTVC = getLinkNavigationController.childViewControllers[0];
        getLinkTVC.nodesToExport = self.nodesToExport;
        [UIApplication.mnz_visibleViewController presentViewController:getLinkNavigationController animated:YES completion:nil];
    }];
}

@end
