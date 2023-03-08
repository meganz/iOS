
#import "CopyrightWarningViewController.h"

#import "MEGASdkManager.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif
#import "UIApplication+MNZCategory.h"

@interface CopyrightWarningViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *copyrightWarningNavigationItem;
@property (weak, nonatomic) IBOutlet UILabel *copyrightWarningLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightMessageLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *disagreeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *agreeBarButtonItem;

@end

@implementation CopyrightWarningViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.copyrightWarningNavigationItem.title = NSLocalizedString(@"copyrightWarning", @"A title for the Copyright Warning");
    self.copyrightWarningLabel.text = NSLocalizedString(@"copyrightWarningToAll", @"A title for the Copyright Warning dialog. Designed to make the user feel as though this is not targeting them, but is a warning for everybody who uses our service.");
    self.copyrightMessageLabel.text = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"copyrightMessagePart1", nil), NSLocalizedString(@"copyrightMessagePart2", nil)];
    self.agreeBarButtonItem.title = NSLocalizedString(@"agree", @"button caption text that the user clicks when he agrees");
    self.disagreeBarButtonItem.title = NSLocalizedString(@"disagree", @"button caption text that the user clicks when he disagrees");
    
    [self updateAppearance];
    
    UIBarButtonItem *flexibleBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.navigationController setToolbarItems:@[self.disagreeBarButtonItem, flexibleBarButtonItem, self.agreeBarButtonItem] animated:YES];
    [self.navigationController setToolbarHidden:NO];
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
}

#pragma mark - Public

+ (void)presentGetLinkViewControllerForNodes:(NSArray<MEGANode *> *)nodes inViewController:(UIViewController *)viewController {
    if (nodes != nil) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"agreedCopywriteWarning"]) {
            if ([MEGASdkManager.sharedMEGASdk publicLinks:MEGASortOrderTypeNone].size.intValue > 0) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedCopywriteWarning"];
            }
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"agreedCopywriteWarning"]) {
            MEGANavigationController *getLinkNC = [GetLinkViewController instantiateWithNodes:nodes];
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
        MEGANavigationController *getLinkNC = [GetLinkViewController instantiateWithNodes:self.nodesToExport];
        [UIApplication.mnz_presentingViewController presentViewController:getLinkNC animated:YES completion:nil];
    }];
}

@end
