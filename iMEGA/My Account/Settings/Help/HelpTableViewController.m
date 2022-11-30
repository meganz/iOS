
#import "HelpTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGASDK+MNZCategory.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"

@interface HelpTableViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *helpCentreLabel;
@property (weak, nonatomic) IBOutlet UILabel *sendFeedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *joinBetaLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateUsLabel;
@property (weak, nonatomic) IBOutlet UILabel *reportIssueLabel;

@end

@implementation HelpTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"help", @"Menu item");
    
    self.sendFeedbackLabel.text = NSLocalizedString(@"sendFeedbackLabel", @"Title of one of the Settings sections where you can 'Send Feedback' to MEGA");
    self.helpCentreLabel.text = NSLocalizedString(@"helpCentreLabel", @"Title of the section to access MEGA's help centre");
    self.joinBetaLabel.text = NSLocalizedString(@"Join Beta", @"Section title that links you to the webpage that let you join and test the beta versions");
    self.rateUsLabel.text = NSLocalizedString(@"rateUsLabel", @"Title to rate the app");
    
    [self updateAppearance];
        self.reportIssueLabel.text = NSLocalizedString(@"help.reportIssue.title", nil);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[MEGASdkManager sharedMEGASdk] mnz_isProAccount] ? 4 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    }
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (indexPath.section) {
            case 0:
                [self openHelpCentre];
                break;
                
            case 1:
                if (indexPath.row == 0) {
                    [self sendFeedback];
                } else {
                    [self reportIssue];
                }
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
                
            case 2: //Join Beta
                [[NSURL URLWithString:@"https://testflight.apple.com/join/4x1P5Tnx"] mnz_presentSafariViewController];
                break;
                
            case 3: //Rate us
                [self rateApp];
                break;
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)sendFeedback {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self sendUserFeedback];
    }
}

- (void)openHelpCentre {
    [[NSURL URLWithString:@"https://help.mega.io"] mnz_presentSafariViewController];
}

- (void)reportIssue {
    ReportIssueViewRouter *reportIssueViewRouter = [ReportIssueViewRouter.alloc initWithPresenter:self];
    [reportIssueViewRouter start];
}

- (void)rateApp {
    NSString *appStoreLink = @"https://itunes.apple.com/us/app/mega/id706857885?mt=8&action=write-review";
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:appStoreLink] options:@{} completionHandler:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
