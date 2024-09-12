#import "NodeVersionsViewController.h"

#import "SVProgressHUD.h"

#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "UIImageView+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "Helper.h"
#import "NodeTableViewCell.h"
#import "MEGAPhotoBrowserViewController.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface NodeVersionsViewController () <
UITableViewDelegate,
UITableViewDataSource,
NodeActionViewControllerDelegate,
MEGADelegate
>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@end

@implementation NodeVersionsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    self.editBarButtonItem.title = LocalizedString(@"select", @"Caption of a button to select files");
    self.closeBarButtonItem.title = LocalizedString(@"close", @"A button label.");

    [self configureToolbarItems];
    self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    [self.tableView registerNib:[UINib nibWithNibName:@"GenericHeaderFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"GenericHeaderFooterViewID"];
    
    [self reloadUI];
    
    self.navigationItem.leftBarButtonItems = @[self.closeBarButtonItem];
    if (!self.node.mnz_isInRubbishBin) {
        self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.presentedViewController) {
        [MEGASdk.shared addMEGADelegate:self];
    }
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (!self.presentedViewController) {
        [MEGASdk.shared removeMEGADelegateAsync:self];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        
        [self updateAppearance];
        
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        
        [AppearanceManager forceToolbarUpdate:self.navigationController.toolbar traitCollection:self.traitCollection];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.backgroundColor = [self defaultBackgroundColor];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NodeVersionSection *versionSection = self.sections[section];
    return [versionSection itemCount];
}

- (NodeVersionItem *)itemAt:(NSIndexPath *)indexPath {
    NodeVersionSection *section = self.sections[indexPath.section];
    NodeVersionItem *item = [section itemAtIndex:indexPath.row];
    return item;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [[self itemAt:indexPath] node];

    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    cell.cellFlavor = NodeTableViewCellFlavorVersions;
    cell.isNodeInRubbishBin = [node mnz_isInRubbishBin];
    [cell configureCellForNode:node shouldApplySensitiveBehaviour:NO api:MEGASdk.shared];
    
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
    cell.backgroundColor = [self defaultBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [[self itemAt:indexPath] node];

    if (tableView.isEditing) {
        if (indexPath.section == 0) {
            return;
        }
        [self.selectedNodesArray addObject:node];
        
        [self updateNavigationBarTitle];
        
        [self setToolbarActionsEnabled:YES];
        [tableView reloadData];
    
    } else {
        [self open:node];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        MEGANode *node = [[self itemAt:indexPath] node];
        NSMutableArray *tempArray = [self.selectedNodesArray copy];
        for (MEGANode *tempNode in tempArray) {
            if (tempNode.handle == node.handle) {
                [self.selectedNodesArray removeObject:tempNode];
            }
        }
        
        [self updateNavigationBarTitle];
        
        [self setToolbarActionsEnabled:self.selectedNodesArray.count != 0];
        
        return;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    GenericHeaderFooterView *sectionHeader = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    
    [sectionHeader setPreferredBackgroundColor:[self defaultBackgroundColor]];
    
    if (section == 0) {
        [sectionHeader configureWithTitle:LocalizedString(@"currentVersion", @"Title of section to display information of the current version of a file") topDistance:30.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
    } else {
        [sectionHeader configureWithTitle:LocalizedString(@"previousVersions", @"A button label which opens a dialog to display the full version history of the selected file") detail:[NSString memoryStyleStringFromByteCount:self.node.mnz_versionsSize] topDistance:30.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
    }
    return sectionHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    GenericHeaderFooterView *sectionFooter = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    
    [sectionFooter setPreferredBackgroundColor:[self defaultBackgroundColor]];
    
    [sectionFooter configureWithTitle:nil topDistance:2.0 isTopSeparatorVisible:YES isBottomSeparatorVisible:NO];
    
    return sectionFooter;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.node.mnz_isInRubbishBin) {
        return nil;
    }
    
    MEGANode *node = [[self itemAt:indexPath] node];
    self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
    
    NSMutableArray *rightActions = [NSMutableArray new];
    
    if ([MEGASdk.shared accessLevelForNode:self.node] >= MEGAShareTypeAccessFull) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self removeAction:nil];
        }];
        removeAction.image = [[UIImage imageNamed:@"delete"] imageWithTintColor:[self swipeIconTintColor]];
        removeAction.backgroundColor = [self deleteSwipeBackgroundColor];
        [rightActions addObject:removeAction];
    }
    
    if (indexPath.section != 0 && [MEGASdk.shared accessLevelForNode:self.node] >= MEGAShareTypeAccessReadWrite) {
        UIContextualAction *revertAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self revertAction:nil];
        }];
        
        revertAction.image = [[UIImage imageNamed:@"history"] imageWithTintColor:[self swipeIconTintColor]];
        revertAction.backgroundColor = [self revertSwipeBackgroundColor];
        [rightActions addObject:revertAction];
    }
        
    UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        if (node != nil) {
            [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:@[node] presenter:self isFolderLink:NO];
        }
        [self setEditing:NO animated:YES];
    }];
    downloadAction.image = [[UIImage imageNamed:@"offline"] imageWithTintColor:[self swipeIconTintColor]];
    downloadAction.backgroundColor = [self offlineSwipeBackgroundColor];
    [rightActions addObject:downloadAction];
    
    return [UISwipeActionsConfiguration configurationWithActions:rightActions];
}

