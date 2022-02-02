
#import "NodeVersionsViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "UIImageView+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "Helper.h"
#import "NodeTableViewCell.h"

#import "MEGAPhotoBrowserViewController.h"

@interface NodeVersionsViewController () <UITableViewDelegate, UITableViewDataSource, NodeActionViewControllerDelegate, MEGADelegate> {
    BOOL allNodesSelected;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *revertBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *removeBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<MEGANode *> *nodeVersionsMutableArray;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@end

@implementation NodeVersionsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    self.editBarButtonItem.title = NSLocalizedString(@"select", @"Caption of a button to select files");
    self.closeBarButtonItem.title = NSLocalizedString(@"close", @"A button label.");

    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[self.downloadBarButtonItem, flexibleItem, self.revertBarButtonItem, flexibleItem, self.removeBarButtonItem] animated:YES];
    
    self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    [self.tableView registerNib:[UINib nibWithNibName:@"GenericHeaderFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"GenericHeaderFooterViewID"];
    
    [self reloadUI];
    
    self.navigationItem.leftBarButtonItems = @[self.closeBarButtonItem];
    if (!self.node.mnz_isInRubbishBin) {
        self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
    }
    
    self.nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.presentedViewController) {
        [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    }
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (!self.presentedViewController) {
        [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (void)reloadUI {
    if (self.node.mnz_numberOfVersions == 0) {
        [self dismissViewControllerAnimated:true completion:nil];
    }  else {
        [self.nodesIndexPathMutableDictionary removeAllObjects];
        
        self.nodeVersionsMutableArray = [NSMutableArray.alloc initWithArray:self.node.mnz_versions];
        
        [self.tableView reloadData];
    }
}

- (void)updateAppearance {
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.node.mnz_numberOfVersions-1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self nodeForIndexPath:indexPath];

    [self.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
    
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    cell.cellFlavor = NodeTableViewCellFlavorVersions;
    cell.isNodeInRubbishBin = [node mnz_isInRubbishBin];
    [cell configureCellForNode:node api:[MEGASdkManager sharedMEGASdk]];
    
    if (self.tableView.isEditing) {
        for (MEGANode *tempNode in self.selectedNodesArray) {
            if (tempNode.handle == node.handle) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGroupedElevated:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self nodeForIndexPath:indexPath];

    if (tableView.isEditing) {
        if (indexPath.section == 0) {
            return;
        }
        [self.selectedNodesArray addObject:node];
        
        [self updateNavigationBarTitle];
        
        [self setToolbarActionsEnabled:YES];
        
        if (self.selectedNodesArray.count == self.node.mnz_numberOfVersions-1) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
    
    } else {
        if (node.name.mnz_isVisualMediaPathExtension) {
            NSMutableArray<MEGANode *> *mediaNodesArray = [[[MEGASdkManager sharedMEGASdk] versionsForNode:self.node] mnz_mediaNodesMutableArrayFromNodeList];
            
            DisplayMode displayMode = self.node.mnz_isInRubbishBin ? DisplayModeRubbishBin : DisplayModeNodeVersions;
            MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:displayMode presentingNode:node preferredIndex:0];
            [self.navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
        } else {
            [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO fileLink:nil];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > (self.node.mnz_numberOfVersions - 1)) {
        return;
    }

    if (tableView.isEditing) {
        MEGANode *node = [self nodeForIndexPath:indexPath];
        NSMutableArray *tempArray = [self.selectedNodesArray copy];
        for (MEGANode *tempNode in tempArray) {
            if (tempNode.handle == node.handle) {
                [self.selectedNodesArray removeObject:tempNode];
            }
        }
        
        [self updateNavigationBarTitle];
        
        [self setToolbarActionsEnabled:self.selectedNodesArray.count != 0];
        
        allNodesSelected = NO;
        
        return;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    GenericHeaderFooterView *sectionHeader = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    
    if (section == 0) {
        [sectionHeader configureWithTitle:NSLocalizedString(@"currentVersion", @"Title of section to display information of the current version of a file").localizedUppercaseString topDistance:30.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
    } else {
        [sectionHeader configureWithTitle:NSLocalizedString(@"previousVersions", @"A button label which opens a dialog to display the full version history of the selected file").localizedUppercaseString detail:[Helper memoryStyleStringFromByteCount:self.node.mnz_versionsSize] topDistance:30.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
    }
    return sectionHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    GenericHeaderFooterView *sectionFooter = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    
    [sectionFooter configureWithTitle:nil topDistance:2.0 isTopSeparatorVisible:YES isBottomSeparatorVisible:NO];
    
    return sectionFooter;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.node.mnz_isInRubbishBin) {
        return nil;
    }
    
    self.selectedNodesArray = [NSMutableArray arrayWithObject:[self nodeForIndexPath:indexPath]];
    
    NSMutableArray *rightActions = [NSMutableArray new];
    
    if ([MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] >= MEGAShareTypeAccessFull) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self removeAction:nil];
        }];
        removeAction.image = [[UIImage imageNamed:@"delete"] imageWithTintColor:UIColor.whiteColor];
        removeAction.backgroundColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
        [rightActions addObject:removeAction];
    }
    
    if (indexPath.section != 0 && [MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] >= MEGAShareTypeAccessReadWrite) {
        UIContextualAction *revertAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self revertAction:nil];
        }];
        
        revertAction.image = [[UIImage imageNamed:@"history"] imageWithTintColor:UIColor.whiteColor];
        revertAction.backgroundColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
        [rightActions addObject:revertAction];
    }
        
    UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MEGANode *node = [self nodeForIndexPath:indexPath];
        [node mnz_downloadNode];
        [self setEditing:NO animated:YES];
    }];
    downloadAction.image = [[UIImage imageNamed:@"offline"] imageWithTintColor:UIColor.whiteColor];
    downloadAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    [rightActions addObject:downloadAction];
    
    return [UISwipeActionsConfiguration configurationWithActions:rightActions];
}

