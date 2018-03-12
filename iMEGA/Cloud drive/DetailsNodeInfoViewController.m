#import "DetailsNodeInfoViewController.h"

#import "NSString+MNZCategory.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "UIImageView+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAShareRequestDelegate.h"
#import "NodeTableViewCell.h"

@interface DetailsNodeInfoViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MEGADelegate>

@property (nonatomic) MEGAShareType accessType;

@property (nonatomic) BOOL isOwnChange;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *linkedImageView;
@property (weak, nonatomic) IBOutlet UILabel *foldersFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DetailsNodeInfoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node];
    
    if ((self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeSharedItem) && (self.accessType == MEGAShareTypeAccessOwner)) {
        [self.navigationItem setRightBarButtonItem:_shareBarButtonItem];
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
        if ((self.displayMode == DisplayModeSharedItem) && (self.accessType != MEGAShareTypeAccessOwner)) {
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
    
    if ((self.displayMode == DisplayModeSharedItem) && (self.accessType != MEGAShareTypeAccessOwner)) {
        [self setNavigationBarTitleLabel];
    } else {
        [self setTitle:[self.node name]];
        self.linkedImageView.hidden = self.node.isExported ? NO : YES;
    }
    
    self.infoLabel.text = [Helper sizeAndDateForNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    
    [self.tableView reloadData];
}

- (void)downloadOrCancelDownload {
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
}

- (void)download {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:self.node isFolderLink:NO]) {
            return;
        }
        
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
        [Helper downloadNode:self.node folderPath:[Helper relativePathForOffline] isFolderLink:NO shouldOverwrite:NO];
        
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

- (void)moveToTheRubbishBinOrRemoveOrLeave {
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
                void (^completion)(void) = ^{
                    [self.navigationController popViewControllerAnimated:YES];
                };
                if (self.displayMode == DisplayModeCloudDrive) {
                    MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:(self.node.isFile ? 1 : 0) folders:(self.node.isFolder ? 1 : 0) completion:completion];
                    [[MEGASdkManager sharedMEGASdk] moveNode:self.node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:moveRequestDelegate];
                } else { //DisplayModeRubbishBin (Remove), DisplayModeSharedItem (Leave share)
                    MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:self.displayMode files:(self.node.isFile ? 1 : 0) folders:(self.node.isFolder ? 1 : 0) completion:completion];
                    [[MEGASdkManager sharedMEGASdk] removeNode:self.node delegate:removeRequestDelegate];
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
            if (self.displayMode == DisplayModeSharedItem && self.node.isOutShare && !nodeUpdated.isOutShare) {
                self.displayMode = DisplayModeCloudDrive;
            }
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
    switch (self.accessType) {
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
        self.navigationItem.titleView = label;
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

- (NodeTableViewCell *)dequeueCellForIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
    switch (self.displayMode) {
        case DisplayModeCloudDrive:
        case DisplayModeRubbishBin: {
            cellIdentifier = (indexPath.section == 0 && self.node.isOutShare) ? @"SharedItemContactsTableViewCellID" : @"NodeDetailsTableViewCellID";
            break;
        }
            
        case DisplayModeSharedItem: {
            if (indexPath.section == 0) {
                if (self.node.isInShare) {
                    cellIdentifier = [self.userName isEqualToString:self.email] ? @"SharedItemContactsTableViewCellID" : @"SharedItemContactTableViewCellID";
                } else if (self.node.isOutShare) {
                    cellIdentifier = @"SharedItemContactsTableViewCellID";
                }
            } else if (indexPath.section == 1) {
                cellIdentifier = @"NodeDetailsTableViewCellID";
            }
            break;
        }
    }
    
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    return cell;
}

- (void)setInShareCell:(NodeTableViewCell *)cell {
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.email];
    [cell.thumbnailImageView mnz_setImageForUserHandle:user.handle];
    
    NSString *owner = [NSString stringWithFormat:@" (%@)", AMLocalizedString(@"owner", @"Text shown next to name of the 'Owner' of the folder that is being shared")];
    NSMutableAttributedString *ownerMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:owner];
    [ownerMutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor mnz_redF0373A] range:[owner rangeOfString:owner]];
    
    NSMutableAttributedString *userNameMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.userName];
    [userNameMutableAttributedString appendAttributedString:ownerMutableAttributedString];
    cell.nameLabel.attributedText = userNameMutableAttributedString;
    cell.infoLabel.text = [self.userName isEqualToString:self.email] ? nil : self.email;
    
    cell.horizontalLineLayoutConstraint.constant = 0.5f;
}

