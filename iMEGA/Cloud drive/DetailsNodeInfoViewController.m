#import "DetailsNodeInfoViewController.h"

#import "NSString+MNZCategory.h"
#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"

#import "GetLinkActivity.h"
#import "Helper.h"
#import "MEGAActivityItemProvider.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"
#import "UIImageView+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAShareRequestDelegate.h"
#import "NodeTableViewCell.h"
#import "OpenInActivity.h"
#import "RemoveLinkActivity.h"
#import "ShareFolderActivity.h"

@interface DetailsNodeInfoViewController () <UIDocumentInteractionControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MEGADelegate> {
    NSInteger actions;
    MEGAShareType accessType;
    
    UILabel *navigationBarLabel;
}

@property (nonatomic) BOOL isOwnChange;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *linkedImageView;
@property (weak, nonatomic) IBOutlet UILabel *foldersFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@end

@implementation DetailsNodeInfoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node];
    
    if ((self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeSharedItem) && (accessType == MEGAShareTypeAccessOwner)) {
        [self.navigationItem setRightBarButtonItem:_shareBarButtonItem];
    }
    
    switch (accessType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite:
            if (self.displayMode == DisplayModeSharedItem) {
                actions = 3; //Download, copy and leave
            } else {
                actions = 2; //Download and copy
            }
            break;
            
        case MEGAShareTypeAccessFull:
                actions = 4; //Download, copy, rename and leave (contacts) or delete (cloud drive)
            break;
            
        case MEGAShareTypeAccessOwner: //Cloud Drive / Rubbish Bin / Outgoing Shared Item
            if ((self.displayMode == DisplayModeSharedItem) && [self.node isOutShare]) {
                actions = 3; //Copy, rename and remove sharing
            } else {
                actions = 7; //Download, move, copy, rename, remove link, remove sharing and move to rubbish bin or remove
            }
            break;
            
        default:
            break;
    }
    
    if ((self.displayMode == DisplayModeSharedItem) && (accessType != MEGAShareTypeAccessOwner)) {
        [self setNavigationBarTitleLabel];
    }
    
    if (@available(iOS 11.0, *)) {
        self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadUI];
    
    if (!self.presentedViewController) {
        [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    }
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (!self.presentedViewController) {
        [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ((self.displayMode == DisplayModeSharedItem) && (accessType != MEGAShareTypeAccessOwner)) {
            [self setNavigationBarTitleLabel];
        }
    } completion:nil];
}

#pragma mark - Private

