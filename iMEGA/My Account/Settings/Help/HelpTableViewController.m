#import "HelpTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "MEGASDK+MNZCategory.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"

#import "LocalizationHelper.h"

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
    
    self.navigationItem.title = LocalizedString(@"help", @"Menu item");
    
    self.sendFeedbackLabel.text = LocalizedString(@"sendFeedbackLabel", @"Title of one of the Settings sections where you can 'Send Feedback' to MEGA");
    self.helpCentreLabel.text = LocalizedString(@"helpCentreLabel", @"Title of the section to access MEGA's help centre");
    self.joinBetaLabel.text = LocalizedString(@"Join Beta", @"Section title that links you to the webpage that let you join and test the beta versions");
    self.rateUsLabel.text = LocalizedString(@"rateUsLabel", @"Title to rate the app");
    
    [self setupColors];
    self.reportIssueLabel.text = LocalizedString(@"help.reportIssue.title", @"");
}

- (SendFeedbackViewModel *)sendFeedbackViewModel {
    if (_sendFeedbackViewModel == nil) {
        _sendFeedbackViewModel = [self createSendFeedbackViewModel];
    }
    return _sendFeedbackViewModel;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [MEGASdk.shared mnz_isProAccount] ? 4 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    }
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (indexPath.section) {
            case 0:
                [self openHelpCentre];
                break;
                
            case 1:
                if (indexPath.row == 0) {
                    [self sendUserFeedback];
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

- (void)setupColors {
    self.tableView.separatorColor = [UIColor borderStrong];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
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
