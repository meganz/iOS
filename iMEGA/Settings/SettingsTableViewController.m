/**
 * @file SettingsTableViewController.m
 * @brief View controller that show your settings
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <MessageUI/MFMailComposeViewController.h>
#import "LTHPasscodeViewController.h"
#import "SVProgressHUD.h"
#import "SVWebViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "CameraUploads.h"

#import "SettingsTableViewController.h"
#import "CameraUploadsTableViewController.h"
#import "CloudDriveTableViewController.h"
#import "PasscodeTableViewController.h"
#import "AboutTableViewController.h"
#import "FeedbackTableViewController.h"
#import "SecurityOptionsTableViewController.h"

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
    
    languagesDictionary = @{//@"ar":@"Afrikaans",
                            //@"ar":@"العربية",
                            //@"bg":@"Bulgarian",
                            //@"bs":@"Bosanski Jezik",
                            @"ca":@"Català",
                            @"cs":@"Čeština",
                            //@"da":@"Dansk",
                            //@"de":@"Deutsch",
                            //@"ee":@"Ewe",
                            @"en":@"English",
                            @"es":@"Español",
                            //@"et":@"Estonian",
                            //@"eu":@"Euskera",
                            @"fi":@"Suomi",
                            //@"fr":@"Français",
                            //@"gl":@"Galician",
                            //@"he":@"עברית",
                            //@"hr":@"Hrvatski Jezik",
                            @"hu":@"Hungarian",
                            //@"id":@"Indonesian",
                            @"it":@"Italiano",
                            //@"ja":@"日本語",
                            //@"ko":@"한국어",
                            //@"lt":@"Lithuanian",
                            //@"lv":@"Latvian",
                            //@"ms":@"Malay",
                            //@"nb":@"Norsk bokmål",
                            @"nl":@"Nederlands",
                            //@"pl":@"Język Polski",
                            @"pt-BR":@"Português Brasileiro",
                            @"pt":@"Português",
                            //@"ro":@"Limba Română",
                            @"ru":@"Pусский язык",
                            //@"sk":@"Slovenský ",
                            //@"sl":@"Slovenščina",
                            @"sv":@"Svenska",
                            //@"th":@"Thai",
                            //@"tr":@"Türkçe",
                            //@"uk":@"Ukrainian",
                            //@"zh-Hans":@"简体中文",
                            @"zh-Hant":@"中文繁體"
                            };
    
    isLanguagePickerViewShown = NO;
    _languagePickerCellRowHeight = 216.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
    
    //Tab bar item titles
    for (NSInteger i = 0; i < [self.tabBarController.viewControllers count]; i++) {
        switch ([[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] tag]) {
            case 3:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"contactsTitle", @"Contacts")];
                break;
                
            case 4:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"transfers", @"Transfers")];
                break;
                
            case 5:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
                break;
                
            case 6:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"myAccount", @"My Account")];
                break;
                
            default:
                break;
        }
    }
    
    if (isLanguagePickerViewShown) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(_languagePickerViewIndexPath.row - 1) inSection:2];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
    
    [self.tableView reloadData];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)toggleLanguagePickerForSelectedIndexPath:(NSIndexPath *)indexPath {
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:2]];
    
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
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_languagePickerViewIndexPath.row inSection:2]]
                              withRowAnimation:UITableViewRowAnimationFade];
        _languagePickerViewIndexPath = nil;
    }
    
    if (!sameCellClicked) {
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:2];
        
        [self toggleLanguagePickerForSelectedIndexPath:indexPathToReveal];
        _languagePickerViewIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:2];
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
    if ([MEGAReachabilityManager isReachable]) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
            [mailComposeVC setMailComposeDelegate:self];
            [mailComposeVC setToRecipients:@[@"ios@mega.nz"]];
            
            NSString *version = [NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            
            [mailComposeVC setSubject:[NSString stringWithFormat:@"Feedback %@", version]];
            [self presentViewController:mailComposeVC animated:YES completion:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noEmailAccountConfigured", @"No email account configured")];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (void)showURL:(NSString *)urlString {
    if ([MEGAReachabilityManager isReachable]) {
        NSURL *URL = [NSURL URLWithString:urlString];
        SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
        [self.navigationController pushViewController:webViewController animated:YES];
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
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
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0:
        case 1:
        case 3:
            numberOfRows = 2;
            break;
            
        case 2: {
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
    if (indexPath.section == 2 && indexPath.row == 2 && isLanguagePickerViewShown) {
        heightForRow = _languagePickerCellRowHeight;
    }
    return heightForRow;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    NSString *cellID = @"";
    
    switch (indexPath.section) {
        case 0:
        case 1:
            cellID = ((indexPath.row == 0) ? @"settingsRightDetailCellID" : @"settingsBasicCellID");
            break;
            
        case 2: {
            if (indexPath.row == 0 || indexPath.row == 3) {
                cellID = @"settingsBasicCellID";
            } else if (indexPath.row == 1) {
                cellID = @"settingsRightDetailCellID";
            }  else if (indexPath.row == 2) {
                cellID = (isLanguagePickerViewShown ? @"languagePickerCellID" : @"settingsBasicCellID");
            }
            break;
        }
            
        case 3:
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
                [cell.textLabel setText:AMLocalizedString(@"rubbishBinLabel", nil)];
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
            
        case 2: {
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
            
        case 3: {
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
        case 0: { //Camera Uploads, Rubbish Bin
            if (indexPath.row == 0) {
                CameraUploadsTableViewController *cameraUploadsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
                [self.navigationController pushViewController:cameraUploadsTVC animated:YES];
                break;
            } else if (indexPath.row == 1) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
                CloudDriveTableViewController *cloud = [storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
                
                [self.navigationController pushViewController:cloud animated:YES];
                cloud.navigationItem.title = AMLocalizedString(@"rubbishBinLabel", @"The name for the rubbish bin label");
                
                [cloud setParentNode:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
                [cloud setDisplayMode:DisplayModeRubbishBin];
                break;
            }
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
         
        case 2: { //About, Language, Send Feedback, Rate Us
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
         
        case 3: { //Privacy Policy, Terms of Service
            if ([MEGAReachabilityManager isReachable]) {
                if (indexPath.row == 0) {
                    [self showURL:@"https://mega.nz/ios_privacy.html"];
                    break;
                } else if (indexPath.row == 1) {
                    [self showURL:@"https://mega.nz/ios_terms.html"];
                    break;
                }
            } else {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
                break;
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
