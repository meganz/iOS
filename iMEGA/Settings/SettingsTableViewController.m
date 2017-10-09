#import "SettingsTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "LTHPasscodeViewController.h"
#import "SVProgressHUD.h"
#import "SVWebViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "CameraUploads.h"

#import "AboutTableViewController.h"
#import "AdvancedTableViewController.h"
#import "CameraUploadsTableViewController.h"
#import "ChatSettingsTableViewController.h"
#import "FeedbackTableViewController.h"
#import "LanguageTableViewController.h"
#import "PasscodeTableViewController.h"
#import "SecurityOptionsTableViewController.h"

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
    
    self.helpLabel.text = AMLocalizedString(@"sendFeedbackLabel", @"Title of one of the Settings sections where you can 'Send Feedback' to MEGA");
    
    self.privacyPolicyLabel.text = AMLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'");
    self.termsOfServiceLabel.text = AMLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'");
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0: //Camera Uploads, Chat
        case 1:
        case 3:
        case 5: //Privacy Policy, Terms of Service
            numberOfRows = 2;
            break;
            
        case 2: //Advanced
        case 4: //Help
            numberOfRows = 1;
            break;
    }
    return numberOfRows;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
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
                LanguageTableViewController *languageTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"LanguageTableViewControllerID"];
                [self.navigationController pushViewController:languageTVC animated:YES];
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