- (void)reloadUI {
    if ([self.node type] == MEGANodeTypeFile) {
        if ([self.node hasThumbnail]) {
            NSString *thumbnailFilePath = [Helper pathForNode:self.node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            if (!thumbnailExists) {
                [self.thumbnailImageView setImage:[Helper infoImageForNode:self.node]];
            } else {
                [self.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
            }
        } else {
            [self.thumbnailImageView setImage:[Helper infoImageForNode:self.node]];
        }
        
        [_foldersFilesLabel setHidden:YES];
        
    } else if ([self.node type] == MEGANodeTypeFolder) {
        if (self.displayMode == DisplayModeSharedItem) {
            if ([self.node isInShare]) {
                [self.thumbnailImageView setImage:[UIImage imageNamed:@"info_folder_incoming"]];
            } else if ([self.node isOutShare]) {
                [self.thumbnailImageView setImage:[UIImage imageNamed:@"info_folder_outgoing"]];
            }
        } else {
            [self.thumbnailImageView setImage:[Helper infoImageForNode:self.node]];
        }
        
        self.foldersFilesLabel.text = [Helper filesAndFoldersInFolderNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    [self.nameLabel setText:[self.node name]];
    
    if (self.displayMode == DisplayModeSharedItem && accessType != MEGAShareTypeAccessOwner) {
        [self.navigationItem setTitleView:navigationBarLabel];
    } else {
        [self setTitle:[self.node name]];
        self.linkedImageView.hidden = self.node.isExported ? NO : YES;
    }
    
    self.infoLabel.text = [Helper sizeAndDateForNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    
    [self.tableView reloadData];
}

- (void)download {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:self.node isFolderLink:NO]) {
            return;
        }
        
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
        [Helper downloadNode:self.node folderPath:[Helper relativePathForOffline] isFolderLink:NO];
        
        if ([self.node isFolder]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)browserWithAction:(NSInteger)browserAction {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
        [browserVC setBrowserAction:browserAction];
    }
}

- (void)rename {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *renameAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") message:AMLocalizedString(@"renameNodeMessage", @"Hint text to suggest that the user have to write the new name for the file or folder") preferredStyle:UIAlertControllerStyleAlert];
        
        [renameAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.delegate = self;
            textField.text = self.node.name;
            [textField addTarget:self action:@selector(renameAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [renameAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *renameAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *alertViewTextField = [[renameAlertController textFields] firstObject];
                [[MEGASdkManager sharedMEGASdk] renameNode:self.node newName:alertViewTextField.text];
            }
        }];
        renameAlertAction.enabled = NO;
        [renameAlertController addAction:renameAlertAction];
        
        [self presentViewController:renameAlertController animated:YES completion:nil];
    }
}

- (void)delete {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle;
        NSString *alertMessage;
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                alertTitle = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
                alertMessage = (self.node.type == MEGANodeTypeFolder) ? AMLocalizedString(@"moveFolderToRubbishBinMessage", @"Alert message to confirm if the user wants to move to the Rubbish Bin '1 folder'") : AMLocalizedString(@"moveFileToRubbishBinMessage", @"Alert message to confirm if the user wants to move to the Rubbish Bin '1 file'");
                break;
            }
                
            case DisplayModeRubbishBin: {
                alertTitle = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
                alertMessage = (self.node.type == MEGANodeTypeFolder) ? AMLocalizedString(@"removeFolderToRubbishBinMessage", @"Alert message shown on the Rubbish Bin when you want to remove '1 folder'") : AMLocalizedString(@"removeFileToRubbishBinMessage", @"Alert message shown on the Rubbish Bin when you want to remove '1 file'");
                break;
            }
                
            case DisplayModeSharedItem: {
                alertTitle = AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
                alertMessage = AMLocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
                break;
            }
                
            default:
                break;
        }
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                self.isOwnChange = YES;
                if (self.displayMode == DisplayModeCloudDrive) {
                    [[MEGASdkManager sharedMEGASdk] moveNode:self.node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
                } else { //DisplayModeRubbishBin (Remove), DisplayModeSharedItem (Remove share)
                    [[MEGASdkManager sharedMEGASdk] removeNode:self.node];
                }
            }
        }]];
        
        [self presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)confirmRemoveSharing {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:self.node];
        NSUInteger outSharesCount = [outSharesOfNodeMutableArray count];
        
        NSString *alertMessage;
        if (outSharesCount == 1) {
            alertMessage = AMLocalizedString(@"removeOneShareOneContactMessage", nil);
        } else if (outSharesCount > 1) {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeOneShareMultipleContactsMessage", nil), (NSInteger)outSharesCount];
        }
        
        UIAlertController *confirmRemoveSharingAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [confirmRemoveSharingAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [confirmRemoveSharingAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self removeSharing];
        }]];
        
        [self presentViewController:confirmRemoveSharingAlertController animated:YES completion:nil];
    }
}

- (void)removeSharing {
    NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:self.node];
    MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:outSharesOfNodeMutableArray.count completion:nil];
    for (MEGAShare *share in outSharesOfNodeMutableArray) {
        [[MEGASdkManager sharedMEGASdk] shareNode:self.node withEmail:share.user level:MEGAShareTypeAccessUnkown delegate:shareRequestDelegate];
    }
    
    if (self.displayMode == DisplayModeSharedItem) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)reloadOrShowWarningAfterActionOnNode:(MEGANode *)nodeUpdated {
    nodeUpdated = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[self.node handle]];
    if (nodeUpdated != nil) { //Is nil if you don't have access to it
        if (nodeUpdated.parentHandle == self.node.parentHandle) { //Same place as before
            //Node renamed, update UI with the new info.
            //Also when you get link, share folder or remove link
            self.node = nodeUpdated;
            [self reloadUI];
        } else {
            //Node moved to the Rubbish Bin or moved inside the same shared folder
            NSString *alertTitle;
            if (nodeUpdated.parentHandle == [[[MEGASdkManager sharedMEGASdk] rubbishNode] handle]) {
                alertTitle = (self.node.isFolder) ? AMLocalizedString(@"folderMovedToTheRubbishBin_alertTitle", @"Alert title shown when you are seeing the details of a folder and you moved it to the Rubbish Bin from another location") : AMLocalizedString(@"fileMovedToTheRubbishBin_alertTitle", @"Alert title shown when you are seeing the details of a file and you moved it to the Rubbish Bin from another location");
            } else {
                alertTitle = (self.node.isFolder) ? AMLocalizedString(@"folderMoved_alertTitle", @"Alert title shown when you are seeing the details of a folder and you moved it from another location") : AMLocalizedString(@"fileMoved_alertTitle", @"Alert title shown when you are seeing the details of a file and you moved it from another location");
            }
            
            UIAlertController *warningAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
            [warningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.navigationController popViewControllerAnimated:YES];
            }]];
            
            [self presentViewController:warningAlertController animated:YES completion:nil];
        }
    } else {
        //Node removed from the Rubbish Bin or moved outside of the shared folder
        NSString *alertTitle = (self.node.isFolder) ? AMLocalizedString(@"youNoLongerHaveAccessToThisFolder_alertTitle", @"Alert title shown when you are seeing the details of a folder and you are not able to access it anymore because it has been removed or moved from the shared folder where it used to be") : AMLocalizedString(@"youNoLongerHaveAccessToThisFile_alertTitle", @"Alert title shown when you are seeing the details of a file and you are not able to access it anymore because it has been removed or moved from the shared folder where it used to be");
        UIAlertController *warningAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
        [warningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        
        [self presentViewController:warningAlertController animated:YES completion:nil];
    }
}

