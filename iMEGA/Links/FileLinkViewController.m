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
#import "NodeTableViewCell.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "MEGAStore.h"
#import "PreviewDocumentViewController.h"

@interface FileLinkViewController () <UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, MEGADelegate, MEGARequestDelegate, MEGATransferDelegate> {
    NSString *previewDocumentPath;
    
    UIAlertView *decryptionAlertView;
}

@property (strong, nonatomic) MEGANode *node;

@property (strong, nonatomic) UILabel *navigationBarLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *folderAndFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    NSMutableDictionary *titleTextAttributesDictionary = [[NSMutableDictionary alloc] init];
    [titleTextAttributesDictionary setValue:[UIFont fontWithName:kFont size:17.0] forKey:NSFontAttributeName];
    [_cancelBarButtonItem setTitleTextAttributes:titleTextAttributesDictionary forState:UIControlStateNormal];
    
    [_folderAndFilesLabel setText:@""];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self setUIItemsHidden:YES];
    [SVProgressHUD show];
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.node name] == nil) {
        [self.navigationItem setTitle:AMLocalizedString(@"fileLink", nil)];
    } else {
        [self setNavigationBarTitleLabel];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)setNavigationBarTitleLabel {
    if (_navigationBarLabel == nil) {
        NSString *title = [self.node name];
        NSMutableAttributedString *titleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:title];
        [titleMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont fontWithName:kFont size:18.0]
                                             range:[title rangeOfString:title]];
        
        NSString *subtitle = [NSString stringWithFormat:@"\n(%@)", AMLocalizedString(@"fileLink", nil)];
        NSMutableAttributedString *subtitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:subtitle];
        [subtitleMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                                value:megaRed
                                                range:[subtitle rangeOfString:subtitle]];
        [subtitleMutableAttributedString addAttribute:NSFontAttributeName
                                                value:[UIFont fontWithName:kFont size:12.0]
                                                range:[subtitle rangeOfString:subtitle]];
        
        [titleMutableAttributedString appendAttributedString:subtitleMutableAttributedString];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44)];
        [label setNumberOfLines:2];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setAttributedText:titleMutableAttributedString];
        _navigationBarLabel = label;
        [self.navigationItem setTitleView:label];
    } else {
        [self.navigationItem setTitleView:_navigationBarLabel];
    }
}

- (void)setUIItemsHidden:(BOOL)boolValue {
    [_mainView setHidden:boolValue];
    [_tableView setHidden:boolValue];
}

- (void)showUnavailableLinkView {
    [SVProgressHUD dismiss];
    
    [self showEmptyStateViewWithTitle:AMLocalizedString(@"linkUnavailable", nil) text:AMLocalizedString(@"fileLinkUnavailableText", nil)];
}

- (void)showEmptyStateViewWithTitle:(NSString *)title text:(NSString *)text {
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView setFrame:self.view.bounds];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:@"invalidFileLink"]];
    [unavailableLinkView.titleLabel setText:title];
    [unavailableLinkView.textView setText:text];
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

- (void)showLinkNotValid {
    [SVProgressHUD dismiss];
    
    [self showEmptyStateViewWithTitle:AMLocalizedString(@"linkNotValid", nil) text:@""];
}


- (void)showDecryptionAlert {
    [SVProgressHUD dismiss];
    
    decryptionAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", nil)
                                                     message:AMLocalizedString(@"decryptionKeyAlertMessage", nil)
                                                    delegate:self
                                           cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                           otherButtonTitles:AMLocalizedString(@"decrypt", nil), nil];
    [decryptionAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *textField = [decryptionAlertView textFieldAtIndex:0];
    [textField setPlaceholder:AMLocalizedString(@"decryptionKey", nil)];
    [decryptionAlertView setTag:1];
    [decryptionAlertView show];
}

