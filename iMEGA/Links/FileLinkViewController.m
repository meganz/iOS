#import "FileLinkViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "UnavailableLinkView.h"
#import "MEGAReachabilityManager.h"
#import "CustomActionViewController.h"

@interface FileLinkViewController () <MEGARequestDelegate, CustomActionViewControllerDelegate>

@property (strong, nonatomic) MEGANode *node;

@property (strong, nonatomic) UILabel *navigationBarLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (nonatomic, getter=isFolderEmpty) BOOL folderEmpty;

@property (nonatomic) BOOL decryptionAlertControllerHasBeenPresented;

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
    
    self.importBarButtonItem.title = AMLocalizedString(@"import", nil);
    self.downloadBarButtonItem.title = AMLocalizedString(@"downloadButton", @"Download");
    
    self.navigationController.topViewController.toolbarItems = self.toolbar.items;
    [self.navigationController setToolbarHidden:NO animated:YES];
    self.navigationController.toolbar.barTintColor = UIColor.whiteColor;
    self.navigationController.toolbar.backgroundColor = UIColor.whiteColor;

    [self.previewButton setTitle:AMLocalizedString(@"previewContent", @"Title to preview document") forState:UIControlStateNormal];
    
    [self setUIItemsHidden:YES];
    [SVProgressHUD show];
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
    
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
}

- (void)showUnavailableLinkView {
    [SVProgressHUD dismiss];
    
    NSString *fileLinkUnavailableText = [NSString stringWithFormat:@"%@\n%@\n%@\n%@", AMLocalizedString(@"fileLinkUnavailableText1", nil), AMLocalizedString(@"fileLinkUnavailableText2", nil), AMLocalizedString(@"fileLinkUnavailableText3", nil), AMLocalizedString(@"fileLinkUnavailableText4", nil)];
    
    [self showEmptyStateViewWithTitle:AMLocalizedString(@"linkUnavailable", nil) text:fileLinkUnavailableText];
}

- (void)showEmptyStateViewWithTitle:(NSString *)title text:(NSString *)text {
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    unavailableLinkView.frame = self.view.bounds;
    unavailableLinkView.imageView.image = [UIImage imageNamed:@"invalidFileLink"];
    unavailableLinkView.titleLabel.text = title;
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
    NSString *name = self.node.name;
    self.nameLabel.text = name;
    [self setNavigationBarTitleLabel];
    
    self.sizeLabel.text = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
    
    if (self.node.isFolder) {
        [self.thumbnailImageView mnz_imageForNode:self.node];
    } else {
        [self.thumbnailImageView mnz_setThumbnailByNode:self.node];
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

- (IBAction)importAction:(UIBarButtonItem *)sender {
    [self import];
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    [self download];
}

- (IBAction)openAction:(UIBarButtonItem *)sender {
    [self open];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    CustomActionViewController *actionController = [[CustomActionViewController alloc] init];
    actionController.node = self.node;
    actionController.displayMode = DisplayModeFileLink;
    actionController.actionDelegate = self;
    actionController.actionSender = sender;
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popController = [actionController popoverPresentationController];
        popController.delegate = actionController;
        popController.barButtonItem = sender;
    } else {
        actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    [self presentViewController:actionController animated:YES completion:nil];
}

- (void)import {
    [self.node mnz_fileLinkImportFromViewController:self isFolderLink:NO];
}

- (void)download {
    [self.node mnz_fileLinkDownloadFromViewController:self isFolderLink:NO];
}

- (void)open {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.node.name.mnz_isImagePathExtension || self.node.name.mnz_isVideoPathExtension) {
            [self.node mnz_openImageInNavigationController:self.navigationController withNodes:@[self.node] folderLink:YES displayMode:2];
        } else {
            [self.node mnz_openNodeInNavigationController:self.navigationController folderLink:YES];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEArgs: {
                if (request.type == MEGARequestTypeGetPublicNode) {
                    if (self.decryptionAlertControllerHasBeenPresented) {
                        [self showDecryptionKeyNotValidAlert];
                    } else {
                        [self showLinkNotValid];
                    }
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                if (request.type == MEGARequestTypeGetPublicNode) {
                    [self showUnavailableLinkView];
                }
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                if (request.type == MEGARequestTypeGetPublicNode) {
                    [self showDecryptionAlert];
                }
                break;
            }
                
            default:
                break;
        }
        
        return;
    }
    
    switch (request.type) {
            
        case MEGARequestTypeGetPublicNode: {
            if (request.flag) {
                if (self.decryptionAlertControllerHasBeenPresented) { //Link without key, after entering a bad one
                    [self showDecryptionKeyNotValidAlert];
                } else { //Link with invalid key
                    [self showLinkNotValid];
                }
                return;
            }
            
            self.node = request.publicNode;
            
            [self setNodeInfo];
            
            [SVProgressHUD dismiss];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - CustomActionViewControllerDelegate

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node fromSender:(id)sender{
    switch (action) {
        case MegaNodeActionTypeDownload:
            [self download];
            break;
            
        case MegaNodeActionTypeOpen:
            [self open];
            break;
            
        case MegaNodeActionTypeImport:
            [self import];
            break;
            
        case MegaNodeActionTypeShare: {
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.fileLinkString] applicationActivities:nil];
            activityVC.popoverPresentationController.barButtonItem = sender;
            [self presentViewController:activityVC animated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
