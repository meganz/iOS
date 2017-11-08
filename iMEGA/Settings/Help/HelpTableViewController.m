
#import "HelpTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>
#import <SafariServices/SafariServices.h>

#import "SVProgressHUD.h"
#import "SVWebViewController.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

@interface HelpTableViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *helpCentreLabel;
@property (weak, nonatomic) IBOutlet UILabel *sendFeedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateUsLabel;

@end

@implementation HelpTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"help", @"Menu item");
    
    self.sendFeedbackLabel.text = AMLocalizedString(@"sendFeedbackLabel", @"Title of one of the Settings sections where you can 'Send Feedback' to MEGA");
    self.helpCentreLabel.text = AMLocalizedString(@"helpCentreLabel", @"Title of the section to access MEGA's help centre");
    self.rateUsLabel.text = AMLocalizedString(@"rateUsLabel", @"Title to rate the app");
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (indexPath.section) {
            case 0:
                [self openHelpCentre];
                break;
                
            case 1:
                [self sendFeedback];
                break;
                
            case 2:
                [self rateApp];
                break;
        }
    }
}


#pragma mark - Private

- (void)sendFeedback {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
            [mailComposeVC setMailComposeDelegate:self];
            [mailComposeVC setToRecipients:@[@"ios@mega.nz"]];
            
            NSString *version = [NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            
            [mailComposeVC setSubject:[NSString stringWithFormat:@"Feedback %@", version]];
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            
            NSString *appVersion = [[NSBundle mainBundle]
                                    objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
            NSString *shortAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
            
            NSArray *languageArray = [NSLocale preferredLanguages];
            NSString *language = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:[languageArray objectAtIndex:0]];
            
            NSString *connectionStatus = @"No internet connection";
            if ([MEGAReachabilityManager isReachable]) {
                if ([MEGAReachabilityManager isReachableViaWiFi]) {
                    connectionStatus = @"WiFi";
                } else {
                    connectionStatus = @"Mobile Data";
                }
            }
            NSString *myEmail = [[MEGASdkManager sharedMEGASdk] myEmail];
            
            NSString *messageBody = AMLocalizedString(@"pleaseWriteYourFeedback", @"Message body of the email that appears when the users tap on \"Send feedback\"");
            messageBody = [messageBody stringByAppendingFormat:@"\n\n\nApp Information:\nApp Name: %@\n", appName];
            messageBody = [messageBody stringByAppendingFormat:@"App Version: %@ (%@)\n\n", shortAppVersion, appVersion];
            
            messageBody = [messageBody stringByAppendingFormat:@"Device information:\nDevice: %@\niOS Version: %@\nLanguage: %@\nTimezone: %@\nConnection Status: %@\nMEGA account: %@", [[UIDevice currentDevice] deviceName], systemVersion, language, [NSTimeZone localTimeZone].name, connectionStatus, myEmail];
            
            [mailComposeVC setMessageBody:messageBody isHTML:NO];
            
            [self presentViewController:mailComposeVC animated:YES completion:nil];
        } else {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"noEmailAccountConfigured", nil)];
        }
    }
}

- (void)openHelpCentre {
    NSURL *URL = [NSURL URLWithString:@"https://mega.nz/help/client/ios/"];
    UIViewController *webViewController;
    if ([[UIDevice currentDevice] systemVersionGreaterThanOrEqualVersion:@"9.0"]) {
        webViewController = [[SFSafariViewController alloc] initWithURL:URL];
        if ([[UIDevice currentDevice] systemVersionGreaterThanOrEqualVersion:@"10.0"]) {
            ((SFSafariViewController *)webViewController).preferredControlTintColor = [UIColor mnz_redD90007];
        } else {
            webViewController.view.tintColor = [UIColor mnz_redD90007];
        }
    } else {
        webViewController = [[SVWebViewController alloc] initWithURL:URL];
    }
    [self presentViewController:webViewController animated:YES completion:nil];
}

- (void)rateApp {
    //TODO: Add logic to allow user rate the app from the app.
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