- (void)showDecryptionKeyNotValidAlert {
    UIAlertView *decryptionKeyNotValidAlertView  = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"decryptionKeyNotValid", nil)
                                                                              message:nil
                                                                             delegate:self
                                                                    cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                                    otherButtonTitles:nil];
    [decryptionKeyNotValidAlertView setTag:2];
    [decryptionKeyNotValidAlertView show];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    
    [self deleteTempFile];
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)import {
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
            [Helper setSelectedOptionOnLink:1];
            
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (void)download {
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
            [Helper setSelectedOptionOnLink:2];
            
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (void)open {
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == 0) {
            [[decryptionAlertView textFieldAtIndex:0] resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else if (buttonIndex == 1) {
            NSString *linkString = [self.fileLinkString stringByAppendingString:@"!"];
            NSString *key = [[alertView textFieldAtIndex:0] text];
            linkString = [linkString stringByAppendingString:key];
            
            [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:linkString delegate:self];
        }
    } else if (alertView.tag == 2) { //Decryption key not valid
        [self showDecryptionAlert];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 1) {
        NSString *decryptionKey = [[alertView textFieldAtIndex:0] text];
        if ([decryptionKey isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 2;
    
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([_node.name pathExtension]), NULL);
    if (UTTypeConformsTo(fileUTI, kUTTypeImage) || [QLPreviewController canPreviewItem:[NSURL URLWithString:(__bridge NSString *)(fileUTI)]] || UTTypeConformsTo(fileUTI, kUTTypeText)) {
        numberOfRows = 3;
    }
    if (fileUTI) {
        CFRelease(fileUTI);
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NodeTableViewCell *cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NodeDetailsTableViewCellID" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NodeDetailsTableViewCellID"];
    }
    
    switch (indexPath.row) {
        case 0: {
            cell.nameLabel.text = AMLocalizedString(@"importButton", nil);
            break;
        }
            
        case 1: {
            [cell.nameLabel setText:AMLocalizedString(@"downloadButton_fileLink", nil)];
            break;
        }
            
        case 2: {
            [cell.nameLabel setText:AMLocalizedString(@"openButton", nil)];
            break;
        }
    }
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case  0:
            [self import];
            break;
            
        case 1:
            [self download];
            break;
            
        case 2:
            [self open];
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs: {
                if ([request type] == MEGARequestTypeGetPublicNode) {
                    if (decryptionAlertView.visible) {
                        [self showDecryptionKeyNotValidAlert];
                    } else {
                        [self showLinkNotValid];
                    }
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                if ([request type] == MEGARequestTypeGetPublicNode) {
                    [self showUnavailableLinkView];
                }
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                if ([request type] == MEGARequestTypeGetPublicNode) {
                    [self showDecryptionAlert];
                }
                break;
            }
                
            default:
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetPublicNode: {
            
            if ([request flag]) {
                if (decryptionAlertView.visible) { //Link without key, after entering a bad one
                    [self showDecryptionKeyNotValidAlert];
                } else { //Link with invalid key
                    [self showLinkNotValid];
                }
                return;
            }
            
            if (decryptionAlertView.visible) {
                [[decryptionAlertView textFieldAtIndex:0] resignFirstResponder];
            }
            
            self.node = [request publicNode];
            
            NSString *name = [self.node name];
            [self.nameLabel setText:name];
            [self setNavigationBarTitleLabel];
            
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
            [self.sizeLabel setText:sizeString];
            
            NSString *extension = [name pathExtension];
            [self.thumbnailImageView setImage:[Helper infoImageForExtension:[extension lowercaseString]]];
            
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(extension), NULL);
            if (UTTypeConformsTo(fileUTI, kUTTypeImage) || [QLPreviewController canPreviewItem:[NSURL URLWithString:(__bridge NSString *)(fileUTI)]] || UTTypeConformsTo(fileUTI, kUTTypeText)) {
                [self.tableView reloadData];
            }
            if (fileUTI) {
                CFRelease(fileUTI);
            }
            
            [self setUIItemsHidden:NO];
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
