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

#import "SettingsTableViewController.h"
#import "Helper.h"
#import "SVProgressHUD.h"
#import "FeedbackTableViewController.h"
#import "MEGASdkManager.h"
#import "UIImage+GKContact.h"
#import "PieChartView.h"
#import "UpgradeTableViewController.h"

@interface SettingsTableViewController () <UIActionSheetDelegate, MEGARequestDelegate, PieChartViewDelegate, PieChartViewDataSource> {
    long long usedSize;
    long long availableSize;
    long long localCacheSize;
    
    NSString *fullname;
}

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *storageLabel;
@property (weak, nonatomic) IBOutlet UILabel *upgradeLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *applicationLanguageLabel;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;
@property (weak, nonatomic) IBOutlet UILabel *logoutLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *accountTypeImageView;

@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;

@property (weak, nonatomic) IBOutlet UIImageView *localImageView;
@property (weak, nonatomic) IBOutlet UIImageView *usedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *availableImageView;

@property (weak, nonatomic) IBOutlet UILabel *localLabel;
@property (weak, nonatomic) IBOutlet UILabel *usedSpaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *availableLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLocalLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeUsedSpaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeAvailableLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *upgradeCell;

@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic) MEGAAccountType megaAccountType;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    
    fullname = [[NSString alloc] init];
    
    [[MEGASdkManager sharedMEGASdk] getUserAttibuteType:MEGAUserAttributeFirstname delegate:self];
    [[MEGASdkManager sharedMEGASdk] getUserAttibuteType:MEGAUserAttributeLastname delegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
    [self.upgradeLabel setText:AMLocalizedString(@"upgradeLabel", nil)];
    [self.cameraUploadsLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
    [self.passcodeLabel setText:AMLocalizedString(@"passcode", nil)];
    [self.applicationLanguageLabel setText:AMLocalizedString(@"applicationLanguageLabel", @"Application language")];
    [self.aboutLabel setText:AMLocalizedString(@"aboutLabel", nil)];
    [self.feedbackLabel setText:AMLocalizedString(@"feedbackLabel", nil)];
    [self.advancedLabel setText:AMLocalizedString(@"advancedLabel", nil)];
    [self.logoutLabel setText:AMLocalizedString(@"logoutLabel", nil)];
    
    [self.localLabel setText:AMLocalizedString(@"localLabel", @"Local")];
    [self.usedSpaceLabel setText:AMLocalizedString(@"usedSpaceLabel", @"Used")];
    [self.availableLabel setText:AMLocalizedString(@"availableLabel", @"Available")];
    
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
                
            default:
                break;
        }
    }
    
    self.pieChartView.layer.cornerRadius = CGRectGetWidth(self.pieChartView.frame)/2;
    self.pieChartView.layer.masksToBounds = YES;
    
    self.usedImageView.backgroundColor = [UIColor colorWithRed:43/255.0f green:166/255.0f blue:222/255.0f alpha:1.0f];
    self.localImageView.backgroundColor = [UIColor colorWithRed:19/255.0f green:224/255.0f blue:60/255.0f alpha:1.0f];
    self.availableImageView.backgroundColor = [UIColor whiteColor];
    
    self.usedImageView.layer.cornerRadius = CGRectGetWidth(self.usedImageView.frame)/2;
    self.usedImageView.layer.masksToBounds = YES;
    self.usedImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.usedImageView.layer.borderWidth = 2;
    
    self.localImageView.layer.cornerRadius = CGRectGetWidth(self.localImageView.frame)/2;
    self.localImageView.layer.masksToBounds = YES;
    self.localImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.localImageView.layer.borderWidth = 2;
    
    self.availableImageView.layer.cornerRadius = CGRectGetWidth(self.availableImageView.frame)/2;
    self.availableImageView.layer.masksToBounds = YES;
    self.availableImageView.layer.borderColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f].CGColor;
    self.availableImageView.layer.borderWidth = 2;
    
    long long thumbsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"]];
    
    long long previewsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"]];
    
    long long offileSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Offline"]];
    
    localCacheSize = thumbsSize + previewsSize + offileSize;
    
    NSString *localStorageString = [NSByteCountFormatter stringFromByteCount:localCacheSize countStyle:NSByteCountFormatterCountStyleMemory];
    [self.sizeLocalLabel setText:localStorageString];
    
    [[MEGASdkManager sharedMEGASdk] getPricingWithDelegate:self];
    [[MEGASdkManager sharedMEGASdk] getAccountDetailsWithDelegate:self];
    
    [self reloadUI];
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

#pragma mark - Private Methods

- (void)reloadUI {
    
    self.emailLabel.text = [[MEGASdkManager sharedMEGASdk] myEmail];
    [self setUserAvatar];
}

- (void)setUserAvatar {
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.emailLabel.text];
    NSString *avatarFilePath = [Helper pathForUser:user searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
    
    if (!fileExists) {
        [self.avatarImageView setImage:[UIImage imageForName:[user email].uppercaseString size:CGSizeMake(88, 88)]];
        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath delegate:self];
    } else {
        [self.avatarImageView setImage:[UIImage imageNamed:avatarFilePath]];
        
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
        self.avatarImageView.layer.masksToBounds = YES;
    }
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            [cell.contentView setBackgroundColor:megaLightGray];
            break;
            
        case 1:
            [cell.contentView setBackgroundColor:megaRed];
            break;
            
        case 3:
            [cell.contentView setBackgroundColor:megaDarkGray];
            break;
            
        default:
            break;
    }
}

