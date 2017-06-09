#import "DetailsNodeInfoViewController.h"

#import "NSString+MNZCategory.h"
#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"

#import "Helper.h"
#import "UIImageView+MNZCategory.h"

#import "BrowserViewController.h"
#import "CloudDriveTableViewController.h"
#import "NodeTableViewCell.h"
#import "ContactsViewController.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "GetLinkActivity.h"
#import "ShareFolderActivity.h"
#import "OpenInActivity.h"
#import "RemoveLinkActivity.h"
#import "MEGAActivityItemProvider.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAStore.h"

@interface DetailsNodeInfoViewController () <UIAlertViewDelegate, UIDocumentInteractionControllerDelegate,UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MEGADelegate> {
    UIAlertView *cancelDownloadAlertView;
    UIAlertView *renameAlertView;
    UIAlertView *removeAlertView;
    
    NSInteger actions;
    MEGAShareType accessType;
    
    NSUInteger remainingOperations;
    NSUInteger numberOfShares;
    
    UILabel *navigationBarLabel;
}

@property (nonatomic) BOOL isOwnChange;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
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
                actions = 5; //Download, move, copy, rename and move to rubbish bin or remove
            }
            break;
            
        default:
            break;
    }
    
    if ((self.displayMode == DisplayModeSharedItem) && (accessType != MEGAShareTypeAccessOwner)) {
        [self setNavigationBarTitleLabel];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadUI];
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
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
            NSString *thumbnailFilePath = [Helper pathForNode:self.node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
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

- (void)getLink {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [[MEGASdkManager sharedMEGASdk] exportNode:self.node];
    }
}

- (void)disableLink {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [[MEGASdkManager sharedMEGASdk] disableExportNode:self.node];
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
        if (!renameAlertView) {
            renameAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"rename", nil) message:AMLocalizedString(@"renameNodeMessage", @"Enter the new name") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"rename", nil), nil];
        }
        
        [renameAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [renameAlertView setTag:0];
        
        UITextField *textField = [renameAlertView textFieldAtIndex:0];
        [textField setDelegate:self];
        [textField setText:[self.node name]];
        
        [renameAlertView show];
    }
}

- (void)delete {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveToTheRubbishBin", nil) message:AMLocalizedString(@"moveFileToRubbishBinMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                break;
            }
                
            case DisplayModeRubbishBin: {
                NSString *alertMessage = ([self.node type] == MEGANodeTypeFolder) ? AMLocalizedString(@"removeFolderToRubbishBinMessage", nil) : AMLocalizedString(@"removeFileToRubbishBinMessage", nil);
                removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"remove", nil) message:alertMessage delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                break;
            }
            
            case DisplayModeSharedItem: {
                removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"leaveFolder", nil) message:AMLocalizedString(@"leaveShareAlertMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                break;
            }
                
            default:
                break;
        }
        
        [removeAlertView setTag:1];
        [removeAlertView show];
    }
}

- (void)confirmRemoveSharing {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {

        NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:self.node];
        NSUInteger outSharesCount = [outSharesOfNodeMutableArray count];
        remainingOperations = outSharesCount;
        numberOfShares = outSharesCount;
        
        NSString *alertMessage;
        if (outSharesCount == 1) {
            alertMessage = AMLocalizedString(@"removeOneShareOneContactMessage", nil);
        } else if (outSharesCount > 1) {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeOneShareMultipleContactsMessage", nil), (NSInteger)outSharesCount];
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeSharing", nil) message:alertMessage delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        [alertView setTag:4];
        [alertView show];
    }
}