- (void)setNavigationBarTitleLabel {
    NSString *accessTypeString;
    switch (accessType) {
        case MEGAShareTypeAccessRead:
            accessTypeString = AMLocalizedString(@"readOnly", nil);
            break;
            
        case MEGAShareTypeAccessReadWrite:
            accessTypeString = AMLocalizedString(@"readAndWrite", nil);
            break;
            
        case MEGAShareTypeAccessFull:
            accessTypeString = AMLocalizedString(@"fullAccess", nil);
            break;
            
        default:
            accessTypeString = @"";
            break;
    }
    
    if ([self.node name] != nil) {
        UILabel *label = [Helper customNavigationBarLabelWithTitle:self.node.name subtitle:accessTypeString];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        navigationBarLabel = label;
        [self.navigationItem setTitleView:navigationBarLabel];
    } else {
        [self.navigationItem setTitle:[NSString stringWithFormat:@"(%@)", accessTypeString]];
    }
}

- (NSMutableArray *)outSharesForNode:(MEGANode *)node {
    NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
    
    MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
    NSUInteger outSharesForNodeCount = [[outSharesForNodeShareList size] unsignedIntegerValue];
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if ([share user] != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    return outSharesForNodeMutableArray;
}

- (void)renameAlertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *renameAlertController = (UIAlertController *)self.presentedViewController;
    if (renameAlertController) {
        UITextField *textField = renameAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = renameAlertController.actions.lastObject;
        BOOL enableRightButton = NO;
        
        NSString *newName = textField.text;
        NSString *nodeNameString = self.node.name;
        
        if (self.node.isFile || self.node.isFolder) {
            if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString] || newName.mnz_isEmpty) {
                enableRightButton = NO;
            } else {
                enableRightButton = YES;
            }
        }
        
        rightButtonAction.enabled = enableRightButton;
    }
}

#pragma mark - IBActions

