
#import "CopywriteWarningViewController.h"

#import "GetLinkTableViewController.h"

@interface CopywriteWarningViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *disagreeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *agreeBarButtonItem;

@end

@implementation CopywriteWarningViewController

- (IBAction)disagreeTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)agreeTapped:(UIBarButtonItem *)sender {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] setBool:YES forKey:@"agreedCopywriteWarning"];
    [self dismissViewControllerAnimated:YES completion:^{
        UINavigationController *getLinkNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
        GetLinkTableViewController *getLinkTVC = getLinkNavigationController.childViewControllers[0];
        getLinkTVC.nodesToExport = self.nodesToExport;
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:getLinkNavigationController animated:YES completion:nil];
    }];
}

@end
