
#import "CopyrightWarningViewController.h"

#import "GetLinkTableViewController.h"
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
        [[UIApplication mnz_visibleViewController] presentViewController:getLinkNavigationController animated:YES completion:nil];
    }];
}

@end