- (void)setOutShareCell:(NodeTableViewCell *)cell {
    cell.thumbnailImageView.image = [UIImage imageNamed:@"info_sharedWith"];
    
    NSMutableArray *outSharesMutableArray = [self outSharesForNode:self.node];
    NSString *sharedWithXContacts;
    NSString *xContacts;
    if (outSharesMutableArray.count > 1) {
        sharedWithXContacts = [NSString stringWithFormat:AMLocalizedString(@"sharedWithXContacts", @"Text shown to explain with how many contacts you have shared a folder"), outSharesMutableArray.count];
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
        [sharedWithXContactsMutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor mnz_redF0373A] range:range];
        cell.nameLabel.attributedText = sharedWithXContactsMutableAttributedString;
    }
    
    cell.arrowImageView.image = [UIImage imageNamed:@"info_sharedWithArrow"];
    
    cell.horizontalLineLayoutConstraint.constant = 0.5f;
}

- (void)setSaveForOfflineCell:(NodeTableViewCell *)cell {
    if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
        cell.thumbnailImageView.image = [UIImage imageNamed:@"download"];
        cell.nameLabel.text = AMLocalizedString(@"queued", @"Text shown when one file has been selected to be downloaded but it's on the queue to be downloaded, it's pending for download");
    } else {
        MOOfflineNode *offlineNode = [[MEGAStore shareInstance] offlineNodeWithNode:self.node api:[MEGASdkManager sharedMEGASdk]];
        if (offlineNode != nil) {
            cell.thumbnailImageView.image = [UIImage imageNamed:@"downloaded"];
            cell.nameLabel.text = AMLocalizedString(@"savedForOffline", @"List option shown on the details of a file or folder");
        } else {
            cell.thumbnailImageView.image = [UIImage imageNamed:@"download"];
            cell.nameLabel.text = AMLocalizedString(@"saveForOffline", @"List option shown on the details of a file or folder");
        }
    }
}

#pragma mark - IBActions

