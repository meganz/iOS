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

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    BOOL isLanguagePickerViewShown;
    
    NSDictionary *languagesDictionary;
    NSString *selectedLanguage;
}

@property (strong, nonatomic) IBOutlet UIPickerView *languagePickerView;

@property (nonatomic, strong) NSIndexPath *languagePickerViewIndexPath;
@property (nonatomic, assign) CGFloat languagePickerCellRowHeight;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *language = [[LocalizationSystem sharedLocalSystem] getLanguage];
    if (language) {
        selectedLanguage = language;
    } else {
        selectedLanguage = nil;
    }
    
    languagesDictionary = @{@"ar":@"العربية",
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
    
    isLanguagePickerViewShown = NO;
    _languagePickerCellRowHeight = 216.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
    
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
    
    if (isLanguagePickerViewShown) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(_languagePickerViewIndexPath.row - 1) inSection:3];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
    
    [self.tableView reloadData];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)toggleLanguagePickerForSelectedIndexPath:(NSIndexPath *)indexPath {
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:3]];
    
    if (isLanguagePickerViewShown) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

- (void)displayInlineLanguagePickerViewForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView beginUpdates];
    
    BOOL before = NO;
    if (_languagePickerViewIndexPath != nil) {
        before = _languagePickerViewIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (_languagePickerViewIndexPath.row - 1 == indexPath.row);
    
    if (isLanguagePickerViewShown) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_languagePickerViewIndexPath.row inSection:3]]
                              withRowAnimation:UITableViewRowAnimationFade];
        _languagePickerViewIndexPath = nil;
    }
    
    if (!sameCellClicked) {
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:3];
        
        [self toggleLanguagePickerForSelectedIndexPath:indexPathToReveal];
        _languagePickerViewIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:3];
    }
    
    [self.tableView endUpdates];
    
    [self updateLanguagePicker];
}

- (void)updateLanguagePicker {
    if (_languagePickerViewIndexPath != nil) {
        
        if (_languagePickerView != nil) {
            UITableViewCell *tableViewCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:(_languagePickerViewIndexPath.row - 1) inSection:_languagePickerViewIndexPath.section]];
            NSString *languageID = [Helper languageID:(_languagePickerViewIndexPath.row - 1)];
            NSString *titleForRow = [languagesDictionary objectForKey:languageID];
            [tableViewCell.detailTextLabel setText:titleForRow];
            [_languagePickerView selectRow:[_languagePickerView selectedRowInComponent:0] inComponent:0 animated:NO];
        }
    }
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
    return languagesDictionary.count;
}

#pragma mark - UIPickerViewDelegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *languageID = [Helper languageID:row];
    NSString *titleForRow = [languagesDictionary objectForKey:languageID];
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:AMLocalizedString(titleForRow, nil)];
    [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:kFont size:20.0] range:[titleForRow rangeOfString:titleForRow]];
    return mutableAttributedString;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row >= languagesDictionary.count) {
        return;
    }
    
    selectedLanguage = [Helper languageID:row];
    [[LocalizationSystem sharedLocalSystem] setLanguage:selectedLanguage];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0: //Camera Uploads, Chat
            numberOfRows = 2;
            break;
            
        case 1:
        case 4:
            numberOfRows = 2;
            break;
            
        case 2: //Advanced
            numberOfRows = 1;
            break;
            
        case 3: {
            if (_languagePickerViewIndexPath != nil) {
                numberOfRows = 4;
            } else {
                numberOfRows = 3;
            }
            break;
        }
    }
    return numberOfRows;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat heightForRow = 44.0;
    if (indexPath.section == 3 && indexPath.row == 2 && isLanguagePickerViewShown) {
        heightForRow = _languagePickerCellRowHeight;
    }
    return heightForRow;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    NSString *cellID = @"";
    
    switch (indexPath.section) {
        case 0:
            cellID = @"settingsRightDetailCellID";
            break;
            
        case 1:
            cellID = ((indexPath.row == 0) ? @"settingsRightDetailCellID" : @"settingsBasicCellID");
            break;
            
        case 3: {
            if (indexPath.row == 0 || indexPath.row == 3) {
                cellID = @"settingsBasicCellID";
            } else if (indexPath.row == 1) {
                cellID = @"settingsRightDetailCellID";
            }  else if (indexPath.row == 2) {
                cellID = (isLanguagePickerViewShown ? @"languagePickerCellID" : @"settingsBasicCellID");
            }
            break;
        }
           
        case 2: //Advanced
        case 4:
            cellID = @"settingsBasicCellID";
            break;
    }
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row == 0) {
                [cell.textLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
                [cell.detailTextLabel setText:([[CameraUploads syncManager] isCameraUploadsEnabled] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil))];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = AMLocalizedString(@"chat", @"Chat section header");
                cell.detailTextLabel.text = ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
            }
            break;
        }
            
        case 1: {
            if (indexPath.row == 0) {
                [cell.textLabel setText:AMLocalizedString(@"passcode", nil)];
                [cell.detailTextLabel setText:([LTHPasscodeViewController doesPasscodeExist] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil))];
            } else if (indexPath.row == 1) {
                [cell.textLabel setText:AMLocalizedString(@"securityOptions", @"Title of the Settings section where you can configure security details of your MEGA account")];
            }
            break;
        }
            
        case 2: { //Advanced
            [cell.textLabel setText:AMLocalizedString(@"advanced", @"Title of one of the Settings sections where you can configure 'Advanced' options")];
            break;
        }
            
        case 3: {
            if (indexPath.row == 0) {
                [cell.textLabel setText:AMLocalizedString(@"about", @"")];
            } else if (indexPath.row == 1) {
                [cell.textLabel setText:AMLocalizedString(@"language", @"")];
                [cell.detailTextLabel setText:[languagesDictionary objectForKey:selectedLanguage]];
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            } else if (indexPath.row == 2) {
                if (!isLanguagePickerViewShown) {
                    [cell.textLabel setText:AMLocalizedString(@"sendFeedbackLabel", nil)];
                }
            }  else if (indexPath.row == 3) {
                [cell.textLabel setText:AMLocalizedString(@"sendFeedbackLabel", nil)];
            }
            break;
        }
            
        case 4: {
            if (indexPath.row == 0) {
                [cell.textLabel setText:AMLocalizedString(@"privacyPolicyLabel", nil)];
            } else if (indexPath.row == 1) {
                [cell.textLabel setText:AMLocalizedString(@"termsOfServicesLabel", nil)];
            }
            break;
        }
    }
    
    return cell;
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
         
        case 3: { //About, Language, Send Feedback, Rate Us
            if (indexPath.row == 0) {
                AboutTableViewController *aboutTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"AboutTableViewControllerID"];
                [self.navigationController pushViewController:aboutTVC animated:YES];
                break;
            } else if (indexPath.row == 1) {
                [self displayInlineLanguagePickerViewForRowAtIndexPath:indexPath];
                isLanguagePickerViewShown = !isLanguagePickerViewShown;
                [self.tableView reloadData];
                break;
            } else if (indexPath.row == 2) {
                if (!isLanguagePickerViewShown) {
                    [self sendFeedback];
                    break;
                }
            } else if (indexPath.row == 3) {
                if (isLanguagePickerViewShown) {
                    [self sendFeedback];
                }
                break;
            }
        }
         
        case 4: { //Privacy Policy, Terms of Service
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
