#import "SettingsTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "LTHPasscodeViewController.h"
#import "SVProgressHUD.h"
#import "SVWebViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "CameraUploads.h"

#import "CameraUploadsTableViewController.h"
#import "ChatSettingsTableViewController.h"
#import "PasscodeTableViewController.h"
#import "AboutTableViewController.h"
#import "FeedbackTableViewController.h"
#import "SecurityOptionsTableViewController.h"
#import "AdvancedTableViewController.h"

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDictionary *languagesDictionary;
@property (weak, nonatomic) NSString *selectedLanguage;

@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *securityOptionsLabel;

@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *languageLabel;
@property (weak, nonatomic) IBOutlet UILabel *languageDetailLabel;

@property (nonatomic, getter=isLanguagePickerViewShown) BOOL languagePickerViewShown;
@property (strong, nonatomic) IBOutlet UIPickerView *languagePickerView;
@property (nonatomic, strong) NSIndexPath *languagePickerViewIndexPath;
@property (nonatomic, assign) CGFloat languagePickerCellRowHeight;

@property (weak, nonatomic) IBOutlet UILabel *helpLabel;

@property (weak, nonatomic) IBOutlet UILabel *privacyPolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsOfServiceLabel;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *language = [[LocalizationSystem sharedLocalSystem] getLanguage];
    if (language) {
        self.selectedLanguage = language;
    } else {
        self.selectedLanguage = nil;
    }
    
    self.languagesDictionary = @{@"ar":@"العربية",
                            @"bg":@"български език",
                            @"cs":@"Čeština",
                            @"de":@"Deutsch",
                            @"en":@"English",
                            @"es":@"Español",
                            @"fa":@"فارسی",
                            @"fi":@"Suomi",
                            @"fr":@"Français",
                            @"he":@"עברית",
                            @"hu":@"magyar",
                            @"id":@"Bahasa Indonesia",
                            @"it":@"Italiano",
                            @"ja":@"日本語",
                            @"ko":@"한국어",
                            @"nl":@"Nederlands",
                            @"pl":@"Język Polski",
                            @"pt-br":@"Português Brasileiro",
                            @"pt":@"Português",
                            @"ro":@"Limba Română",
                            @"ru":@"Pусский язык",
                            @"sk":@"Slovenský",
                            @"sl":@"Slovenščina",
                            @"sr":@"српски језик",
                            @"sv":@"Svenska",
                            @"th":@"ไทย",
                            @"tl":@"Tagalog",
                            @"tr":@"Türkçe",
                            @"uk":@"українська мова",
                            @"vi":@"Tiếng Việt",
                            @"zh-Hans":@"简体中文",
                            @"zh-Hant":@"中文繁體"};
    
    self.languagePickerViewShown = NO;
    self.languagePickerView.hidden = YES;
    self.languagePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    NSUInteger languageIndex = [[Helper languagesSupportedIDs] indexOfObject:self.selectedLanguage];
    [self.languagePickerView selectRow:languageIndex inComponent:0 animated:NO];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSArray *viewControllersMutableArray = [self.tabBarController viewControllers];
    for (NSInteger i = 0; i < [viewControllersMutableArray count]; i++) {
        UITabBarItem *tabBarItem = [[viewControllersMutableArray objectAtIndex:i] tabBarItem];
        switch (tabBarItem.tag) {
            case 0:
                tabBarItem.title = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                break;
                
            case 1:
                tabBarItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
                break;
                
            case 2:
                tabBarItem.title = AMLocalizedString(@"chat", @"Chat section header");
                break;
            
            case 3:
                [tabBarItem setTitle:AMLocalizedString(@"shared", nil)];
                break;
                
            case 4:
                tabBarItem.title = AMLocalizedString(@"offline", @"Title of the Offline section");
                break;
                
            case 5:
                tabBarItem.title = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section");
                break;
                
            case 6:
                tabBarItem.title = AMLocalizedString(@"transfers", @"Title of the Transfers section");
                break;
                
            case 8:
                [tabBarItem setTitle:AMLocalizedString(@"settingsTitle", nil)];
                break;
                
            case 7:
                [tabBarItem setTitle:AMLocalizedString(@"myAccount", nil)];
                break;
                
            default:
                break;
        }
    }
    [self updateUI];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)updateUI {
    self.navigationItem.title = AMLocalizedString(@"settingsTitle", @"Title of the Settings section");
    
    self.cameraUploadsLabel.text = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    self.cameraUploadsDetailLabel.text = ([[CameraUploads syncManager] isCameraUploadsEnabled] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    self.chatLabel.text = AMLocalizedString(@"chat", @"Chat section header");
    self.chatDetailLabel.text = ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    
    self.passcodeLabel.text = AMLocalizedString(@"passcode", nil);
    self.passcodeDetailLabel.text = ([LTHPasscodeViewController doesPasscodeExist] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    self.securityOptionsLabel.text = AMLocalizedString(@"securityOptions", @"Title of the Settings section where you can configure security details of your MEGA account");
    
    self.advancedLabel.text = AMLocalizedString(@"advanced", @"Title of one of the Settings sections where you can configure 'Advanced' options");
    
    self.aboutLabel.text = AMLocalizedString(@"about", @"Title of one of the Settings sections where you can see things 'About' the app");
    self.languageLabel.text = AMLocalizedString(@"language", @"Title of one of the Settings sections where you can set up the 'Language' of the app");
    self.languageDetailLabel.text = [self.languagesDictionary objectForKey:self.selectedLanguage];
    
    self.helpLabel.text = AMLocalizedString(@"sendFeedbackLabel", @"Title of one of the Settings sections where you can 'Send Feedback' to MEGA");
    
    self.privacyPolicyLabel.text = AMLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'");
    self.termsOfServiceLabel.text = AMLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'");
}

- (void)showLanguagePickerCell {
    self.languagePickerViewShown = YES;
    
    self.languagePickerView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.languagePickerView.alpha = 1.0f;
    }];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)hideLanguagePickerCell {
    self.languagePickerViewShown = NO;
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.languagePickerView.alpha = 0.0f;
        self.languagePickerView.hidden = YES;
    }];
}

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
            
            NSString *messageBody = AMLocalizedString(@"pleaseWriteYourFeedback", @"Message body of the email that appears when the users tap on \"Send feedback\"");
            messageBody = [messageBody stringByAppendingFormat:@"\n\n\nApp Information:\nApp Name: %@\n", appName];
            messageBody = [messageBody stringByAppendingFormat:@"App Version: %@ (%@)\n\n", shortAppVersion, appVersion];
            
            messageBody = [messageBody stringByAppendingFormat:@"Device information:\nDevice: %@\niOS Version: %@\nLanguage: %@\nTimezone: %@\nConnection Status: %@", [[UIDevice currentDevice] deviceName], systemVersion, language, [NSTimeZone localTimeZone].name, connectionStatus];
            
            [mailComposeVC setMessageBody:messageBody isHTML:NO];
            
            [self presentViewController:mailComposeVC animated:YES completion:nil];
        } else {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"noEmailAccountConfigured", nil)];
        }
    }
}

