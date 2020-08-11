#import "FileLinkViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGALinkManager.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "SendToViewController.h"
#import "UnavailableLinkView.h"

@interface FileLinkViewController () <NodeActionViewControllerDelegate>

@property (strong, nonatomic) MEGANode *node;

@property (strong, nonatomic) UILabel *navigationBarLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendToBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;
@property (weak, nonatomic) IBOutlet UIButton *importButton;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (nonatomic, getter=isFolderEmpty) BOOL folderEmpty;

@property (nonatomic) BOOL decryptionAlertControllerHasBeenPresented;

@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.cancelBarButtonItem.title = AMLocalizedString(@"close", @"A button label.");
    self.moreBarButtonItem.image = [UIImage imageNamed:@"moreSelected"];
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.moreBarButtonItem;
    
    self.navigationController.topViewController.toolbarItems = self.toolbar.items;
    [self.navigationController setToolbarHidden:NO animated:YES];

    [self.openButton setTitle:AMLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
    [self.importButton setTitle:AMLocalizedString(@"Import to Cloud Drive", @"Button title that triggers the importing link action") forState:UIControlStateNormal];
    
    [self setUIItemsHidden:YES];
    
    [self processRequestResult];
    
    if (@available(iOS 11.0, *)) {
        self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    self.moreBarButtonItem.accessibilityLabel = AMLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    [self updateAppearance];
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
            [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    
    self.mainView.backgroundColor = [UIColor mnz_secondaryBackgroundElevated:self.traitCollection];
    
    self.sizeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    [self.importButton mnz_setupPrimary:self.traitCollection];
    [self.openButton mnz_setupBasic:self.traitCollection];
}

- (void)processRequestResult {
    [SVProgressHUD dismiss];
    
    if (self.error.type) {
        switch (self.error.type) {
            case MEGAErrorTypeApiEArgs: {
                if (self.decryptionAlertControllerHasBeenPresented) {
                    [self showDecryptionKeyNotValidAlert];
                } else {
                    [self showUnavailableLinkView];
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                [self showUnavailableLinkView];
                break;
            }
                
            case MEGAErrorTypeApiETooMany:
                [self showUnavailableLinkView];
                break;
                
            case MEGAErrorTypeApiEIncomplete: {
                [self showDecryptionAlert];
                break;
            }
                
            default:
                break;
        }
        
        return;
    }
    
    if (self.request.flag) {
        if (self.decryptionAlertControllerHasBeenPresented) { //Link without key, after entering a bad one
            [self showDecryptionKeyNotValidAlert];
        } else { //Link with invalid key
            [self showUnavailableLinkView];
        }
        return;
    }
    
    self.node = self.request.publicNode;
    
    if (self.node.name.mnz_isImagePathExtension || self.node.name.mnz_isVideoPathExtension) {
        [self dismissViewControllerAnimated:YES completion:^{
            MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[self.node].mutableCopy api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeFileLink presentingNode:self.node preferredIndex:0];
            photoBrowserVC.publicLink = self.publicLinkString;
            
            [UIApplication.mnz_presentingViewController presentViewController:photoBrowserVC animated:YES completion:nil];
        }];
    } else {
        if (self.node.size.longLongValue < MEGAMaxFileLinkAutoOpenSize) {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
                [UIApplication.mnz_presentingViewController presentViewController:[self.node mnz_viewControllerForNodeInFolderLink:YES fileLink:link] animated:YES completion:nil];
            }];
        } else {
            [self setNodeInfo];
        }
    }
}

- (void)setNavigationBarTitleLabel {
    if (self.node.name != nil) {
        UILabel *label = [Helper customNavigationBarLabelWithTitle:self.node.name subtitle:AMLocalizedString(@"fileLink", nil)];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        self.navigationBarLabel = label;
        self.navigationItem.titleView = self.navigationBarLabel;
    } else {
        self.navigationItem.title = AMLocalizedString(@"fileLink", nil);
    }
}

