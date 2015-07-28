
#import "FeedbackTableViewController.h"
#import "MEGAReachabilityManager.h"
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
    
    [self.sendFeedbackLabel setText:AMLocalizedString(@"sendFeedbackLabel", @"Send feedback")];
    [self.helpCentreLabel setText:AMLocalizedString(@"helpCentreLabel", @"Help centre")];
    [self.rateUsLabel setText:AMLocalizedString(@"rateUsLabel", @"Rate us!")];
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
            return AMLocalizedString(@"sendFeedbackFooter", @"Contact the support team through email. All emails are read but given the high volume of requests we might not answer everyone individually.");
            break;
            
        case 1:
            return AMLocalizedString(@"helpCentreFooter", @"Get support or read popular topics.");
            break;
            
        default:
            return nil;
            break;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MEGAReachabilityManager isReachable]) {
        switch (indexPath.section) {
                
            case 1:
                [self openHelpCentre];
                break;
                
            case 2:
                [self rateApp];
                break;
                
            default:
                break;
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}


#pragma mark - select row actions

- (void)openHelpCentre {
    NSURL *URL = [NSURL URLWithString:@"https://mega.nz/ios_help.html"];
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)rateApp {
    NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id706857885?at=10l6dK"];
    [[UIApplication sharedApplication] openURL:url];
}

@end