- (void)showURL:(NSString *)urlString {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSURL *URL = [NSURL URLWithString:urlString];
        SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.languagesDictionary.count;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *labelView = (UILabel *)view;
    if (!labelView) {
        labelView = [[UILabel alloc] init];
        labelView.font = [UIFont mnz_SFUIRegularWithSize:17.0f];
        labelView.textColor = [UIColor mnz_black333333];
        labelView.textAlignment = NSTextAlignmentCenter;
    }
    
    NSString *languageID = [Helper languageID:row];
    labelView.text = [self.languagesDictionary objectForKey:languageID];
    
    return labelView;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row >= self.languagesDictionary.count) {
        return;
    }
    
    self.selectedLanguage = [Helper languageID:row];
    [[LocalizationSystem sharedLocalSystem] setLanguage:self.selectedLanguage];
    [[MEGASdkManager sharedMEGASdk] setLanguageCode:self.selectedLanguage];
    
    [self updateUI];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0: //Camera Uploads, Chat
            numberOfRows = 2;
            break;
            
        case 1:
        case 5: //Privacy Policy, Terms of Service
            numberOfRows = 2;
            break;
            
        case 2: //Advanced
        case 4: //Help
            numberOfRows = 1;
            break;
            
        case 3: {
            self.isLanguagePickerViewShown ? (numberOfRows = 3) : (numberOfRows = 2);
            break;
        }
    }
    return numberOfRows;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat heightForRow = 44.0;
    if (indexPath.section == 3 && indexPath.row == 2 && self.isLanguagePickerViewShown) {
        heightForRow = self.isLanguagePickerViewShown ? 216.0f : 0.0f;
    }
    return heightForRow;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0: { //Camera Uploads, Chat
            if (indexPath.row == 0) {
                CameraUploadsTableViewController *cameraUploadsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
                [self.navigationController pushViewController:cameraUploadsTVC animated:YES];
            } else if (indexPath.row == 1) {
                ChatSettingsTableViewController *chatSettingsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatSettingsTableViewControllerID"];
                [self.navigationController pushViewController:chatSettingsTVC animated:YES];
            }
            break;
        }
        
        case 1: { //Pascode, Security Options
            if (indexPath.row == 0) {
                PasscodeTableViewController *passcodeTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"PasscodeTableViewControllerID"];
                [self.navigationController pushViewController:passcodeTVC animated:YES];
                break;
            } else if (indexPath.row == 1) {
                SecurityOptionsTableViewController *securityOptionsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"SecurityOptionsTableViewControllerID"];
                [self.navigationController pushViewController:securityOptionsTVC animated:YES];
                break;
            }
        }
            
        case 2: { //Advanced
            AdvancedTableViewController *advancedTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"AdvancedTableViewControllerID"];
            [self.navigationController pushViewController:advancedTVC animated:YES];
            break;
        }
         
        case 3: { //About, Language
            if (indexPath.row == 0) {
                AboutTableViewController *aboutTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"AboutTableViewControllerID"];
                [self.navigationController pushViewController:aboutTVC animated:YES];
                break;
            } else if (indexPath.row == 1) {
                self.isLanguagePickerViewShown ? [self hideLanguagePickerCell] : [self showLanguagePickerCell];
                [self.tableView reloadData];
                break;
            } else if (indexPath.row == 2) {
                if (!self.isLanguagePickerViewShown) {
                    [self sendFeedback];
                    break;
                }
            } else if (indexPath.row == 3) {
                if (self.isLanguagePickerViewShown) {
                    [self sendFeedback];
                }
                break;
            }
        }
            
        case 4: { //Help
            if (indexPath.row == 0) {
                [self sendFeedback];
                break;
            }
            break;
        }
         
        case 5: { //Privacy Policy, Terms of Service
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                if (indexPath.row == 0) {
                    [self showURL:@"https://mega.nz/ios_privacy.html"];
                    break;
                } else if (indexPath.row == 1) {
                    [self showURL:@"https://mega.nz/ios_terms.html"];
                    break;
                }
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
