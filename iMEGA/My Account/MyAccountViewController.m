#import "MyAccountViewController.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAImagePickerController.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "UsageViewController.h"
#import "SettingsTableViewController.h"

@interface MyAccountViewController () <MEGARequestDelegate, MEGAChatRequestDelegate> {
    BOOL isAccountDetailsAvailable;
    
    NSNumber *localSize;
    NSNumber *cloudDriveSize;
    NSNumber *rubbishBinSize;
    NSNumber *incomingSharesSize;
    NSNumber *usedStorage;
    NSNumber *maxStorage;
    
    NSByteCountFormatter *byteCountFormatter;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIButton *usageButton;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;

@property (weak, nonatomic) IBOutlet UIImageView *userAvatarImageView;

@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UILabel *settingsLabel;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UILabel *localLabel;
@property (weak, nonatomic) IBOutlet UILabel *localUsedSpaceLabel;

@property (weak, nonatomic) IBOutlet UILabel *usedLabel;
@property (weak, nonatomic) IBOutlet UILabel *usedSpaceLabel;

@property (weak, nonatomic) IBOutlet UILabel *availableLabel;
@property (weak, nonatomic) IBOutlet UILabel *availableSpaceLabel;

@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;

@property (weak, nonatomic) IBOutlet UIView *freeView;
@property (weak, nonatomic) IBOutlet UILabel *freeStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *upgradeToProButton;

@property (weak, nonatomic) IBOutlet UIView *proView;
@property (weak, nonatomic) IBOutlet UILabel *proStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *proExpiryDateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *logoutButtonTopImageView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoutButtonBottomImageView;

@property (nonatomic) MEGAAccountType megaAccountType;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usedLabelTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accountTypeLabelTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *freeViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upgradeAccountTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *proViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoutButtonTopLayoutConstraint;

@end

@implementation MyAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"myAccount", @"Title of the app section where you can see your account details")];
    
    self.editBarButtonItem.title = AMLocalizedString(@"edit", @"Caption of a button to edit the files that are selected");
    
    [self.usageLabel setText:AMLocalizedString(@"usage", nil)];
    [self.settingsLabel setText:AMLocalizedString(@"settingsTitle", nil)];
    
    [self.localLabel setText:AMLocalizedString(@"localLabel", @"Local")];
    [self.usedLabel setText:AMLocalizedString(@"usedSpaceLabel", @"Used")];
    [self.availableLabel setText:AMLocalizedString(@"availableLabel", @"Available")];
    
    NSString *accountTypeString = [AMLocalizedString(@"accountType", @"title of the My Account screen") stringByReplacingOccurrencesOfString:@":" withString:@""];
    self.accountTypeLabel.text = accountTypeString;
    
    [self.freeStatusLabel setText:AMLocalizedString(@"free", nil)];
    [self.upgradeToProButton setTitle:AMLocalizedString(@"upgradeAccount", nil) forState:UIControlStateNormal];
    
    [self.logoutButton setTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") forState:UIControlStateNormal];
    
    isAccountDetailsAvailable = NO;
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    if ([[UIDevice currentDevice] iPhone4X]) {
        self.usedLabelTopLayoutConstraint.constant = 8.0f;
        self.accountTypeLabelTopLayoutConstraint.constant = 9.0f;
        self.freeViewTopLayoutConstraint.constant = 8.0f;
        self.upgradeAccountTopLayoutConstraint.constant = 8.0f;
        self.proViewTopLayoutConstraint.constant = 8.0f;
        self.logoutButtonTopLayoutConstraint.constant = 0.0f;
        self.logoutButtonTopImageView.backgroundColor = nil;
        self.logoutButtonBottomImageView.backgroundColor = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    
    long long thumbsSize = [Helper sizeOfFolderAtPath:[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"]];
    long long previewsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"]];
    long long offlineSize = [Helper sizeOfFolderAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    
    localSize = [NSNumber numberWithLongLong:(thumbsSize + previewsSize + offlineSize)];
    
    NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:[localSize longLongValue]];
    [_localUsedSpaceLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    
    [[MEGASdkManager sharedMEGASdk] getAccountDetails];
    
    [self setUserAvatar];
    
    self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
    self.emailLabel.text = [[MEGASdkManager sharedMEGASdk] myEmail];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.presentedViewController == nil) {
        if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
            [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegate:self];
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)setUserAvatar {
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    [self.userAvatarImageView mnz_setImageForUserHandle:myUser.handle];
}

- (NSMutableAttributedString *)textForSizeLabels:(NSString *)stringFromByteCount {
    
    NSMutableAttributedString *firstPartMutableAttributedString;
    NSMutableAttributedString *secondPartMutableAttributedString;
    
    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    NSRange firstPartRange;
    
    NSArray *stringComponentsArray = [firstPartString componentsSeparatedByString:@","];
    NSString *secondPartString;
    if ([stringComponentsArray count] > 1) {
        NSString *integerPartString = [stringComponentsArray objectAtIndex:0];
        NSString *fractionalPartString = [stringComponentsArray objectAtIndex:1];
        firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:integerPartString];
        firstPartRange = [integerPartString rangeOfString:integerPartString];
        secondPartString = [NSString stringWithFormat:@".%@ %@", fractionalPartString, [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray]];
    } else {
        firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
        firstPartRange = [firstPartString rangeOfString:firstPartString];
        secondPartString = [NSString stringWithFormat:@" %@", [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray]];
    }
    NSRange secondPartRange = [secondPartString rangeOfString:secondPartString];
    secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont mnz_SFUIRegularWithSize:20.0f]
                                             range:firstPartRange];
    
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                              value:[UIFont mnz_SFUIRegularWithSize:12.0f]
                                              range:secondPartRange];
    
    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (void)presentChangeAvatarAlertController {
    UIAlertController *changeAvatarAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [changeAvatarAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *fromPhotosAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"choosePhotoVideo", @"Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    [fromPhotosAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [changeAvatarAlertController addAction:fromPhotosAlertAction];
    
    UIAlertAction *captureAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"capturePhotoVideo", @"Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
                if (permissionGranted) {
                    // Permission has been granted. Use dispatch_async for any UI updating code because this block may be executed in a thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *cameraPermissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
                        [cameraPermissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [cameraPermissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            //Check Camera permissions
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }]];
                        
                        [self presentViewController:cameraPermissionsAlertController animated:YES completion:nil];
                    });
                }
            }];
        }
    }];
    [captureAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [changeAvatarAlertController addAction:captureAlertAction];
    
    changeAvatarAlertController.modalPresentationStyle = UIModalPresentationPopover;
    changeAvatarAlertController.popoverPresentationController.barButtonItem = self.editBarButtonItem;
    changeAvatarAlertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:changeAvatarAlertController animated:YES completion:nil];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    MEGAImagePickerController *imagePickerController = [[MEGAImagePickerController alloc] initToChangeAvatarWithSourceType:sourceType];
    imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
    imagePickerController.popoverPresentationController.sourceView = self.view;
    imagePickerController.popoverPresentationController.barButtonItem = self.editBarButtonItem;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)editTouchUpInside:(UIBarButtonItem *)sender {
    UIAlertController *editAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [editAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *changeNameAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"changeName", @"Button title that allows the user change his name") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MEGANavigationController *changeNameNavigationController = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangeNameNavigationControllerID"];
        [self presentViewController:changeNameNavigationController animated:YES completion:nil];
    }];
    [changeNameAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [editAlertController addAction:changeNameAlertAction];
    
    UIAlertAction *changeAvatarAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"changeAvatar", @"button that allows the user the change his avatar") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentChangeAvatarAlertController];
    }];
    [changeAvatarAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
    [editAlertController addAction:changeAvatarAlertAction];
    
    NSString *myUserBase64Handle = [MEGASdk base64HandleForUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
    NSString *myAvatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:myUserBase64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:myAvatarFilePath]) {
        UIAlertAction *removeAvatarAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"removeAvatar", @"Button to remove avatar. Try to keep the text short (as in English)") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGASdk] setAvatarUserWithSourceFilePath:nil];
        }];
        [removeAvatarAlertAction mnz_setTitleTextColor:[UIColor mnz_redD90007]];
        [editAlertController addAction:removeAvatarAlertAction];
    }
    
    editAlertController.modalPresentationStyle = UIModalPresentationPopover;
    editAlertController.popoverPresentationController.barButtonItem = self.editBarButtonItem;
    editAlertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:editAlertController animated:YES completion:nil];
}