#pragma mark - IBActions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Logout
    if (indexPath.section == 3) {
        [[MEGASdkManager sharedMEGASdk] logoutWithDelegate:self];
    }
    
    // Feedback
    if (indexPath.section == 2 && indexPath.row == 4) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:AMLocalizedString(@"feedbackActionSheet_title", @"How are you feeling?")
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"feedbackActionSheet_happyButton", @"Happy"), AMLocalizedString(@"feedbackActionSheet_confusedButton", @"Confused"), AMLocalizedString(@"feedbackActionSheet_unhappyButton", @"Unhappy"), nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

#pragma mark - Navigation

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"showUpgrade"]) {
//        UpgradeTableViewController *upgradeTableViewController = segue.destinationViewController;
//        upgradeTableViewController.pricing = self.pricing;
//        upgradeTableViewController.megaAccountType = self.megaAccountType;
//    }
//}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != FeedbackFeelingNone) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
        FeedbackTableViewController *feedbackTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedbackID"];
        feedbackTableViewController.feeling = buttonIndex;
        [self.navigationController pushViewController:feedbackTableViewController animated:YES];
    }
}

//For iOS 7 UIActionSheet color
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:megaRed forState:UIControlStateNormal];
        }
    }
}

#pragma mark - PieChartViewDelegate

- (CGFloat)centerCircleRadius {
    return 35.f;
}

#pragma mark - PieChartViewDataSource
- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView {
    return 3;
}
- (UIColor *)pieChartView:(PieChartView *)pieChartView colorForSliceAtIndex:(NSUInteger)index {
    switch (index) {
        case 0:
            return [UIColor colorWithRed:19/255.0f green:224/255.0f blue:60/255.0f alpha:1.0f];
            break;
            
        case 1:
            return [UIColor colorWithRed:43/255.0f green:166/255.0f blue:222/255.0f alpha:1.0f];
            break;
            
        case 2:
            return [UIColor whiteColor];
            break;
            
        default:
            return [UIColor whiteColor];
            break;
    }
}
- (double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index {
    if (localCacheSize == 0) {
        localCacheSize = 1;
    }
    
    switch (index) {
        case 0:
            return localCacheSize / localCacheSize;
            break;
            
        case 1:
            return usedSize / localCacheSize;
            break;
            
        case 2:
            return availableSize / localCacheSize;
            break;
            
        default:
            break;
    }
    return 2;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrUser: {
            //If paramType = 1 or 2 we are receiving the firstname or the lastname
            if (request.paramType) {
                if (request.paramType == MEGAUserAttributeLastname) {
                    fullname = [fullname stringByAppendingString:@" "];
                }
                fullname = [fullname stringByAppendingString:request.text];
                [self.userNameLabel setText:fullname];
            } else {
                [self setUserAvatar];
            }
            break;
        }
            
        case MEGARequestTypeAccountDetails: {
            self.megaAccountType = [[request megaAccountDetails] type];
            usedSize = [[request.megaAccountDetails storageUsed] longLongValue];
            availableSize = [[request.megaAccountDetails storageMax] longLongValue] - [[request.megaAccountDetails storageUsed] longLongValue];
            
            [self.pieChartView reloadData];
            
            NSString *maxStorageString = [NSByteCountFormatter stringFromByteCount:[[request.megaAccountDetails storageMax] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory];
            NSString *usedStorageString = [NSByteCountFormatter stringFromByteCount:[[request.megaAccountDetails storageUsed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory];
            NSString *availableStorageString = [NSByteCountFormatter stringFromByteCount:([[request.megaAccountDetails storageMax] longLongValue]- [[request.megaAccountDetails storageUsed] longLongValue])  countStyle:NSByteCountFormatterCountStyleMemory];
            
            [self.storageLabel setText:[NSString stringWithFormat:@"%@", maxStorageString]];
            
            [self.sizeUsedSpaceLabel setText:usedStorageString];
            [self.sizeAvailableLabel setText:availableStorageString];
            
            if (![request.megaAccountDetails type]) {
                [self.accountTypeImageView setImage:[UIImage imageNamed:@"profree"]];
                [self.accountTypeLabel setText:@"Free"];
            } else {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'"];
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                [formatter setLocale:locale];
                NSDate *expireDate = [[NSDate alloc] initWithTimeIntervalSince1970:[request.megaAccountDetails proExpiration]];
                
                NSString *expiresString = [NSString stringWithFormat:AMLocalizedString(@"expiresOn", @"(Expires on %@)"), [formatter stringFromDate:expireDate]];
                
                switch ([request.megaAccountDetails type]) {
                    case MEGAAccountTypeLite: {
                        [self.accountTypeImageView setImage:[UIImage imageNamed:@"prolite"]];
                        [self.accountTypeLabel setText:[NSString stringWithFormat:@"Pro Lite %@", expiresString]];
                        break;
                    }
                        
                    case MEGAAccountTypeProI: {
                        [self.accountTypeImageView setImage:[UIImage imageNamed:@"pro1"]];
                        [self.accountTypeLabel setText:[NSString stringWithFormat:@"Pro I %@", expiresString]];
                        break;
                    }
                        
                    case MEGAAccountTypeProII: {
                        [self.accountTypeImageView setImage:[UIImage imageNamed:@"pro2"]];
                        [self.accountTypeLabel setText:[NSString stringWithFormat:@"Pro II %@", expiresString]];
                        break;
                    }
                        
                    case MEGAAccountTypeProIII: {
                        [self.accountTypeImageView setImage:[UIImage imageNamed:@"pro3"]];
                        [self.accountTypeLabel setText:[NSString stringWithFormat:@"Pro III %@", expiresString]];
                        break;
                    }
                        
                    default:
                        break;
                }
            }
            break;
        }
            
        case MEGARequestTypeGetPricing:
            self.pricing = [request pricing];
            [self.upgradeCell setUserInteractionEnabled:YES];
            break;
            
        default:
            break;
    }
}

@end
