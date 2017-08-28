
#import "MyAccountBaseViewController.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAImagePickerController.h"
#import "MEGANavigationController.h"
#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@interface MyAccountBaseViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation MyAccountBaseViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped:)];
    self.avatarImageView.gestureRecognizers = @[tapGestureRecognizer];
    self.avatarImageView.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.presentedViewController == nil) {
        [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    }
    
    [self setUserAvatar];
    self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.presentedViewController == nil) {
        [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegate:self];
    }
}

#pragma mark - Private

- (void)presentEditProfileAlertController {
    UIAlertController *editProfileAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [editProfileAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *changeNameAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"changeName", @"Button title that allows the user change his name") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MEGANavigationController *changeNameNavigationController = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangeNameNavigationControllerID"];
        [self presentViewController:changeNameNavigationController animated:YES completion:nil];
    }];
    [changeNameAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [editProfileAlertController addAction:changeNameAlertAction];
    
    UIAlertAction *changeAvatarAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"changeAvatar", @"button that allows the user the change his avatar") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentChangeAvatarAlertController];
    }];
    [changeAvatarAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
    [editProfileAlertController addAction:changeAvatarAlertAction];
    
    NSString *myUserBase64Handle = [MEGASdk base64HandleForUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
    NSString *myAvatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:myUserBase64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:myAvatarFilePath]) {
        UIAlertAction *removeAvatarAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"removeAvatar", @"Button to remove avatar. Try to keep the text short (as in English)") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGASdk] setAvatarUserWithSourceFilePath:nil];
        }];
        [removeAvatarAlertAction mnz_setTitleTextColor:[UIColor mnz_redD90007]];
        [editProfileAlertController addAction:removeAvatarAlertAction];
    }
    
    editProfileAlertController.modalPresentationStyle = UIModalPresentationPopover;
    editProfileAlertController.popoverPresentationController.sourceRect = self.avatarImageView.frame;
    editProfileAlertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:editProfileAlertController animated:YES completion:nil];
}

- (void)avatarTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self presentEditProfileAlertController];
    }
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
    changeAvatarAlertController.popoverPresentationController.sourceRect = self.avatarImageView.frame;
    changeAvatarAlertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:changeAvatarAlertController animated:YES completion:nil];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    MEGAImagePickerController *imagePickerController = [[MEGAImagePickerController alloc] initToChangeAvatarWithSourceType:sourceType];
    imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
    imagePickerController.popoverPresentationController.sourceView = self.view;
    imagePickerController.popoverPresentationController.sourceRect = self.avatarImageView.frame;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)setUserAvatar {
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    [self.avatarImageView mnz_setImageForUserHandle:myUser.handle];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch (request.type) {
        case MEGARequestTypeGetAttrUser: {
            if (error.type) {
                return;
            }
            
            if (request.file) {
                [self setUserAvatar];
            }
            
            if (request.paramType == MEGAUserAttributeFirstname || request.paramType == MEGAUserAttributeLastname) {
                self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
            }
            break;
        }
            
        case MEGARequestTypeSetAttrUser: {
            if (error.type) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
                return;
            }
            
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
            
        default:
            break;
    }
}

@end
