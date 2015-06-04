
#import "FeedbackTableViewController.h"
#import "SVProgressHUD.h"
#import "SVWebViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

@interface FeedbackTableViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *sendFeedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *helpCentreLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateUsLabel;

@end

@implementation FeedbackTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.sendFeedbackLabel setText:NSLocalizedString(@"sendFeedbackLabel", "Send feedback")];
    [self.helpCentreLabel setText:NSLocalizedString(@"helpCentreLabel", "Help centre")];
    [self.rateUsLabel setText:NSLocalizedString(@"rateUsLabel", "Rate us!")];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = @"Feedback";
    [self.navigationController.navigationBar.topItem setTitle:@"Feedback"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (self.feeling) {
        case 0:
            return 3;
            break;
     
        case 1:
            return 2;
            break;
            
        case 2:
            return 1;
            break;
            
        default:
            return 0;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"sendFeedbackFooter", "Contact the support team through email. All emails are read but given the high volume of requests we might not answer everyone individually.");
            break;
            
        case 1:
            return NSLocalizedString(@"helpCentreFooter", "Get support or read popular topics.");
            break;
            
        case 2:
            return NSLocalizedString(@"rateUsFooter", "Oh my, it's full of stars!");
            break;
            
        default:
            return nil;
            break;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            [self sendFeedback];
            break;
            
        case 1:
            [self openHelpCentre];
            break;
            
        case 2:
            [self rateApp];
            break;
            
        default:
            break;
    }
}


#pragma mark - select row actions

- (void)sendFeedback {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        [mailer setMailComposeDelegate:self];
        [mailer setToRecipients:@[@"ios@mega.co.nz"]];
        
        NSString *version = [NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        
        [mailer setSubject:[NSString stringWithFormat:@"Feedback %@", version]];
        [self presentViewController:mailer animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        }];
    } else {
        [SVProgressHUD showErrorWithStatus:@"No email account configured"];
    }
}

- (void)openHelpCentre {
    NSURL *URL = [NSURL URLWithString:@"https://mega.co.nz/ios_help.html"];
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)rateApp {
    NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id706857885?at=10l6dK"];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - MFMailComposeViewControllerDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
