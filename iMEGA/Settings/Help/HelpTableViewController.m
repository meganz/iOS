
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
                [self sendFeedback];
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
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
            [mailComposeVC setMailComposeDelegate:self];
            mailComposeVC.toRecipients = @[@"iosfeedback@mega.nz"];
            
            NSString *version = [NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            
            [mailComposeVC setSubject:[NSString stringWithFormat:@"Feedback %@", version]];
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            
            NSString *appVersion = [[NSBundle mainBundle]
                                    objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
            NSString *shortAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
            
            NSArray *languageArray = NSBundle.mainBundle.preferredLocalizations;
            NSString *language = [NSLocale.currentLocale displayNameForKey:NSLocaleIdentifier value:languageArray.firstObject];
            
            NSString *connectionStatus = @"No internet connection";
            if ([MEGAReachabilityManager isReachable]) {
                if ([MEGAReachabilityManager isReachableViaWiFi]) {
                    connectionStatus = @"WiFi";
                } else {
                    connectionStatus = @"Mobile Data";
                }
            }
            NSString *myEmail = [[MEGASdkManager sharedMEGASdk] myEmail];
            NSString *proLevel = [MEGAAccountDetails stringForAccountType:MEGASdkManager.sharedMEGASdk.mnz_accountDetails.type];
            
            NSString *messageBody = NSLocalizedString(@"pleaseWriteYourFeedback", @"Message body of the email that appears when the users tap on \"Send feedback\"");
            messageBody = [messageBody stringByAppendingFormat:@"\n\n\nApp Information:\nApp Name: %@\n", appName];
            messageBody = [messageBody stringByAppendingFormat:@"App Version: %@ (%@)\n\n", shortAppVersion, appVersion];
            
            messageBody = [messageBody stringByAppendingFormat:@"Device information:\nDevice: %@\niOS Version: %@\nLanguage: %@\nTimezone: %@\nConnection Status: %@\nMEGA account: %@ (%@)", [[UIDevice currentDevice] deviceName], systemVersion, language, [NSTimeZone localTimeZone].name, connectionStatus, myEmail, proLevel];
            
            [mailComposeVC setMessageBody:messageBody isHTML:NO];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"help.reportIssue.attachLogFiles.title", nil) message:NSLocalizedString(@"help.reportIssue.attachLogFiles.message", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSURL *sourceURL = Logger.shared.logsDirectoryUrl;
                    NSData *compressedData = [LogFileCompressor.alloc zippedDataFrom:sourceURL];
                    
                    if (compressedData) {
                        [mailComposeVC addAttachmentData:compressedData mimeType:@"text/plain" fileName:@"MEGAiOSLogs.zip"];
                    }
                    
                    [self presentViewController:mailComposeVC animated:YES completion:nil];
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"no", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self presentViewController:mailComposeVC animated:YES completion:nil];
                }]];
                
                [self presentViewController:alertController animated:YES completion:nil];
            } else {
                [self presentViewController:mailComposeVC animated:YES completion:nil];
            }
        } else {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:NSLocalizedString(@"noEmailAccountConfigured", nil)];
        }
    }
}

- (void)openHelpCentre {
    [[NSURL URLWithString:@"https://mega.nz/help/client/ios/"] mnz_presentSafariViewController];
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