- (IBAction)logoutTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSError *error;
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] error:&error];
        if (error) {
            MEGALogError(@"Contents of directory at path failed with error: %@", error);
        }
        
        BOOL isInboxDirectory = NO;
        for (NSString *directoryElement in directoryContent) {
            if ([directoryElement isEqualToString:@"Inbox"]) {
                NSString *inboxPath = [[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"];
                [[NSFileManager defaultManager] fileExistsAtPath:inboxPath isDirectory:&isInboxDirectory];
                break;
            }
        }
        
        if (directoryContent.count > 0) {
            if (directoryContent.count == 1 && isInboxDirectory) {
                [[MEGASdkManager sharedMEGASdk] logout];
                return;
            }
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"warning", nil) message:AMLocalizedString(@"allFilesSavedForOfflineWillBeDeletedFromYourDevice", @"Alert message shown when the user perform logout and has files in the Offline directory") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGASdk] logout];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [[MEGASdkManager sharedMEGASdk] logout];
        }
    }
}

- (IBAction)usageTouchUpInside:(UIButton *)sender {
    
    if (isAccountDetailsAvailable) {
        NSArray *sizesArray = @[cloudDriveSize, rubbishBinSize, incomingSharesSize, usedStorage, maxStorage];
        
        UsageViewController *usageVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UsageViewControllerID"];
        [self.navigationController pushViewController:usageVC animated:YES];
        
        [usageVC setSizesArray:sizesArray];
    }
}