- (IBAction)shareTouchUpInside:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] button:self.shareBarButtonItem];
    [self presentViewController:activityVC animated:YES completion:nil];
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
    NSInteger numberOfRows = 0;
    if ((section == 0) && ((self.displayMode == DisplayModeSharedItem) || (self.displayMode == DisplayModeCloudDrive && self.node.isOutShare))) {
        numberOfRows = 1;
    } else {
        switch (self.accessType) {
            case MEGAShareTypeAccessRead:
            case MEGAShareTypeAccessReadWrite: {
                if (self.isIncomingShareChildView) {
                    numberOfRows = 2; //Download and copy
                } else {
                    numberOfRows = 3; //Download, copy and leave sharing
                }
                break;
            }

            case MEGAShareTypeAccessFull:
                if (self.isIncomingShareChildView) {
                    numberOfRows = 3; //Download, copy and rename
                } else {
                    numberOfRows = 4; //Download, copy, rename and leave sharing
                }
                break;
                
            case MEGAShareTypeAccessOwner:
                if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin) {
                    numberOfRows = 7; //Download, move, copy, rename, remove link, remove sharing and move to rubbish bin
                } else {
                    numberOfRows = 4; //Download, copy, rename and remove sharing
                }
                break;
                
            default:
                break;
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NodeTableViewCell *cell = [self dequeueCellForIndexPath:indexPath];
    
    if (([self numberOfSectionsInTableView:self.tableView] == 2) && (indexPath.section == 0) && (self.displayMode == DisplayModeSharedItem || (self.displayMode == DisplayModeCloudDrive && self.node.isOutShare))) {
        if (self.accessType == MEGAShareTypeAccessRead || self.accessType == MEGAShareTypeAccessReadWrite || self.accessType == MEGAShareTypeAccessFull) {
            [self setInShareCell:cell];
        } else if (self.accessType == MEGAShareTypeAccessOwner) {
            [self setOutShareCell:cell];
        }
    } else {
        if (self.displayMode == DisplayModeSharedItem || (self.displayMode == DisplayModeCloudDrive && self.isIncomingShareChildView)) {
            switch (indexPath.row) {
                case 0:
                    [self setSaveForOfflineCell:cell];
                    break;
                    
                case 1:
                    cell.thumbnailImageView.image = [UIImage imageNamed:@"copy"];
                    cell.nameLabel.text = AMLocalizedString(@"copy", @"List option shown on the details of a file or folder");
                    break;
                    
                case 2:
                    if (self.accessType == MEGAShareTypeAccessRead || self.accessType == MEGAShareTypeAccessReadWrite) {
                        cell.thumbnailImageView.image = [UIImage imageNamed:@"leaveShare"];
                        cell.nameLabel.text = AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
                    } else if (self.accessType == MEGAShareTypeAccessFull || self.accessType == MEGAShareTypeAccessOwner) {
                        cell.thumbnailImageView.image = [UIImage imageNamed:@"rename"];
                        cell.nameLabel.text = AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder");
                    }
                    break;
                    
                case 3:
                    if (self.accessType == MEGAShareTypeAccessRead || self.accessType == MEGAShareTypeAccessReadWrite || self.accessType == MEGAShareTypeAccessFull) {
                        cell.thumbnailImageView.image = [UIImage imageNamed:@"leaveShare"];
                        cell.nameLabel.text = AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
                    } else if (self.accessType == MEGAShareTypeAccessFull) {
                        if (self.isIncomingShareChildView) {
                            cell.thumbnailImageView.image = [UIImage imageNamed:@"rubbishBin"];
                            cell.nameLabel.text = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to \"Move to the Rubbish Bin\" files or folders");
                        } else {
                            cell.thumbnailImageView.image = [UIImage imageNamed:@"leaveShare"];
                            cell.nameLabel.text = AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
                        }
                    } else if (self.accessType == MEGAShareTypeAccessOwner) {
                        cell.thumbnailImageView.image = [UIImage imageNamed:@"removeShare"];
                        cell.nameLabel.text = AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share");
                    }
                    break;
            }
        } else {
            switch (indexPath.row) {
                case 0:
                    [self setSaveForOfflineCell:cell];
                    break;
                    
                case 1:
                    cell.thumbnailImageView.image = [UIImage imageNamed:@"move"];
                    cell.nameLabel.text = AMLocalizedString(@"move", @"Title for the action that allows you to move a file or folder");
                    break;
                    
                case 2:
                    cell.thumbnailImageView.image = [UIImage imageNamed:@"copy"];
                    cell.nameLabel.text = AMLocalizedString(@"copy", @"List option shown on the details of a file or folder");
                    break;
                    
                case 3:
                    cell.thumbnailImageView.image = [UIImage imageNamed:@"rename"];
                    cell.nameLabel.text = AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder");
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
                    if (self.displayMode == DisplayModeCloudDrive) {
                        cell.thumbnailImageView.image = [UIImage imageNamed:@"rubbishBin"];
                        cell.nameLabel.text = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
                    } else if (self.displayMode == DisplayModeRubbishBin) {
                        cell.thumbnailImageView.image = [UIImage imageNamed:@"remove"];
                        cell.nameLabel.text = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
                    }
                    break;
            }
        }
    }
    
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([self numberOfSectionsInTableView:self.tableView] == 2) && (indexPath.section == 0) && (self.displayMode == DisplayModeSharedItem || (self.displayMode == DisplayModeCloudDrive && self.node.isOutShare))) {
        return 66.0;
    }
    
    if (self.accessType == MEGAShareTypeAccessOwner && (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin)) {
        if (((indexPath.row == 4) && !self.node.isExported) || ((indexPath.row == 5) && !self.node.isOutShare)) {
            return 0.0;
        }
    }
    
    return 44.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([self numberOfSectionsInTableView:self.tableView] == 2) && (indexPath.section == 0) && (self.displayMode == DisplayModeSharedItem || (self.displayMode == DisplayModeCloudDrive && self.node.isOutShare))) {
        if (self.accessType == MEGAShareTypeAccessRead || self.accessType == MEGAShareTypeAccessReadWrite || self.accessType == MEGAShareTypeAccessFull) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        } else if (self.accessType == MEGAShareTypeAccessOwner) {
            ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            contactsVC.contactsMode = ContactsModeFolderSharedWith;
            contactsVC.node = self.node;
            
            [self.navigationController pushViewController:contactsVC animated:YES];
        }
    } else {
        if (self.displayMode == DisplayModeSharedItem || (self.displayMode == DisplayModeCloudDrive && self.isIncomingShareChildView)) {
            switch (indexPath.row) {
                case 0:
                    [self downloadOrCancelDownload];
                    break;
                    
                case 1:
                    [self browserWithAction:BrowserActionCopy];
                    break;
                    
                case 2:
                    if (self.accessType == MEGAShareTypeAccessRead || self.accessType == MEGAShareTypeAccessReadWrite) {
                        [self moveToTheRubbishBinOrRemoveOrLeave]; //Leave share
                    } else if (self.accessType == MEGAShareTypeAccessFull || self.accessType == MEGAShareTypeAccessOwner) {
                        [self rename];
                    }
                    break;
                    
                case 3:
                    if (self.accessType == MEGAShareTypeAccessRead || self.accessType == MEGAShareTypeAccessReadWrite || self.accessType == MEGAShareTypeAccessFull) {
                        [self moveToTheRubbishBinOrRemoveOrLeave]; //Leave share
                    } else if (self.accessType == MEGAShareTypeAccessFull) {
                        if (self.isIncomingShareChildView) {
                            [self moveToTheRubbishBinOrRemoveOrLeave]; //Move to the Rubbish Bin
                        } else {
                            [self moveToTheRubbishBinOrRemoveOrLeave]; //Leave share
                        }
                    } else if (self.accessType == MEGAShareTypeAccessOwner) {
                        [self confirmRemoveSharing]; //Remove sharing
                    }
                    break;
            }
        } else {
            switch (indexPath.row) {
                case 0:
                    [self downloadOrCancelDownload];
                    break;
                    
                case 1:
                    [self browserWithAction:BrowserActionMove];
                    break;
                    
                case 2:
                    [self browserWithAction:BrowserActionCopy];
                    break;
                    
                case 3:
                    [self rename];
                    break;
                    
                case 4: {
                    MEGAExportRequestDelegate *requestDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                        NSString *status = AMLocalizedString(@"linkRemoved", @"Message shown when the links to a file or folder has been removed");
                        [SVProgressHUD showSuccessWithStatus:status];
                    } multipleLinks:NO];
                    
                    [[MEGASdkManager sharedMEGASdk] disableExportNode:self.node delegate:requestDelegate];
                    break;
                }
                    
                case 5:
                    [self confirmRemoveSharing];
                    break;
                    
                case 6:
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [self moveToTheRubbishBinOrRemoveOrLeave]; //Move to the Rubbish Bin
                    } else if (self.displayMode == DisplayModeRubbishBin) {
                        [self moveToTheRubbishBinOrRemoveOrLeave]; //Remove
                    }
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
