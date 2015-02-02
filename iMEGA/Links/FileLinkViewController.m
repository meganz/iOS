/**
 * @file FileLinkViewController.m
 * @brief View controller that allows to see and manage MEGA file links.
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

#import "SVProgressHUD.h"
#import "SSKeychain.h"

#import "MEGASdkManager.h"
#import "Helper.h"

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "FileLinkViewController.h"
#import "MoveCopyNodeViewController.h"

@interface FileLinkViewController () <MEGADelegate, MEGARequestDelegate, MEGATransferDelegate>

@property (strong, nonatomic) MEGANode *node;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setLeftBarButtonItem:self.cancelBarButtonItem];
    
    self.importButton.layer.cornerRadius = 6;
    self.importButton.layer.masksToBounds = YES;
    [self.importButton setTitle:NSLocalizedString(@"importButton", nil) forState:UIControlStateNormal];
    
    self.downloadButton.layer.cornerRadius = 6;
    self.downloadButton.layer.masksToBounds = YES;
    [self.downloadButton setTitle:NSLocalizedString(@"downloadButton", nil) forState:UIControlStateNormal];
    
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
    } else {
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
    }
}

- (IBAction)importTouchUpInside:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
        
        if ([self.node type] == MEGANodeTypeFile) {
            UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
            UINavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"moveNodeNav"];
            [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:navigationController animated:YES completion:nil];
            
            MoveCopyNodeViewController *moveCopyNodeVC = navigationController.viewControllers.firstObject;
            moveCopyNodeVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            moveCopyNodeVC.moveOrCopyNodes = [NSArray arrayWithObject:self.node];
            
            [moveCopyNodeVC setIsPublicNode:YES];
        }
    } else {
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [loginVC setLoginOption:[(UIButton *)sender tag]];
        [loginVC setNode:self.node];
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

- (IBAction)downloadTouchUpInside:(UIButton *)sender {
    
    NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
    if ([freeSizeNumber longLongValue] < [[self.node size] longLongValue]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"fileTooBig", @"You need more free space")
                                                            message:NSLocalizedString(@"fileTooBigMessage", @"The file you are trying to download is bigger than the avaliable memory.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
        [mainTBC setSelectedIndex:1]; //0 = Cloud, 1 = Offline, 2 = Contacts, 3 = Settings
        
        if ([self.node type] == MEGANodeTypeFile) {
            NSString *filePath = [Helper pathForOffline];
            NSString *fileName = [[MEGASdkManager sharedMEGASdk] nameToLocal:[self.node name]];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[filePath stringByAppendingString:fileName]];
            if (!fileExists) {
                [[MEGASdkManager sharedMEGASdk] startDownloadNode:self.node localPath:filePath delegate:self];
            } else {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"fileAlreadyExist", @"The file you want to download already exists on Offline")];
            }
        }
        
    } else {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [loginVC setLoginOption:[(UIButton *)sender tag]];
        [loginVC setNode:self.node];
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    switch ([error type]) {
        case MEGAErrorTypeApiEArgs: {
            
            if ([request type] == MEGARequestTypeGetPublicNode) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"Error")
                                                                    message:NSLocalizedString(@"invalidLink", @"Link invalid")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                          otherButtonTitles:nil];
                [alertView show];
                
                if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
                    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                    
                    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
                } else {
                    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
                    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
                }
            }
            break;
        }
            
        case MEGAErrorTypeApiOk: {
            
            if ([request type] == MEGARequestTypeGetPublicNode) {
                self.node = [request publicNode];
                NSString *name = [self.node name];
                
                [self.nameLabel setText:name];
                
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
                [self.sizeLabel setText:sizeString];
                
                NSString *fileTypeIconString = [Helper fileTypeIconForExtension:[name.pathExtension lowercaseString]];
                UIImage *image = [UIImage imageNamed:fileTypeIconString];
                [self.thumbnailImageView setImage:image];
            }
            
//            if ([request type] == MEGARequestTypeImportLink) {
//                
//            }
            
            break;
        }
            
        default:
            return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetPublicNode: {
            break;
        }
      
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"downloadStarted", @"Download started")];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