- (IBAction)settingsTouchUpInside:(UIButton *)sender {
    [Helper changeToViewController:[SettingsTableViewController class] onTabBarController:self.tabBarController];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if (request.type == MEGARequestTypeSetAttrFile) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrUser: {
            if (request.file) {
                [self setUserAvatar];
            }
            break;
        }
            
        case MEGARequestTypeSetAttrUser: {
            if (request.paramType == MEGAUserAttributeFirstname || request.paramType == MEGAUserAttributeLastname) {
                self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
            } else if (request.paramType  == MEGAUserAttributeAvatar) {
                NSString *myUserBase64Handle = [MEGASdk base64HandleForUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
                NSString *myAvatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:myUserBase64Handle];
                if (request.file == nil) {
                    NSError *removeError = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:myAvatarFilePath error:&removeError];
                    if (removeError) MEGALogError(@"Remove item at path failed with error: %@", removeError);
                }
                
                [self setUserAvatar];
            }
            break;
        }
            
        case MEGARequestTypeAccountDetails: {
            self.megaAccountType = [[request megaAccountDetails] type];
            
            cloudDriveSize = [[request megaAccountDetails] storageUsedForHandle:[[[MEGASdkManager sharedMEGASdk] rootNode] handle]];
            rubbishBinSize = [[request megaAccountDetails] storageUsedForHandle:[[[MEGASdkManager sharedMEGASdk] rubbishNode] handle]];
            
            MEGANodeList *incomingShares = [[MEGASdkManager sharedMEGASdk] inShares];
            NSUInteger count = [incomingShares.size unsignedIntegerValue];
            long long incomingSharesSizeLongLong = 0;
            for (NSUInteger i = 0; i < count; i++) {
                MEGANode *node = [incomingShares nodeAtIndex:i];
                incomingSharesSizeLongLong += [[[MEGASdkManager sharedMEGASdk] sizeForNode:node] longLongValue];
            }
            incomingSharesSize = [NSNumber numberWithLongLong:incomingSharesSizeLongLong];
            
            usedStorage = [request.megaAccountDetails storageUsed];
            maxStorage = [request.megaAccountDetails storageMax];
            
            NSString *usedStorageString = [byteCountFormatter stringFromByteCount:[usedStorage longLongValue]];
            long long availableStorage = maxStorage.longLongValue - usedStorage.longLongValue;
            NSString *availableStorageString = [byteCountFormatter stringFromByteCount:(availableStorage < 0) ? 0 : availableStorage];
            
            [_usedSpaceLabel setAttributedText:[self textForSizeLabels:usedStorageString]];
            [_availableSpaceLabel setAttributedText:[self textForSizeLabels:availableStorageString]];
            
            NSString *expiresString;
            if ([request.megaAccountDetails type]) {
                [_freeView setHidden:YES];
                [_proView setHidden:NO];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy'-'MM'-'dd'"];
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                [formatter setLocale:locale];
                NSDate *expireDate = [[NSDate alloc] initWithTimeIntervalSince1970:[request.megaAccountDetails proExpiration]];
                
                expiresString = [NSString stringWithFormat:AMLocalizedString(@"expiresOn", @"(Expires on %@)"), [formatter stringFromDate:expireDate]];
            } else {
                [_proView setHidden:YES];
                [_freeView setHidden:NO];
            }
            
            switch ([request.megaAccountDetails type]) {
                case MEGAAccountTypeFree: {
                    break;
                }
                    
                case MEGAAccountTypeLite: {
                    [_proStatusLabel setText:[NSString stringWithFormat:@"PRO LITE"]];
                    [_proExpiryDateLabel setText:[NSString stringWithFormat:@"%@", expiresString]];
                    break;
                }
                    
                case MEGAAccountTypeProI: {
                    [_proStatusLabel setText:[NSString stringWithFormat:@"PRO I"]];
                    [_proExpiryDateLabel setText:[NSString stringWithFormat:@"%@", expiresString]];
                    break;
                }
                    
                case MEGAAccountTypeProII: {
                    [_proStatusLabel setText:[NSString stringWithFormat:@"PRO II"]];
                    [_proExpiryDateLabel setText:[NSString stringWithFormat:@"%@", expiresString]];
                    break;
                }
                    
                case MEGAAccountTypeProIII: {
                    [_proStatusLabel setText:[NSString stringWithFormat:@"PRO III"]];
                    [_proExpiryDateLabel setText:[NSString stringWithFormat:@"%@", expiresString]];
                    break;
                }
                    
                default:
                    break;
            }
            
            isAccountDetailsAvailable = YES;
            
            break;
        }
            
        default:
            break;
    }
}

@end