- (void)removeSharing {
    NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:self.node];
    MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:outSharesOfNodeMutableArray.count completion:nil];
    for (MEGAShare *share in outSharesOfNodeMutableArray) {
        [[MEGASdkManager sharedMEGASdk] shareNode:self.node withEmail:share.user level:MEGAShareTypeAccessUnkown delegate:shareRequestDelegate];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showWarningAfterActionOnNode:(MEGANode *)nodeUpdated {
    NSString *alertTitle = @"";
    
    nodeUpdated = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[self.node handle]];
    if (nodeUpdated != nil) { //Is nil if you don't have access to it
        if (nodeUpdated.parentHandle == self.node.parentHandle) { //Same place as before
            //Node renamed, update UI with the new info.
            //Also when you get link, share folder or remove link
            self.node = nodeUpdated;
            [self reloadUI];
        } else {
            //Node moved to the Rubbish Bin or moved inside the same shared folder
            if (nodeUpdated.parentHandle == [[[MEGASdkManager sharedMEGASdk] rubbishNode] handle]) {
                if ([self.node isFile]) {
                    alertTitle = @"fileMovedToTheRubbishBin_alertTitle";
                } else {
                    alertTitle = @"folderMovedToTheRubbishBin_alertTitle";
                }
            } else {
                if ([self.node isFile]) {
                    alertTitle = @"fileMoved_alertTitle";
                } else {
                    alertTitle = @"folderMoved_alertTitle";
                }
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(alertTitle, nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:nil otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
            [alertView setTag:3];
            [alertView show];
        }
    } else {
        //Node removed from the Rubbish Bin or moved outside of the shared folder
        if ([self.node isFile]) {
            alertTitle = @"youNoLongerHaveAccessToThisFile_alertTitle";
        } else {
            alertTitle = @"youNoLongerHaveAccessToThisFolder_alertTitle";
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(alertTitle, nil)
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:nil otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        [alertView setTag:3];
        [alertView show];
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

#pragma mark - IBActions

- (IBAction)shareTouchUpInside:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] button:self.shareBarButtonItem];
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - UIAlertDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable;
    if ([alertView tag] == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *newName = [textField text];
        NSString *newNameExtension = [newName pathExtension];
        NSString *newNameWithoutExtension = [newName stringByDeletingPathExtension];
        
        NSString *nodeNameString = [self.node name];
        NSString *nodeNameExtension = [NSString stringWithFormat:@".%@", [nodeNameString pathExtension]];
        
        switch ([self.node type]) {
            case MEGANodeTypeFile: {
                if ([newName isEqualToString:@""] ||
                    [newName isEqualToString:nodeNameString] ||
                    [newName isEqualToString:nodeNameExtension] ||
                    ![[NSString stringWithFormat:@".%@", newNameExtension] isEqualToString:nodeNameExtension] || //Particular case, for example: (.jp == .jpg)
                    [newNameWithoutExtension isEqualToString:nodeNameExtension]) {
                    shouldEnable = NO;
                } else {
                    shouldEnable = YES;
                }
                break;
            }
                
            case MEGANodeTypeFolder: {
                if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString]) {
                    shouldEnable = NO;
                } else {
                    shouldEnable = YES;
                }
                break;
            }
                
            default:
                shouldEnable = NO;
                break;
        }
        
    } else {
        shouldEnable = YES;
    }
    
    return shouldEnable;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        [textField setSelectedTextRange:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch ([alertView tag]) {
        case 0: {
            if (buttonIndex == 1) {
                if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                    UITextField *alertViewTextField = [alertView textFieldAtIndex:0];
                    [[MEGASdkManager sharedMEGASdk] renameNode:self.node newName:[alertViewTextField text]];
                }
            }
            break;
        }
            
        case 1: {
            if (buttonIndex == 1) {
                if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                    self.isOwnChange = YES;
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [[MEGASdkManager sharedMEGASdk] moveNode:self.node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
                    } else { //DisplayModeRubbishBin (Remove), DisplayModeSharedItem (Remove share)
                        [[MEGASdkManager sharedMEGASdk] removeNode:self.node];
                    }
                }
            }
            break;
        }
            
        case 2: {
            if (buttonIndex == 1) {
                if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                    NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:self.node.base64Handle];
                    if (transferTag != nil) {
                        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
                    }
                }
            }
            break;
        }
            
        case 3: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
            
        case 4: {
            if (buttonIndex == 1) {
                [self removeSharing];
            }
            break;
        }

    }
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
            numberOfSections = 1;
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
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"NodeDetailsTableViewCellID" forIndexPath:indexPath];
            if (cell == nil) {
                cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NodeDetailsTableViewCellID"];
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
    
    if ((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 0)) {
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
            if ([outSharesMutableArray count] > 1) {
                sharedWithXContacts = [NSString stringWithFormat:AMLocalizedString(@"sharedWithXContacts", nil), [outSharesMutableArray count]];
            } else {
                NSString *tempString = AMLocalizedString(@"removeOneShareOneContactMessage", nil);
                sharedWithXContacts = [tempString mnz_stringBetweenString:@"(" andString:@")"];
            }
            NSArray *sharedWithXContactsArray = [sharedWithXContacts componentsSeparatedByString:@" "];
            NSString *sharedWith = [[sharedWithXContactsArray objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@" %@ ", [sharedWithXContactsArray objectAtIndex:1]]];
            NSString *xContacts = [[sharedWithXContactsArray objectAtIndex:2] stringByAppendingString:[NSString stringWithFormat:@" %@", [sharedWithXContactsArray objectAtIndex:3]]];
            
            NSMutableAttributedString *xContactsMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:xContacts];
            [xContactsMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                                     value:[UIColor mnz_redD90007]
                                                     range:[xContacts rangeOfString:xContacts]];
            
            NSMutableAttributedString *sharedWithMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sharedWith];
            [sharedWithMutableAttributedString appendAttributedString:xContactsMutableAttributedString];
            [cell.nameLabel setAttributedText:sharedWithMutableAttributedString];
            
            [cell.arrowImageView setImage:[UIImage imageNamed:@"info_sharedWithArrow"]];
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
                
                MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:self.node]];
                
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
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 0)) {
        return 66.0;
    }
    
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.displayMode == DisplayModeSharedItem) && (indexPath.section == 0)) {
        return 66.0;
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
        
        switch (indexPath.row) {
            case 0: { //Save for Offline
                if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
                    if (!cancelDownloadAlertView) {
                        cancelDownloadAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"downloading", @"Downloading...")
                                                                             message:AMLocalizedString(@"cancelDownloadAlertViewText", @"Do you want to cancel the download?")
                                                                            delegate:self
                                                                   cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                                   otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    }
                    [cancelDownloadAlertView setTag:2];
                    [cancelDownloadAlertView show];
                } else {
                    MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:self.node]];
                    if (!offlineNodeExist) {
                        [self download];
                    }
                }
                break;
            }
                
            case 1: {
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
                
            case 2: {
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
                
            case 3: {
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
                
            case 4: //Move to the Rubbish Bin / Remove
                [self delete];
                break;
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
        case MEGANodeTypeFile: {
            NSString *textFieldString = [textField text];
            NSString *newName = [textFieldString stringByReplacingCharactersInRange:range withString:string];
            NSString *newNameExtension = [newName pathExtension];
            NSString *newNameWithoutExtension = [newName stringByDeletingPathExtension];
            
            NSString *nodeNameString = [self.node name];
            NSString *nodeNameExtension = [NSString stringWithFormat:@".%@", [nodeNameString pathExtension]];
            
            NSRange nodeWithoutExtensionRange = [[textFieldString stringByDeletingPathExtension] rangeOfString:[textFieldString stringByDeletingPathExtension]];
            NSRange nodeExtensionStartRange = [textFieldString rangeOfString:@"." options:NSBackwardsSearch];
            
            if ((range.location > nodeExtensionStartRange.location) ||
                (range.length > nodeWithoutExtensionRange.length) ||
                ([newName isEqualToString:newNameExtension] && [newNameWithoutExtension isEqualToString:nodeNameExtension]) ||
                ((range.location == nodeExtensionStartRange.location) && [string isEqualToString:@""])) {
                
                UITextPosition *beginning = textField.beginningOfDocument;
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:nodeExtensionStartRange.location];
                [textField setSelectedTextRange:[textField textRangeFromPosition:beginning toPosition:beforeExtension]];
                shouldChangeCharacters = NO;
            } else if (range.location < nodeExtensionStartRange.location) {
                shouldChangeCharacters = YES;
            }
            break;
        }
            
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
                NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
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
            [self showWarningAfterActionOnNode:nodeUpdated];
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
        MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithBase64Handle:self.node.base64Handle];
        if ((offlineNode != nil) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            if (cancelDownloadAlertView.visible) {
                [cancelDownloadAlertView dismissWithClickedButtonIndex:0 animated:YES];
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