- (IBAction)shareTouchUpInside:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] button:self.shareBarButtonItem];
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - UIDocumentInteractionController

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger numberOfSections;
    switch (self.displayMode) {
        case DisplayModeCloudDrive:
        case DisplayModeRubbishBin: {
            numberOfSections = self.node.isOutShare ? 2 : 1;
            break;
        }
            
        case DisplayModeSharedItem: {
            numberOfSections = 2;
            break;
        }
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows;
    switch (self.displayMode) {
        case DisplayModeCloudDrive:
            if (section == 0) {
                numberOfRows = self.node.isOutShare ? 1 : actions;
            } else {
                numberOfRows = actions;
            }
            break;
            
        case DisplayModeRubbishBin: {
            numberOfRows = actions;
            break;
        }
            
        case DisplayModeSharedItem: {
            if (section == 0) {
                numberOfRows = 1;
            } else {
                numberOfRows = actions;
            }
            break;
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NodeTableViewCell *cell;
    switch (self.displayMode) {
        case DisplayModeCloudDrive:
        case DisplayModeRubbishBin: {
            if (indexPath.section == 0 && self.node.isOutShare) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:@"SharedItemContactsTableViewCellID" forIndexPath:indexPath];
                if (cell == nil) {
                    cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SharedItemContactsTableViewCellID"];
                }
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:@"NodeDetailsTableViewCellID" forIndexPath:indexPath];
                if (cell == nil) {
                    cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NodeDetailsTableViewCellID"];
                }
            }
            break;
        }
            
        case DisplayModeSharedItem: {
            if (indexPath.section == 0) {
                if (([self.node isInShare] && [self.userName isEqualToString:self.email]) || [self.node isOutShare]) {
                    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SharedItemContactsTableViewCellID" forIndexPath:indexPath];
                    if (cell == nil) {
                        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SharedItemContactsTableViewCellID"];
                    }
                } else {
                    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SharedItemContactTableViewCellID" forIndexPath:indexPath];
                    if (cell == nil) {
                        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SharedItemContactTableViewCellID"];
                    }
                    
                    [cell.infoLabel setText:self.email];
                }
            } else if (indexPath.section == 1) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:@"NodeDetailsTableViewCellID" forIndexPath:indexPath];
                if (cell == nil) {
                    cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NodeDetailsTableViewCellID"];
                }
            }
            break;
        }
    }
    
    if (((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 0)) || ((self.displayMode == DisplayModeCloudDrive) && (indexPath.section == 0) && self.node.isOutShare)) {
        if ([self.node isInShare]) {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.email];
            [cell.thumbnailImageView mnz_setImageForUserHandle:user.handle];
            
            NSString *owner = [NSString stringWithFormat:@" (%@)", AMLocalizedString(@"owner", nil)];
            NSMutableAttributedString *ownerMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:owner];
            [ownerMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                                 value:[UIColor mnz_redD90007]
                                                 range:[owner rangeOfString:owner]];
            
            NSMutableAttributedString *userNameMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.userName];
            [userNameMutableAttributedString appendAttributedString:ownerMutableAttributedString];
            [cell.nameLabel setAttributedText:userNameMutableAttributedString];
            
        } else if ([self.node isOutShare]) {
            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"info_sharedWith"]];
            
            NSMutableArray *outSharesMutableArray = [self outSharesForNode:self.node];
            NSString *sharedWithXContacts;
            NSString *xContacts;
            if ([outSharesMutableArray count] > 1) {
                sharedWithXContacts = [NSString stringWithFormat:AMLocalizedString(@"sharedWithXContacts", @"Text shown to explain with how many contacts you have shared a folder"), [outSharesMutableArray count]];
                xContacts = [AMLocalizedString(@"XContactsSelected", @"[X] will be replaced by a plural number, indicating the total number of contacts the user has") stringByReplacingOccurrencesOfString:@"[X]" withString:[NSString stringWithFormat:@"%lu", (unsigned long)[outSharesMutableArray count]]];
            } else {
                sharedWithXContacts = AMLocalizedString(@"sharedWithOneContact", @"Text shown to explain that you have shared a folder with one contact");
                xContacts = AMLocalizedString(@"oneContact", @"");
            }
            
            NSRange range = [sharedWithXContacts rangeOfString:xContacts];
            if (range.location == NSNotFound && range.length == 0) {
                cell.nameLabel.text = sharedWithXContacts;
            } else {
                NSMutableAttributedString *sharedWithXContactsMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sharedWithXContacts];
                [sharedWithXContactsMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                                                   value:[UIColor mnz_redD90007]
                                                                   range:range];
                cell.nameLabel.attributedText = sharedWithXContactsMutableAttributedString;
            }
            cell.arrowImageView.image = [UIImage imageNamed:@"info_sharedWithArrow"];
        }
        
        [cell.horizontalLineLayoutConstraint setConstant:0.5f];
        
    } else if ((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 1) && (accessType == MEGAShareTypeAccessOwner)) {
        switch (indexPath.row) {
            case 0:
                [cell.thumbnailImageView setImage:[UIImage imageNamed:@"copy"]];
                [cell.nameLabel setText:AMLocalizedString(@"copy", nil)];
                break;
                
            case 1:
                [cell.thumbnailImageView setImage:[UIImage imageNamed:@"rename"]];
                [cell.nameLabel setText:AMLocalizedString(@"rename", nil)];
                break;
                
            case 2:
                [cell.thumbnailImageView setImage:[UIImage imageNamed:@"removeShare"]];
                [cell.nameLabel setText:AMLocalizedString(@"removeSharing", nil)];
                break;
        }
    } else {
        //Is the same for all posibilities
        if (indexPath.row == 0) {
            if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
                [cell.thumbnailImageView setImage:[UIImage imageNamed:@"download"]];
                [cell.nameLabel setText:AMLocalizedString(@"queued", @"Queued")];
                return cell;
            } else {
                MOOfflineNode *offlineNode = [[MEGAStore shareInstance] offlineNodeWithNode:self.node api:[MEGASdkManager sharedMEGASdk]];
                
                if (offlineNode != nil) {
                    [cell.thumbnailImageView setImage:[UIImage imageNamed:@"downloaded"]];
                    [cell.nameLabel setText:AMLocalizedString(@"savedForOffline", @"Saved for offline")];
                } else {
                    [cell.thumbnailImageView setImage:[UIImage imageNamed:@"download"]];
                    [cell.nameLabel setText:AMLocalizedString(@"saveForOffline", @"Save for Offline")];
                }
            }
        }
        
        switch (accessType) {
            case MEGAShareTypeAccessReadWrite:
            case MEGAShareTypeAccessRead:
                switch (indexPath.row) {
                    case 1:
                        [cell.thumbnailImageView setImage:[UIImage imageNamed:@"copy"]];
                        [cell.nameLabel setText:AMLocalizedString(@"copy", @"Copy")];
                        break;
                        
                    case 2:
                        [cell.thumbnailImageView setImage:[UIImage imageNamed:@"leaveShare"]];
                        [cell.nameLabel setText:AMLocalizedString(@"leaveFolder", @"Leave")];
                        break;
                }
                break;
                
            case MEGAShareTypeAccessFull:
                switch (indexPath.row) {
                    case 1:
                        [cell.thumbnailImageView setImage:[UIImage imageNamed:@"copy"]];
                        [cell.nameLabel setText:AMLocalizedString(@"copy", nil)];
                        break;
                        
                    case 2:
                        [cell.thumbnailImageView setImage:[UIImage imageNamed:@"rename"]];
                        [cell.nameLabel setText:AMLocalizedString(@"rename", nil)];
                        break;
                        
                    case 3:
                        if (self.displayMode == DisplayModeCloudDrive) {
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"rubbishBin"]];
                            [cell.nameLabel setText:AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to \"Move to the Rubbish Bin\" files or folders")];
                        } else {
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"leaveShare"]];
                            [cell.nameLabel setText:AMLocalizedString(@"leaveFolder", @"Leave")];
                        }
                        
                        break;
                }
                break;
                
            case MEGAShareTypeAccessOwner:
                if (self.displayMode == DisplayModeCloudDrive) {
                    switch (indexPath.row) {
                        case 1:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"move"]];
                            [cell.nameLabel setText:AMLocalizedString(@"move", nil)];
                            break;
                            
                        case 2:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"copy"]];
                            [cell.nameLabel setText:AMLocalizedString(@"copy", nil)];
                            break;
                            
                        case 3:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"rename"]];
                            [cell.nameLabel setText:AMLocalizedString(@"rename", nil)];
                            break;
                            
                        case 4:
                            cell.thumbnailImageView.image = [UIImage imageNamed:@"removeLink"];
                            cell.nameLabel.text = AMLocalizedString(@"removeLink", @"Message shown when there is an active link that can be removed or disabled");
                            break;
                            
                        case 5:
                            cell.thumbnailImageView.image = [UIImage imageNamed:@"removeShare"];
                            cell.nameLabel.text = AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share");
                            break;
                            
                        case 6:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"rubbishBin"]];
                            [cell.nameLabel setText:AMLocalizedString(@"moveToTheRubbishBin", @"Move to the rubbish bin")];
                            break;
                    }
                    // Rubbish bin
                } else {
                    switch (indexPath.row) {
                        case 1:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"move"]];
                            [cell.nameLabel setText:AMLocalizedString(@"move", nil)];
                            break;
                            
                        case 2:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"copy"]];
                            [cell.nameLabel setText:AMLocalizedString(@"copy", nil)];
                            break;
                            
                        case 3:
                            [cell.thumbnailImageView setImage:[UIImage imageNamed:@"rename"]];
                            [cell.nameLabel setText:AMLocalizedString(@"rename", nil)];
                            break;
                            
                        case 4:
                            if ([self.node isOutShare]) {
                                [cell.thumbnailImageView setImage:[UIImage imageNamed:@"removeShare"]];
                                [cell.nameLabel setText:AMLocalizedString(@"removeSharing", nil)];
                            } else {
                                [cell.thumbnailImageView setImage:[UIImage imageNamed:@"remove"]];
                                [cell.nameLabel setText:AMLocalizedString(@"remove", nil)];
                            }
                            break;
                    }
                }
                
                break;
                
            default:
                break;
        }
    
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 0)) || ((self.displayMode == DisplayModeCloudDrive) && (indexPath.section == 0) && self.node.isOutShare)) {
        return 66.0;
    }
    
    if (((indexPath.row == 4) && !self.node.isExported) || ((indexPath.row == 5) && !self.node.isOutShare)) {
        return 0.0;
    }
    
    return 44.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.displayMode == DisplayModeSharedItem) && (accessType == MEGAShareTypeAccessOwner)) {
        if (indexPath.section == 0) {
            ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            contactsVC.contactsMode = ContactsModeFolderSharedWith;
            [contactsVC setNode:self.node];
            [self.navigationController pushViewController:contactsVC animated:YES];
        } else {
            switch (indexPath.row) {
                case  0:
                    [self browserWithAction:BrowserActionCopy];
                    break;
                    
                case 1:
                    [self rename];
                    break;
                    
                case 2:
                    [self confirmRemoveSharing];
                    break;
            }
        }
    } else {
         if ((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 0) && ([self.node isInShare])) {
             [tableView deselectRowAtIndexPath:indexPath animated:YES];
             return;
         }
        
        if (self.node.isOutShare && (indexPath.section == 0) && (self.displayMode == DisplayModeCloudDrive)) {
            ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            contactsVC.contactsMode = ContactsModeFolderSharedWith;
            contactsVC.node = self.node;
            [self.navigationController pushViewController:contactsVC animated:YES];
        } else {
            switch (indexPath.row) {
                case 0: { //Save for Offline
                    if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
                        UIAlertController *cancelDownloadAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"downloading", @"Title show when a file is being downloaded") message:AMLocalizedString(@"cancelDownloadAlertViewText", @"Message shown when you tap on the cancel button of an active transfer") preferredStyle:UIAlertControllerStyleAlert];
                        
                        [cancelDownloadAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                        
                        [cancelDownloadAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                                NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:self.node.base64Handle];
                                if (transferTag != nil) {
                                    [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
                                }
                            }
                        }]];
                        
                        [self presentViewController:cancelDownloadAlertController animated:YES completion:nil];
                    } else {
                        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:self.node api:[MEGASdkManager sharedMEGASdk]];
                        if (!offlineNodeExist) {
                            [self download];
                        }
                    }
                    break;
                }
                    
                case 1: { //Copy or Move
                    switch (accessType) {
                        case MEGAShareTypeAccessRead:
                        case MEGAShareTypeAccessReadWrite:
                        case MEGAShareTypeAccessFull:
                            [self browserWithAction:BrowserActionCopy];
                            break;
                            
                        case MEGAShareTypeAccessOwner:
                            [self browserWithAction:BrowserActionMove];
                            break;
                            
                        default:
                            break;
                    }
                    break;
                }
                    
                case 2: { //Leave, rename or copy
                    switch (accessType) {
                        case MEGAShareTypeAccessRead:
                        case MEGAShareTypeAccessReadWrite:
                            [self delete];
                            break;
                            
                        case MEGAShareTypeAccessFull:
                            [self rename];
                            break;
                            
                        case MEGAShareTypeAccessOwner:
                            [self browserWithAction:BrowserActionCopy];
                            break;
                            
                        default:
                            break;
                    }
                    break;
                }
                    
                case 3: { //Leave, rename
                    switch (accessType) {
                        case MEGAShareTypeAccessFull:
                            [self delete];
                            break;
                            
                        case MEGAShareTypeAccessOwner:
                            [self rename];
                            break;
                            
                        default:
                            break;
                    }
                    break;
                }
                    
                case 4: { //Remove link
                    MEGAExportRequestDelegate *requestDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                        NSString *status = AMLocalizedString(@"linkRemoved", @"Message shown when the links to a file or folder has been removed");
                        [SVProgressHUD showSuccessWithStatus:status];
                    } multipleLinks:NO];
                    
                    [[MEGASdkManager sharedMEGASdk] disableExportNode:self.node delegate:requestDelegate];
                    break;
                }
                    
                case 5: //Remove sharing
                    [self confirmRemoveSharing];
                    break;
                    
                case 6: //Move to the Rubbish Bin / Remove
                    [self delete];
                    break;
            }
            
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSString *nodeName = [textField text];
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextRange *textRange;
    
    switch ([self.node type]) {
        case MEGANodeTypeFile: {
            if ([[nodeName pathExtension] isEqualToString:@""] && [nodeName isEqualToString:[nodeName stringByDeletingPathExtension]]) { //File without extension
                UITextPosition *end = textField.endOfDocument;
                textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            } else {
                NSRange filenameRange = [nodeName rangeOfString:@"." options:NSBackwardsSearch];
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:filenameRange.location];
                textRange = [textField textRangeFromPosition:beginning  toPosition:beforeExtension];
            }
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        case MEGANodeTypeFolder: {
            UITextPosition *end = textField.endOfDocument;
            textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shouldChangeCharacters = YES;
    switch ([self.node type]) {
        case MEGANodeTypeFile:
        case MEGANodeTypeFolder:
            shouldChangeCharacters = YES;
            break;
            
        default:
            shouldChangeCharacters = NO;
            break;
    }
    
    return shouldChangeCharacters;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrFile: {
            if ([request nodeHandle] == [self.node handle]) {
                MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[request nodeHandle]];
                NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                if (fileExists) {
                    [self.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                }
            }
            break;
        }
            
        case MEGARequestTypeCancelTransfer:
            [self.tableView reloadData];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
            break;
            
        case MEGARequestTypeMove:
        case MEGARequestTypeRemove: {
            [self.navigationController popViewControllerAnimated:YES];
            
            if (self.displayMode == DisplayModeCloudDrive) {
                NSString *message;
                if ([self.node isFile]) {
                    message = AMLocalizedString(@"fileMovedToRubbishBinMessage", @"Success message shown when you have moved 1 file to the Rubbish Bin");
                } else if ([self.node isFolder]) {
                    message = AMLocalizedString(@"folderMovedToRubbishBinMessage", @"Success message shown when you have moved 1 folder to the Rubbish Bin");
                }
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudRubbishBin"] status:message];
            } else if (self.displayMode == DisplayModeRubbishBin) {
                NSString *message;
                if ([self.node isFile]) {
                    message = AMLocalizedString(@"fileRemovedToRubbishBinMessage", @"Success message shown when 1 file has been removed from MEGA");
                } else if ([self.node isFolder]) {
                    message = AMLocalizedString(@"folderRemovedToRubbishBinMessage", @"Success message shown when 1 folder has been removed from MEGA");
                }
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
            } else if (self.displayMode == DisplayModeSharedItem) {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"shareLeft", @"Message shown when a share has been left")];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (self.isOwnChange) return;
    
    MEGANode *nodeUpdated;
    
    NSUInteger size = [[nodeList size] unsignedIntegerValue];
    for (NSUInteger i = 0; i < size; i++) {
        nodeUpdated = [nodeList nodeAtIndex:i];
        
        if ([nodeUpdated handle] == [self.node handle]) {
            [self reloadOrShowWarningAfterActionOnNode:nodeUpdated];
            break;
        }
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:base64Handle];
        if (([transferTag integerValue] == transfer.tag) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            NodeTableViewCell *cell;
            if (self.displayMode == DisplayModeSharedItem) {
                cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            } else {
                cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
            [cell.nameLabel setText:AMLocalizedString(@"queued", @"Queued")];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:base64Handle];
        if (([transferTag integerValue] == transfer.tag) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
            NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
            NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
            
            NodeTableViewCell *cell;
            if (self.displayMode == DisplayModeSharedItem) {
                cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            } else {
                cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
            [cell.nameLabel setText:[NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed]];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type] || ([transfer type] == MEGATransferTypeUpload)) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        MOOfflineNode *offlineNode =  [[MEGAStore shareInstance] offlineNodeWithNode:self.node api:api];
        
        if ((offlineNode != nil) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            if ([self.presentedViewController.title isEqualToString:AMLocalizedString(@"downloading", @"Title show when a file is being downloaded")]) {
                [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
            }
            
            NodeTableViewCell *cell;
            if (self.displayMode == DisplayModeSharedItem) {
                cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            } else {
                cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
            [cell.nameLabel setText:AMLocalizedString(@"savedForOffline", @"Saved for offline")];
            [self.tableView reloadData];
        }
    }
}

@end
