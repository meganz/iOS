#import "FileLinkViewController.h"

#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "SVProgressHUD.h"
#import "SAMKeychain.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MyAccountHallViewController.h"
#import "NSString+MNZCategory.h"

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "BrowserViewController.h"
#import "UnavailableLinkView.h"
#import "OfflineTableViewController.h"
#import "NodeTableViewCell.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "MEGAQLPreviewController.h"
#import "MEGAStore.h"
#import "PreviewDocumentViewController.h"

@interface FileLinkViewController () <UITableViewDataSource, UITableViewDelegate, MEGARequestDelegate>

@property (strong, nonatomic) MEGANode *node;

@property (strong, nonatomic) UILabel *navigationBarLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *folderAndFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, getter=isFolderEmpty) BOOL folderEmpty;

@property (nonatomic) BOOL decryptionAlertControllerHasBeenPresented;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_folderAndFilesLabel setText:@""];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    if (self.fileLinkMode == FileLinkModeDefault) {
        [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
        [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
        [self.navigationItem setRightBarButtonItem:_cancelBarButtonItem];
        
        [self setUIItemsHidden:YES];
        [SVProgressHUD show];
        [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
    } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
        _node = self.nodeFromFolderLink;
        
        [self setNodeInfo];
        if (_node.isFolder) {
            self.folderAndFilesLabel.text = [Helper filesAndFoldersInFolderNode:self.node api:[MEGASdkManager sharedMEGASdkFolder]];
            
            if ([[MEGASdkManager sharedMEGASdkFolder] numberChildrenForParent:_node] == 0) {
                [self setFolderEmpty:YES];
                [_tableView setUserInteractionEnabled:NO];
            }
        }
    }
    
    if (@available(iOS 11.0, *)) {
        self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNavigationBarTitleLabel];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setNavigationBarTitleLabel];
    } completion:nil];
}

#pragma mark - Private

- (void)setNavigationBarTitleLabel {
    if ([self.node name] != nil) {
        UILabel *label = [Helper customNavigationBarLabelWithTitle:self.node.name subtitle:((self.fileLinkMode == FileLinkModeDefault) ? AMLocalizedString(@"fileLink", nil) : AMLocalizedString(@"folderLink", nil))];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        self.navigationBarLabel = label;
        [self.navigationItem setTitleView:self.navigationBarLabel];
    } else {
        [self.navigationItem setTitle:AMLocalizedString(@"fileLink", nil)];
    }
}

- (void)setUIItemsHidden:(BOOL)boolValue {
    [_mainView setHidden:boolValue];
    [_tableView setHidden:boolValue];
}

- (void)showUnavailableLinkView {
    [SVProgressHUD dismiss];
    
    NSString *fileLinkUnavailableText = [NSString stringWithFormat:@"%@\n%@\n%@\n%@", AMLocalizedString(@"fileLinkUnavailableText1", nil), AMLocalizedString(@"fileLinkUnavailableText2", nil), AMLocalizedString(@"fileLinkUnavailableText3", nil), AMLocalizedString(@"fileLinkUnavailableText4", nil)];
    
    [self showEmptyStateViewWithTitle:AMLocalizedString(@"linkUnavailable", nil) text:fileLinkUnavailableText];
}

- (void)showEmptyStateViewWithTitle:(NSString *)title text:(NSString *)text {
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView setFrame:self.view.bounds];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:@"invalidFileLink"]];
    [unavailableLinkView.titleLabel setText:title];
    unavailableLinkView.textLabel.text = text;
    
    if ([[UIDevice currentDevice] iPhone4X] && ![text isEqualToString:@""]) {
        [unavailableLinkView.imageViewCenterYLayoutConstraint setConstant:-64];
    }
    
    [self.view addSubview:unavailableLinkView];
}

- (void)showLinkNotValid {
    [SVProgressHUD dismiss];
    
    [self showEmptyStateViewWithTitle:AMLocalizedString(@"linkNotValid", nil) text:@""];
}


- (void)showDecryptionAlert {
    [SVProgressHUD dismiss];
    
    UIAlertController *decryptionAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", @"Alert title shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents") message:AMLocalizedString(@"decryptionKeyAlertMessage", @"Alert message shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents") preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = AMLocalizedString(@"decryptionKey", @"Hint text to suggest that the user has to write the decryption key");
        [textField addTarget:self action:@selector(decryptionAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *decryptAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"decrypt", @"Button title to try to decrypt the link") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            NSString *key = decryptionAlertController.textFields.firstObject.text;
            NSString *linkString = ([[key substringToIndex:1] isEqualToString:@"!"]) ? self.fileLinkString : [self.fileLinkString stringByAppendingString:@"!"];
            linkString = [linkString stringByAppendingString:key];
            
            [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:linkString delegate:self];
        }
    }];
    decryptAlertAction.enabled = NO;
    [decryptionAlertController addAction:decryptAlertAction];
    
    [self presentViewController:decryptionAlertController animated:YES completion:^{
        self.decryptionAlertControllerHasBeenPresented = YES;
    }];
}

- (void)showDecryptionKeyNotValidAlert {
    UIAlertController *decryptionKeyNotValidAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyNotValid", @"Alert title shown when you have written a decryption key not valid") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionKeyNotValidAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"nil") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
         [self showDecryptionAlert];
    }]];
    
    [self presentViewController:decryptionKeyNotValidAlertController animated:YES completion:nil];
}