#pragma mark - Private

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.tableView.isEditing) {
        if (self.selectedNodesArray.count == 0) {
            navigationTitle = NSLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            navigationTitle = (self.selectedNodesArray.count <= 1) ? [NSString stringWithFormat:NSLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), self.selectedNodesArray.count] : [NSString stringWithFormat:NSLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), self.selectedNodesArray.count];
        }
    } else {
        navigationTitle = NSLocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    }
    
    self.navigationItem.title = navigationTitle;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [self.tableView setEditing:editing animated:animated];
    
    [self updateNavigationBarTitle];
    
    if (editing) {
        self.editBarButtonItem.title = NSLocalizedString(@"cancel", @"Button title to cancel something");
        self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        [self.navigationController setToolbarHidden:NO animated:YES];
        
        for (NodeTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        self.editBarButtonItem.title = NSLocalizedString(@"select", @"Caption of a button to select files");

        allNodesSelected = NO;
        self.selectedNodesArray = nil;
        self.navigationItem.leftBarButtonItems = @[self.closeBarButtonItem];
        
        [self.navigationController setToolbarHidden:YES animated:YES];
        
        for (NodeTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectedBackgroundView = nil;
        }
    }
    
    if (!self.selectedNodesArray) {
        self.selectedNodesArray = [NSMutableArray new];

        [self setToolbarActionsEnabled:NO];
    }        
}

- (void)setToolbarActionsEnabled:(BOOL)boolValue {
    self.downloadBarButtonItem.enabled = self.selectedNodesArray.count == 1 ? boolValue : NO;
    self.revertBarButtonItem.enabled = (self.selectedNodesArray.count == 1 && self.selectedNodesArray.firstObject.handle != self.node.handle && [MEGASdkManager.sharedMEGASdk accessLevelForNode:self.node] >= MEGAShareTypeAccessReadWrite) ? boolValue : NO;
    self.removeBarButtonItem.enabled = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node] < MEGAShareTypeAccessFull ? NO : boolValue;
}

- (MEGANode *)nodeForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return self.node.mnz_versions.firstObject;
    } else {
        return [self.nodeVersionsMutableArray objectAtIndex:indexPath.row + 1];
    }
}

#pragma mark - IBActions

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    if (self.selectedNodesArray.count == 1) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", nil)];
        
        [self.selectedNodesArray.firstObject mnz_downloadNode];
        
        [self setEditing:NO animated:YES];
        
        [self.tableView reloadData];
    }
}

