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
#import <MobileCoreServices/MobileCoreServices.h>

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
#import "MEGAStore.h"
#import "PreviewDocumentViewController.h"

@interface FileLinkViewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, MEGADelegate, MEGARequestDelegate, MEGATransferDelegate> {
    NSString *previewDocumentPath;
}

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
    [self.downloadButton setTitle:AMLocalizedString(@"downloadButton_fileLink", nil) forState:UIControlStateNormal];

    
    self.openButton.layer.cornerRadius = 6;
    self.openButton.layer.masksToBounds = YES;
    [self.openButton setTitle:AMLocalizedString(@"openButton", nil) forState:UIControlStateNormal];
    
    [SVProgressHUD show];
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"megaLink", nil)];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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
    
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([_node.name pathExtension]), NULL);
    if (UTTypeConformsTo(fileUTI, kUTTypeImage) || [QLPreviewController canPreviewItem:[NSURL URLWithString:(__bridge NSString *)(fileUTI)]] || UTTypeConformsTo(fileUTI, kUTTypeText)) {
        [self.openButton setEnabled:boolValue];
    }
    if (fileUTI) {
        CFRelease(fileUTI);
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
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:previewDocumentPath];
    if (fileExists) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:previewDocumentPath error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove temp document error: %@", error]];
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
        
        if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                if ([self.node type] == MEGANodeTypeFile) {
                    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:navigationController animated:YES completion:nil];
                    
                    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                    browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
                    browserVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
                    [browserVC setBrowserAction:BrowserActionImport];
                }
            }];
        } else {
            LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
            
            [Helper setLinkNode:self.node];
            [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
            
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)downloadTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        [self deleteTempFile];
        
        if (![Helper isFreeSpaceEnoughToDownloadNode:self.node isFolderLink:NO]) {
            [self setEditing:NO animated:YES];
            return;
        }
        
        if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                [Helper changeToViewController:[OfflineTableViewController class] onTabBarController:mainTBC];
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
                [Helper downloadNode:self.node folderPath:[Helper pathForOffline] isFolderLink:NO];
            }];
        } else {
            LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
            
            [Helper setLinkNode:self.node];
            [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
            
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)openTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:_node]];
        
        if (offlineNodeExist) {
            previewDocumentPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
            
            QLPreviewController *previewController = [[QLPreviewController alloc] init];
            [previewController setDelegate:self];
            [previewController setDataSource:self];
            [previewController setTransitioningDelegate:self];
            [previewController setTitle:[self.node name]];
            [self presentViewController:previewController animated:YES completion:nil];
        } else {
            if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] > 0) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"documentOpening_alertTitle", nil)
                                                                    message:AMLocalizedString(@"documentOpening_alertMessage", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            } else {
                // There isn't enough space in the device for preview the document
                if (![Helper isFreeSpaceEnoughToDownloadNode:self.node isFolderLink:NO]) {
                    return;
                }
                
                PreviewDocumentViewController *previewDocumentVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentID"];
                [previewDocumentVC setNode:self.node];
                [previewDocumentVC setApi:[MEGASdkManager sharedMEGASdk]];
                
                [self.navigationController pushViewController:previewDocumentVC animated:YES];
            }
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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
    return [NSURL fileURLWithPath:previewDocumentPath];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
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
            
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(extension), NULL);
            if (UTTypeConformsTo(fileUTI, kUTTypeImage) || [QLPreviewController canPreviewItem:[NSURL URLWithString:(__bridge NSString *)(fileUTI)]] || UTTypeConformsTo(fileUTI, kUTTypeText)) {
                [self.openButton setEnabled:YES];
                [self.openButton setHidden:NO];
            }
            if (fileUTI) {
                CFRelease(fileUTI);
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
    if ([transfer isStreamingTransfer] || ([transfer type] == MEGATransferTypeUpload)) {
        return;
    }
    
    if (([transfer type] == MEGATransferTypeDownload) && ([transfer.path isEqualToString:previewDocumentPath])) {
        [SVProgressHUD show];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([transfer isStreamingTransfer] || ([transfer type] == MEGATransferTypeUpload)) {
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload && ([transfer.path isEqualToString:previewDocumentPath])) {
        [self openTempFile];
        [SVProgressHUD dismiss];
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
