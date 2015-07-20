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

#import <QuickLook/QuickLook.h>

#import "SVProgressHUD.h"
#import "SSKeychain.h"

#import "MEGASdkManager.h"
#import "Helper.h"

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "FileLinkViewController.h"
#import "BrowserViewController.h"
#import "UnavailableLinkView.h"
#import "OfflineTableViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"

@interface FileLinkViewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, MEGADelegate, MEGARequestDelegate, MEGATransferDelegate>

@property (strong, nonatomic) MEGANode *node;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setRightBarButtonItem:self.cancelBarButtonItem];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.navigationItem setTitle:AMLocalizedString(@"megaLink", nil)];
    
    [self setUIItemsEnabled:NO];
    
    self.importButton.layer.cornerRadius = 6;
    self.importButton.layer.masksToBounds = YES;
    [self.importButton setTitle:AMLocalizedString(@"importButton", nil) forState:UIControlStateNormal];
    
    self.downloadButton.layer.cornerRadius = 6;
    self.downloadButton.layer.masksToBounds = YES;
    [self.downloadButton setTitle:AMLocalizedString(@"downloadButton", nil) forState:UIControlStateNormal];
    
    self.openButton.layer.cornerRadius = 6;
    self.openButton.layer.masksToBounds = YES;
    [self.openButton setTitle:AMLocalizedString(@"openButton", nil) forState:UIControlStateNormal];
    
    [SVProgressHUD show];
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)setUIItemsEnabled:(BOOL)boolValue {
    [self.nameLabel setHidden:!boolValue];
    [self.sizeLabel setHidden:!boolValue];
    
    [self.thumbnailImageView setHidden:!boolValue];
    
    [self.importButton setEnabled:boolValue];
    [self.downloadButton setEnabled:boolValue];
    
    NSString *extension = [self.node.name pathExtension];
    if (isDocument(extension) || isImage(extension)) {
        [self.openButton setEnabled:boolValue];
    }
}

- (void)showUnavailableLinkView {
    [self setUIItemsEnabled:NO];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView setFrame:self.view.bounds];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:@"unavailableLink"]];
    [unavailableLinkView.titleLabel setText:AMLocalizedString(@"fileLinkUnavailableTitle", nil)];
    [unavailableLinkView.textView setText:AMLocalizedString(@"fileLinkUnavailableText", nil)];
    [unavailableLinkView.textView setFont:[UIFont fontWithName:kFont size:14.0]];
    [unavailableLinkView.textView setTextColor:megaDarkGray];
    
    [self.view addSubview:unavailableLinkView];
}

- (void)openTempFile {
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    [previewController setDelegate:self];
    [previewController setDataSource:self];
    [previewController setTransitioningDelegate:self];
    [previewController setTitle:[self.node name]];
    [self presentViewController:previewController animated:YES completion:nil];
}

- (void)deleteTempFile {
    if (self.node == nil) {
        return;
    }
    
    NSString *name = [[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[self.node name]];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (fileExists) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[Helper pathForPreviewDocument] error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    
    [self deleteTempFile];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)importTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        [self deleteTempFile];
        
        if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                if ([self.node type] == MEGANodeTypeFile) {
                    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"moveNodeNav"];
                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:navigationController animated:YES completion:nil];
                    
                    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                    browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
                    browserVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
                    
                    [browserVC setIsPublicNode:YES];
                }
            }];
        } else {
            LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
            
            [Helper setLinkNode:self.node];
            [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
            
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (IBAction)downloadTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        [self deleteTempFile];
        
        if (![Helper isFreeSpaceEnoughToDownloadNode:self.node isFolderLink:NO]) {
            [self setEditing:NO animated:YES];
            return;
        }
        
        if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                [Helper changeToViewController:[OfflineTableViewController class] onTabBarController:mainTBC];
                [Helper downloadNode:self.node folderPath:[Helper pathForOffline] isFolderLink:NO];
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"downloadStarted", nil)];
            }];
        } else {
            LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
            
            [Helper setLinkNode:self.node];
            [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
            
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (IBAction)openTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        [self.importButton setEnabled:NO];
        [self.downloadButton setEnabled:NO];
        [self.openButton setEnabled:NO];
        
        NSNumber *nodeSizeNumber = [self.node size];
        NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
        if ([freeSizeNumber longLongValue] < [nodeSizeNumber longLongValue]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                                message:AMLocalizedString(@"fileTooBigMessage_open", @"The file you are trying to open is bigger than the avaliable memory.")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            return;
        }
        
        [Helper setRenamePathForPreviewDocument:[NSTemporaryDirectory() stringByAppendingPathComponent:[self.node name]]];
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[Helper renamePathForPreviewDocument]];
        if (!fileExists) {
            NSString *name = [[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[self.node name]];
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
            [Helper setPathForPreviewDocument:path];
            
            [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:self.node localPath:path];
        } else {
            [self openTempFile];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
   
    if ([presented isKindOfClass:[QLPreviewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    
    return nil;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:[Helper renamePathForPreviewDocument]];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
    [Helper setPathForPreviewDocument:nil];
    [Helper setRenamePathForPreviewDocument:nil];
    
    [self.importButton setEnabled:YES];
    [self.downloadButton setEnabled:YES];
    [self.openButton setEnabled:YES];
}


#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiENoent) {
            if ([request type] == MEGARequestTypeGetPublicNode) {
                [SVProgressHUD dismiss];
                [self showUnavailableLinkView];
            }
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetPublicNode: {
            self.node = [request publicNode];
            
            NSString *name = [self.node name];
            [self.nameLabel setText:name];
            
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
            [self.sizeLabel setText:sizeString];
            
            NSString *extension = [name pathExtension];
            NSString *fileTypeIconString = [Helper fileTypeIconForExtension:[extension lowercaseString]];
            UIImage *image = [UIImage imageNamed:fileTypeIconString];
            [self.thumbnailImageView setImage:image];
            
            if (isDocument(extension) || isImage(extension)) {
                [self.openButton setEnabled:YES];
                [self.openButton setHidden:NO];
            }
            
            [self setUIItemsEnabled:YES];
            [SVProgressHUD dismiss];
            break;
        }
      
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (([transfer type] == MEGATransferTypeDownload)  && (!transfer.isStreamingTransfer) && ([transfer.path isEqualToString:[Helper pathForPreviewDocument]])) {
        [SVProgressHUD show];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([transfer isStreamingTransfer] || ([transfer type] == MEGATransferTypeUpload)) {
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload && ([transfer.path isEqualToString:[Helper pathForPreviewDocument]])) {
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] moveItemAtPath:[Helper pathForPreviewDocument] toPath:[Helper renamePathForPreviewDocument] error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
        }
        
        [self openTempFile];
        
        [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
        [SVProgressHUD dismiss];
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