- (IBAction)revertAction:(id)sender {
    if (self.selectedNodesArray.count != 1) {
        return;
    }
    MEGANode *node = self.selectedNodesArray.firstObject;
    
    if ([MEGASdkManager.sharedMEGASdk accessLevelForNode:node] == MEGAShareTypeAccessReadWrite) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"permissionTitle", @"Error title shown when you are trying to do an action with a file or folder and you don’t have the necessary permissions") message:NSLocalizedString(@"You do not have the permissions required to revert this file. In order to continue, we can create a new file with the reverted data. Would you like to proceed?", @"Confirmation dialog shown to user when they try to revert a node in an incoming ReadWrite share.") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Create new file", @"Text shown for the action create new file") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MEGASdkManager.sharedMEGASdk restoreVersionNode:node delegate:[MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
                if (error.type == MEGAErrorTypeApiOk) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Version created as a new file successfully.", @"Text shown when the creation of a version as a new file was successful")];
                }
            }]];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [MEGASdkManager.sharedMEGASdk restoreVersionNode:node];
    }
    
    [self setEditing:NO animated:YES];
}

- (IBAction)removeAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"deleteVersion", @"Question to ensure user wants to delete file version") message:NSLocalizedString(@"permanentlyRemoved", @"Message to notify user the file version will be permanently removed") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"delete", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (MEGANode *node in self.selectedNodesArray) {
            [[MEGASdkManager sharedMEGASdk] removeVersionNode:node];
        }
        [self setEditing:NO animated:YES];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    [self setEditing:!self.tableView.isEditing animated:YES];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedNodesArray removeAllObjects];
    
    if (!allNodesSelected) {
        MEGANode *n = nil;
        
        for (NSInteger i = 1; i < self.node.mnz_numberOfVersions; i++) {
            n = [self.nodeVersionsMutableArray objectAtIndex:i];
            [self.selectedNodesArray addObject:n];
        }
        
        allNodesSelected = YES;
        [self setToolbarActionsEnabled:YES];
    } else {
        allNodesSelected = NO;
        [self setToolbarActionsEnabled:NO];
    }
    
    [self updateNavigationBarTitle];
    [self.tableView reloadData];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:[self nodeForIndexPath:indexPath] delegate:self displayMode:DisplayModeNodeVersions isIncoming:NO sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)closeAction:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeDownload:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [node mnz_downloadNode];
            break;
            
        case MegaNodeActionTypeRemove:
            self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
            [self removeAction:nil];
            break;
            
        case MegaNodeActionTypeRevertVersion:
            self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
            [self revertAction:nil];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [node mnz_saveToPhotos];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    NSUInteger size = nodeList.size.unsignedIntegerValue;
    for (NSUInteger i = 0; i < size; i++) {
        MEGANode *nodeUpdated = [nodeList nodeAtIndex:i];
        if ([nodeUpdated hasChangedType:MEGANodeChangeTypeRemoved]) {
            if (nodeUpdated.handle == self.node.handle) {
                [self currentVersionRemoved];
                break;
            } else {
                if ([self.nodesIndexPathMutableDictionary objectForKey:nodeUpdated.base64Handle]) {
                    self.node = [MEGASdkManager.sharedMEGASdk nodeForHandle:self.node.handle];
                    [self reloadUI];
                    break;
                }
            }
        }
        
        if ([nodeUpdated hasChangedType:MEGANodeChangeTypeParent]) {
            if (nodeUpdated.handle == self.node.handle) {
                self.node = [MEGASdkManager.sharedMEGASdk nodeForHandle:nodeUpdated.parentHandle];
                [self reloadUI];
                break;
            }
        }
    }
}

- (void)currentVersionRemoved {
    if (self.nodeVersionsMutableArray.count == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        self.node = [self.nodeVersionsMutableArray objectAtIndex:1];
        [self reloadUI];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (error.type) {
        if (error.type == MEGAErrorTypeApiEAccess) {
            if (transfer.type ==  MEGATransferTypeUpload) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"permissionTitle", nil) message:NSLocalizedString(@"permissionMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        } else if (error.type == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:NSLocalizedString(@"transferCancelled", nil)];
            NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
            NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
            if (indexPath != nil) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        [self.tableView reloadData];
    }
}

@end