- (void)setNodeInfo {
    NSString *name = [_node name];
    [_nameLabel setText:name];
    [self setNavigationBarTitleLabel];
    
    NSString *sizeString;
    if (self.fileLinkMode == FileLinkModeDefault) {
        sizeString = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
    } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
        sizeString = [NSByteCountFormatter stringFromByteCount:[[[MEGASdkManager sharedMEGASdkFolder] sizeForNode:self.nodeFromFolderLink] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
    }
    [_sizeLabel setText:sizeString];
    
    if ([_node isFolder]) {
        [_thumbnailImageView setImage:[Helper infoImageForNode:_node]];
    } else {
        NSString *extension = [name pathExtension];
        [_thumbnailImageView setImage:[Helper infoImageForExtension:[extension lowercaseString]]];
        
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(extension), NULL);
        if (UTTypeConformsTo(fileUTI, kUTTypeImage) || [QLPreviewController canPreviewItem:[NSURL URLWithString:(__bridge NSString *)(fileUTI)]] || UTTypeConformsTo(fileUTI, kUTTypeText)) {
            [_tableView reloadData];
        }
        if (fileUTI) {
            CFRelease(fileUTI);
        }
    }
    
    [self setUIItemsHidden:NO];
}

- (void)decryptionAlertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *decryptionAlertController = (UIAlertController *)self.presentedViewController;
    if (decryptionAlertController) {
        UITextField *textField = decryptionAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = decryptionAlertController.actions.lastObject;
        BOOL enableRightButton = NO;
        if (textField.text.length > 0) {
            enableRightButton = YES;
        }
        rightButtonAction.enabled = enableRightButton;
    }
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)import {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:navigationController animated:YES completion:nil];
                
                BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                browserVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
                
                if (self.fileLinkMode == FileLinkModeDefault) {
                    [browserVC setBrowserAction:BrowserActionImport];
                } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
                    [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
                }
            }];
        } else {
            if (self.fileLinkMode == FileLinkModeDefault) {
                [Helper setLinkNode:_node];
                [Helper setSelectedOptionOnLink:1]; //Import file from link
            } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
                [[Helper nodesFromLinkMutableArray] addObject:self.nodeFromFolderLink];
                [Helper setSelectedOptionOnLink:3]; //Import folder or nodes from link
            }
            
            LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    }
}

- (void)download {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.fileLinkMode == FileLinkModeDefault) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:_node isFolderLink:NO]) {
                return;
            }
        } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:self.nodeFromFolderLink isFolderLink:YES]) {
                return;
            }
        }
        
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            [self dismissViewControllerAnimated:YES completion:^{
                if ([[[[[UIApplication sharedApplication] delegate] window] rootViewController] isKindOfClass:[MainTabBarController class]]) {
                    MainTabBarController *mainTBC = (MainTabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
                    mainTBC.selectedIndex = MYACCOUNT;
                    MEGANavigationController *navigationController = [mainTBC.childViewControllers objectAtIndex:MYACCOUNT];
                    MyAccountHallViewController *myAccountHallVC = navigationController.viewControllers.firstObject;
                    [myAccountHallVC openOffline];
                }
                
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
                
                if (self.fileLinkMode == FileLinkModeDefault) {
                    [Helper downloadNode:_node folderPath:[Helper relativePathForOffline] isFolderLink:NO];
                } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
                    [Helper downloadNode:self.nodeFromFolderLink folderPath:[Helper relativePathForOffline] isFolderLink:YES];
                }
            }];
        } else {
            if (self.fileLinkMode == FileLinkModeDefault) {
                [Helper setLinkNode:_node];
                [Helper setSelectedOptionOnLink:2]; //Download file from link
            } else if (self.fileLinkMode == FileLinkModeNodeFromFolderLink) {
                [[Helper nodesFromLinkMutableArray] addObject:self.nodeFromFolderLink];
                [Helper setSelectedOptionOnLink:4]; //Download folder or nodes from link
            }
            
            LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    }
}

- (void)open {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        BOOL isFolderLink = ((self.fileLinkMode == FileLinkModeNodeFromFolderLink) ? YES : NO);
        if (self.node.name.mnz_isImagePathExtension) {
            [self.node mnz_openImageInNavigationController:self.navigationController withNodes:@[self.node] folderLink:isFolderLink displayMode:2];
        } else {
            [self.node mnz_openNodeInNavigationController:self.navigationController folderLink:isFolderLink];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NodeTableViewCell *cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NodeDetailsTableViewCellID" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NodeDetailsTableViewCellID"];
    }
    
    switch (indexPath.row) {
        case 0: {
            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"infoImport"]];
            cell.nameLabel.text = AMLocalizedString(@"import", nil);
            break;
        }
            
        case 1: {
            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"infoDownload"]];
            [cell.nameLabel setText:AMLocalizedString(@"downloadButton", nil)];
            break;
        }
            
        case 2: {
            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"infoOpen"]];
            [cell.nameLabel setText:AMLocalizedString(@"openButton", nil)];
            break;
        }
    }
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    if ([self isFolderEmpty]) {
        [cell.thumbnailImageView setAlpha:0.4];
        [cell.nameLabel setAlpha:0.4];
    }
    
    return cell;
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

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs: {
                if ([request type] == MEGARequestTypeGetPublicNode) {
                    if (self.decryptionAlertControllerHasBeenPresented) {
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
                if (self.decryptionAlertControllerHasBeenPresented) { //Link without key, after entering a bad one
                    [self showDecryptionKeyNotValidAlert];
                } else { //Link with invalid key
                    [self showLinkNotValid];
                }
                return;
            }
            
            self.node = [request publicNode];
            
            [self setNodeInfo];
            
            [SVProgressHUD dismiss];
            break;
        }
      
        default:
            break;
    }
}

@end