#pragma mark - Private

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.tableView.isEditing) {
        navigationTitle = [self selectedCountTitle];
    } else {
        navigationTitle = LocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    }
    
    self.navigationItem.title = navigationTitle;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [self.tableView setEditing:editing animated:animated];
    
    [self updateNavigationBarTitle];
    
    if (editing) {
        self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
        self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        [self.navigationController setToolbarHidden:NO animated:YES];
        
        for (NodeTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        self.editBarButtonItem.title = LocalizedString(@"select", @"Caption of a button to select files");

        [self.selectedNodesArray removeAllObjects];
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

#pragma mark - IBActions

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    if (self.selectedNodesArray.count == 1) {
        [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:self.selectedNodesArray presenter:self isFolderLink:NO];
        [self setEditing:NO animated:YES];
    }
}

- (IBAction)revertAction:(id)sender {
    if (self.selectedNodesArray.count != 1) {
        return;
    }
    MEGANode *node = self.selectedNodesArray.firstObject;
    
    if ([MEGASdk.shared accessLevelForNode:node] == MEGAShareTypeAccessReadWrite) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"permissionTitle", @"Error title shown when you are trying to do an action with a file or folder and you don’t have the necessary permissions") message:LocalizedString(@"You do not have the permissions required to revert this file. In order to continue, we can create a new file with the reverted data. Would you like to proceed?", @"Confirmation dialog shown to user when they try to revert a node in an incoming ReadWrite share.") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"Create new file", @"Text shown for the action create new file") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MEGASdk.shared restoreVersionNode:node delegate:[RequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
                if (!error) {
                    [SVProgressHUD showSuccessWithStatus:LocalizedString(@"Version created as a new file successfully.", @"Text shown when the creation of a version as a new file was successful")];
                }
            }]];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [MEGASdk.shared restoreVersionNode:node];
    }
    
    [self setEditing:NO animated:YES];
}

- (IBAction)removeAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"deleteVersion", @"Question to ensure user wants to delete file version") message:LocalizedString(@"permanentlyRemoved", @"Message to notify user the file version will be permanently removed") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"delete", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (MEGANode *node in self.selectedNodesArray) {
            [MEGASdk.shared removeVersionNode:node];
        }
        [self setEditing:NO animated:YES];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    [self setEditing:!self.tableView.isEditing animated:YES];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    
    if ([self allNodesSelected]) {
        [self.selectedNodesArray removeAllObjects];
        [self setToolbarActionsEnabled:NO];
    } else {
        self.selectedNodesArray = [[[self previousVersionsSection] nodes] mutableCopy];
        [self setToolbarActionsEnabled:YES];
    }
    
    [self updateNavigationBarTitle];
    [self.tableView reloadData];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    MEGANode *node = [[self itemAt:indexPath] node];
    
    BOOL isBackupNode = [[[BackupsOCWrapper alloc] init] isBackupNode:node];
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node delegate:self displayMode:DisplayModeNodeVersions isIncoming:NO isBackupNode:isBackupNode isFromSharedItem: NO sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)closeAction:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeDownload:
            if (node != nil) {
                [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:@[node] presenter:self isFolderLink:NO];
            }
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
            [SaveMediaToPhotosUseCaseOCWrapper.new saveToPhotosWithNodes:@[node] isFolderLink:NO];
            break;
            
        case MegaNodeActionTypeExportFile:
            [self exportFileFrom:node sender:sender];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    NSUInteger size = nodeList.size;
    for (NSUInteger i = 0; i < size; i++) {
        MEGANode *nodeUpdated = [nodeList nodeAtIndex:i];
        if ([nodeUpdated hasChangedType:MEGANodeChangeTypeRemoved]) {
            if (nodeUpdated.handle == self.node.handle) {
                self.node = nodeUpdated;
                [self currentVersionRemoved];
                break;
            } else {
                if ([self isNodeWithHandlePreviousVersion:nodeUpdated.base64Handle]) {
                    self.node = [MEGASdk.shared nodeForHandle:self.node.handle];
                    [self reloadUI];
                    break;
                }
            }
        }
        
        if ([nodeUpdated hasChangedType:MEGANodeChangeTypeParent]) {
            if (nodeUpdated.handle == self.node.handle) {
                self.node = [MEGASdk.shared nodeForHandle:nodeUpdated.parentHandle];
                [self reloadUI];
                break;
            }
        }
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        if ([self isNodeWithHandlePreviousVersion:base64Handle]) {
            [self reloadUI];
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"permissionTitle", @"") message:LocalizedString(@"permissionMessage", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        } else if (error.type == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:LocalizedString(@"transferCancelled", @"")];
            NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
            if ([self isNodeWithHandlePreviousVersion:base64Handle]) {
                [self reloadUI];
            }
        }
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        [self reloadUI];
    }
}

@end
