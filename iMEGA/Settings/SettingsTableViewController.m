/**
 * @file SettingsTableViewController.m
 * @brief View controller that show your settings
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
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

#import "SettingsTableViewController.h"
#import "Helper.h"
#import "SVProgressHUD.h"
#import "FeedbackTableViewController.h"

@interface SettingsTableViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *storageLabel;
@property (weak, nonatomic) IBOutlet UILabel *upgradeLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;
@property (weak, nonatomic) IBOutlet UILabel *logoutLabel;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.upgradeLabel setText:NSLocalizedString(@"upgradeLabel", nil)];
    [self.cameraUploadsLabel setText:NSLocalizedString(@"cameraUploadsLabel", nil)];
    [self.passcodeLabel setText:NSLocalizedString(@"passcodeLabel", nil)];
    [self.aboutLabel setText:NSLocalizedString(@"aboutLabel", nil)];
    [self.feedbackLabel setText:NSLocalizedString(@"feedbackLabel", nil)];
    [self.advancedLabel setText:NSLocalizedString(@"advancedLabel", nil)];
    [self.logoutLabel setText:NSLocalizedString(@"logoutLabel", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadUI];
}

#pragma mark - Private Methods

- (void)reloadUI {
    
    self.emailLabel.text = [[MEGASdkManager sharedMEGASdk] myEmail];
    [self setUserAvatar];
    
    [[MEGASdkManager sharedMEGASdk] getAccountDetailsWithDelegate:self];
    [[MEGASdkManager sharedMEGASdk] getUserDataWithDelegate:self];
}

- (void)setUserAvatar {
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.emailLabel.text];
    NSString *avatarFilePath = [Helper pathForUser:user searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
    
    if (!fileExists) {
        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath delegate:self];
    } else {
        [self.avatarImageView setImage:[UIImage imageNamed:avatarFilePath]];
        
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
        self.avatarImageView.layer.masksToBounds = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Logout
    if (indexPath.section == 2) {
        [[MEGASdkManager sharedMEGASdk] logoutWithDelegate:self];
    }
    
    // Feedback
    if (indexPath.section == 1 && indexPath.row == 3) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"¿Cómo te sientes?"
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel")
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Feliz", @"Confuso", @"Infeliz", nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != FeedbackFeelingNone) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
        FeedbackTableViewController *feedbackTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedbackID"];
        feedbackTableViewController.feeling = buttonIndex;
        [self.navigationController pushViewController:feedbackTableViewController animated:YES];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeLogout:
            [SVProgressHUD showWithStatus:NSLocalizedString(@"logout", @"Logout...")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeLogout: {
            [Helper logout];
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeGetAttrUser: {
            [self setUserAvatar];
            break;
        }
            
        case MEGARequestTypeAccountDetails: {
            NSString *maxStorageString = [NSByteCountFormatter stringFromByteCount:[[request.megaAccountDetails storageMax] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory];
            NSString *usedStorageString = [NSByteCountFormatter stringFromByteCount:[[request.megaAccountDetails storageUsed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory];
            
            [self.storageLabel setText:[NSString stringWithFormat:NSLocalizedString(@"usedSpaceOfTotalSpace", nil), usedStorageString, maxStorageString]];
            break;
        }
            
        case MEGARequestTypeGetUserData: {
            [self.userNameLabel setText:[request name]];
            
            //Needed for load the avatar when user enter on settings before fetchnodes finish
            self.emailLabel.text = [[MEGASdkManager sharedMEGASdk] myEmail];
            [self setUserAvatar];
            break;
        }
            
        default:
            break;
    }
}

@end