- (void)setUIItemsHidden:(BOOL)boolValue {
    self.mainView.hidden = boolValue;
    self.openButton.hidden = boolValue;
}

- (void)showUnavailableLinkView {
    self.moreBarButtonItem.enabled = self.shareBarButtonItem.enabled = self.sendToBarButtonItem.enabled = NO;
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView configureInvalidFileLink];
    unavailableLinkView.frame = self.view.bounds;
    [self.view addSubview:unavailableLinkView];
}

- (void)showDecryptionAlert {
    UIAlertController *decryptionAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", @"Alert title shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents") message:AMLocalizedString(@"decryptionKeyAlertMessage", @"Alert message shown when you tap on a encrypted file/folder link that can't be opened because it doesn't include the key to see its contents") preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = AMLocalizedString(@"decryptionKey", @"Hint text to suggest that the user has to write the decryption key");
        [textField addTarget:self action:@selector(decryptionAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
    }];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *decryptAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"decrypt", @"Button title to try to decrypt the link") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            NSString *linkString = [MEGALinkManager buildPublicLink:self.publicLinkString withKey:decryptionAlertController.textFields.firstObject.text isFolder:NO];
            
            MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
                self.request = request;
                self.error = error;
                [self processRequestResult];
            }];
            delegate.savePublicHandle = YES;
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:linkString delegate:delegate];
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
    NSString *name = self.node.name;
    self.nameLabel.text = name;
    [self setNavigationBarTitleLabel];
    
    self.sizeLabel.text = [Helper memoryStyleStringFromByteCount:self.node.size.longLongValue];
    
    [self.thumbnailImageView mnz_setThumbnailByNode:self.node];
    
    [self setUIItemsHidden:NO];
}

- (void)decryptionAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *decryptionAlertController = (UIAlertController *)self.presentedViewController;
    if (decryptionAlertController) {
        UIAlertAction *rightButtonAction = decryptionAlertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

- (void)import {
    [self.node mnz_fileLinkImportFromViewController:self isFolderLink:NO];
}

- (void)open {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
        [self.node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:link];
    }
}

- (void)shareFileLink {
    NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
    activityVC.popoverPresentationController.barButtonItem = self.shareBarButtonItem;
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)saveToPhotos {
    [self.node mnz_saveToPhotosWithApi:[MEGASdkManager sharedMEGASdk]];
}

- (void)sendFileLinkToChat {
    UIStoryboard *chatStoryboard = [UIStoryboard storyboardWithName:@"Chat" bundle:[NSBundle bundleForClass:SendToViewController.class]];
    SendToViewController *sendToViewController = [chatStoryboard instantiateViewControllerWithIdentifier:@"SendToViewControllerID"];
    sendToViewController.sendMode = SendModeFileAndFolderLink;
    self.sendLinkDelegate = [SendLinkToChatsDelegate.alloc initWithLink:self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString navigationController:self.navigationController];
    sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate;
    [self.navigationController pushViewController:sendToViewController animated:YES];
}

- (void)download {
    [self.node mnz_fileLinkDownloadFromViewController:self isFolderLink:NO];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [MEGALinkManager resetUtilsForLinksWithoutSession];
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)importAction:(UIButton *)sender {
    [self import];
}

- (IBAction)openAction:(UIButton *)sender {
    [self open];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    [self shareFileLink];
}

- (IBAction)sendToContactAction:(UIBarButtonItem *)sender {
    [self sendFileLinkToChat];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    if (self.node.name) {
        NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:self.node delegate:self displayMode:DisplayModeFileLink isIncoming:NO sender:sender];
        [self presentViewController:nodeActions animated:YES completion:nil];
    }
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeDownload:
            [self download];
            break;
            
        case MegaNodeActionTypeImport:
            [self import];
            break;
            
        case MegaNodeActionTypeSendToChat:
            [self sendFileLinkToChat];
            break;
            
        case MegaNodeActionTypeShare:
            [self shareFileLink];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [self saveToPhotos];
            break;
            
        default:
            break;
    }
}

@end
