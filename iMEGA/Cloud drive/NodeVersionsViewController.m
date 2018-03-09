
#import "NodeVersionsViewController.h"

#import "SVProgressHUD.h"

#import "MEGAStore.h"
#import "MEGASdkManager.h"
#import "MEGANode+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "Helper.h"
#import "NodeTableViewCell.h"
#import "CustomActionViewController.h"

@interface NodeVersionsViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate, CustomActionViewControllerDelegate, MEGADelegate> {
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *revertBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *removeBarButtonItem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@end

@implementation NodeVersionsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = AMLocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    self.editBarButtonItem.title = AMLocalizedString(@"edit", @"Caption of a button to edit the files that are selected");

    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[self.downloadBarButtonItem, flexibleItem, self.revertBarButtonItem, flexibleItem, self.removeBarButtonItem] animated:YES];
    
    [self reloadUI];
    
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
    
    self.nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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

#pragma mark - Layout

- (void)reloadUI {
    if (self.node.mnz_numberOfVersions == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }  else {
        [self.nodesIndexPathMutableDictionary removeAllObjects];
        [self.tableView reloadData];
    }
}

#pragma mark - TableViewDataSource

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
    [cell configureCellForNode:node delegate:self api:[MEGASdkManager sharedMEGASdk]];
    
    if (self.tableView.isEditing) {
        for (MEGANode *tempNode in self.selectedNodesArray) {
            if (tempNode.handle == node.handle) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}

#pragma mark - TableViewDelegate

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
        if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
            [node mnz_openImageInNavigationController:self.navigationController withNodes:self.node.mnz_versions folderLink:NO displayMode:DisplayModeNodeVersions];
        } else {
            [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO];
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
    UITableViewCell *sectionHeader = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoHeader"];
    
    UILabel *titleSection = (UILabel*)[sectionHeader viewWithTag:1];
    UILabel *versionsSize = (UILabel*)[sectionHeader viewWithTag:2];
    
    if (section == 0) {
        titleSection.text = AMLocalizedString(@"currentVersion", @"Title of section to display information of the current version of a file").uppercaseString;
        versionsSize.text = nil;
    } else {
        titleSection.text = AMLocalizedString(@"previousVersions", @"A button label which opens a dialog to display the full version history of the selected file").uppercaseString;
        versionsSize.text = [NSByteCountFormatter stringFromByteCount:self.node.mnz_versionsSize.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory];
    }
    
    return sectionHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UITableViewCell *sectionFooter = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoFooter"];

    return sectionFooter;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    isSwipeEditing = YES;
    MEGANode *node = [self nodeForIndexPath:indexPath];
    
    UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [node mnz_downloadNodeOverwriting:YES];
        [self setEditing:NO animated:YES];
    }];
    downloadAction.image = [UIImage imageNamed:@"infoDownload"];
    downloadAction.backgroundColor = [UIColor colorWithRed:0 green:0.75 blue:0.65 alpha:1];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[downloadAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node] < MEGAShareTypeAccessFull) {
        return [UISwipeActionsConfiguration configurationWithActions:@[]];
    }
    isSwipeEditing = YES;
    self.selectedNodesArray = [NSMutableArray arrayWithObject:[self nodeForIndexPath:indexPath]];
    
    NSMutableArray *rightActions = [NSMutableArray new];
    
    UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self removeAction:nil];
    }];
    removeAction.image = [UIImage imageNamed:@"delete"];
    removeAction.backgroundColor = UIColor.mnz_redF0373A;
    [rightActions addObject:removeAction];
    
    if (indexPath.section != 0) {
        UIContextualAction *revertAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self revertAction:nil];
        }];
        revertAction.image = [UIImage imageNamed:@"history"];
        revertAction.backgroundColor = UIColor.darkGrayColor;
        [rightActions addObject:revertAction];
    }

    return [UISwipeActionsConfiguration configurationWithActions:rightActions];
}

#pragma clang diagnostic pop

#pragma mark - Private

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.tableView.isEditing) {
        if (self.selectedNodesArray.count == 0) {
            navigationTitle = AMLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            navigationTitle = (self.selectedNodesArray.count <= 1) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), self.selectedNodesArray.count] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), self.selectedNodesArray.count];
        }
    } else {
        navigationTitle = AMLocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    }
    
    self.navigationItem.title = navigationTitle;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [self.tableView setEditing:editing animated:animated];
    
    if (!isSwipeEditing) {
        [self updateNavigationBarTitle];
    }
    if (editing) {
        if (!isSwipeEditing) {
            self.editBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
            self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    } else {
        self.editBarButtonItem.title = AMLocalizedString(@"edit", @"Caption of a button to edit the files that are selected");

        allNodesSelected = NO;
        self.selectedNodesArray = nil;
        self.navigationItem.leftBarButtonItems = @[];
        
        [self.navigationController setToolbarHidden:YES animated:YES];

    }
    
    if (!self.selectedNodesArray) {
        self.selectedNodesArray = [NSMutableArray new];

        [self setToolbarActionsEnabled:NO];
    }
    
    isSwipeEditing = NO;
}

- (void)setToolbarActionsEnabled:(BOOL)boolValue {
    self.downloadBarButtonItem.enabled = self.selectedNodesArray.count == 1 ? boolValue : NO;
    self.revertBarButtonItem.enabled = (self.selectedNodesArray.count == 1 && self.selectedNodesArray.firstObject.handle != self.node.handle && [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node] >= MEGAShareTypeAccessFull) ? boolValue : NO;
    self.removeBarButtonItem.enabled = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node] < MEGAShareTypeAccessFull ? NO : boolValue;
}

- (MEGANode *)nodeForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [self.node.mnz_versions objectAtIndex:0];
    } else {
        return [self.node.mnz_versions objectAtIndex:indexPath.row + 1];
    }
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressGestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        
        if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section] || indexPath.section == 0) {
            return;
        }
        
        if (self.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedNodesArray.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedNodesArray.count == 1) {
                MEGANode *nodeSelected = self.selectedNodesArray.firstObject;
                MEGANode *nodePressed = [self nodeForIndexPath:indexPath];
                if (nodeSelected.handle == nodePressed.handle) {
                    [self setEditing:NO animated:YES];
                }
            }
        } else {
            [self setEditing:YES animated:YES];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark - IBActions

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    if (self.selectedNodesArray.count == 1) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
        
        [self.selectedNodesArray.firstObject mnz_downloadNodeOverwriting:YES];
        
        [self setEditing:NO animated:YES];
        
        [self.tableView reloadData];
    }
}

- (IBAction)revertAction:(id)sender {
    if (self.selectedNodesArray.count != 1) {
        return;
    }
    
    [[MEGASdkManager sharedMEGASdk] restoreVersionNode:[self.selectedNodesArray firstObject]];
    
    [self setEditing:NO animated:YES];
}

- (IBAction)removeAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"deleteVersion", @"Question to ensure user wants to delete file version") message:AMLocalizedString(@"permanentlyRemoved", @"Message to notify user the file version will be permanently removed") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"delete", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
            n = [self.node.mnz_versions objectAtIndex:i];
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
    
    CustomActionViewController *actionController = [[CustomActionViewController alloc] init];
    actionController.node = [self nodeForIndexPath:indexPath];
    actionController.displayMode = DisplayModeNodeVersions;
    actionController.actionDelegate = self;
    actionController.actionSender = sender;
    if (indexPath.section == 0) {
        actionController.excludedActions = @[@(MegaNodeActionTypeRevertVersion)];
    }
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popController = [actionController popoverPresentationController];
        popController.delegate = actionController;
        popController.sourceView = sender;
        popController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
    } else {
        actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    
    [self presentViewController:actionController animated:YES completion:nil];
}

#pragma mark - Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction {
    MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node];
    if (direction == MGSwipeDirectionRightToLeft && accessType < MEGAShareTypeAccessFull) {
        return NO;
    }
    return !self.isEditing;
}

- (void)swipeTableCellWillBeginSwiping:(nonnull MGSwipeTableCell *)cell {
    NodeTableViewCell *nodeCell = (NodeTableViewCell *)cell;
    nodeCell.moreButton.hidden = YES;
}

- (void)swipeTableCellWillEndSwiping:(nonnull MGSwipeTableCell *)cell {
    NodeTableViewCell *nodeCell = (NodeTableViewCell *)cell;
    nodeCell.moreButton.hidden = NO;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
    expansionSettings.fillOnTrigger = NO;
    expansionSettings.threshold = 2;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    MEGANode *node = [self nodeForIndexPath:indexPath];
    
    if (direction == MGSwipeDirectionLeftToRight && [[Helper downloadingNodes] objectForKey:node.base64Handle] == nil) {
        
        MGSwipeButton *downloadButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"infoDownload"] backgroundColor:[UIColor colorWithRed:0.0 green:0.75 blue:0.65 alpha:1.0] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
            [node mnz_downloadNodeOverwriting:YES];
            return YES;
        }];
        downloadButton.tintColor = UIColor.whiteColor;
        
        return @[downloadButton];
    } else if (direction == MGSwipeDirectionRightToLeft) {
        
        NSMutableArray *rightButtons = [NSMutableArray new];
        self.selectedNodesArray = [NSMutableArray arrayWithObject:node];

        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete"] backgroundColor:UIColor.mnz_redF0373A padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
            [self removeAction:nil];
            return YES;
        }];
        deleteButton.tintColor = UIColor.whiteColor;
        [rightButtons addObject:deleteButton];
        
        if (indexPath.section != 0) {
            MGSwipeButton *revertButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"history"] backgroundColor:UIColor.darkGrayColor padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                [self revertAction:nil];
                return YES;
            }];
            revertButton.tintColor = UIColor.whiteColor;
            [rightButtons addObject:revertButton];
        }

        return rightButtons;
    } else {
        return nil;
    }
}

#pragma mark - CustomActionViewControllerDelegate

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node fromSender:(id)sender {
    switch (action) {
            
        case MegaNodeActionTypeDownload:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [node mnz_downloadNodeOverwriting:YES];
            break;
            
        case MegaNodeActionTypeRemove:
            self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
            [self removeAction:nil];
            break;
            
        case MegaNodeActionTypeRevertVersion:
            self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
            [self revertAction:nil];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    MEGANode *nodeUpdated;
    
    NSUInteger size = nodeList.size.unsignedIntegerValue;
    for (NSUInteger i = 0; i < size; i++) {
        nodeUpdated = [nodeList nodeAtIndex:i];
        
        switch (nodeUpdated.getChanges) {
                
            case MEGANodeChangeTypeRemoved:
                if (nodeUpdated.handle == self.node.handle) {
                    [self currentVersionRemovedOnNodeList:nodeList];
                } else {
                    self.node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.node.handle];
                    [self reloadUI];
                }
                break;
                
            case MEGANodeChangeTypeParent:
                if (nodeUpdated.handle == self.node.handle) {
                    self.node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:nodeUpdated.parentHandle];
                    [self reloadUI];
                }
                break;
                
            default:
                break;
        }
    }
}

- (void)currentVersionRemovedOnNodeList:(MEGANodeList *)nodeList {
    MEGANode *newCurrentNode;
    
    NSUInteger size = nodeList.size.unsignedIntegerValue;
    for (NSUInteger i = 0; i < size; i++) {
        newCurrentNode = [nodeList nodeAtIndex:i];
        if (newCurrentNode.getChanges == MEGANodeChangeTypeParent) {
            self.node = newCurrentNode;
            [self reloadUI];
            return;
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
    
    if (transfer.type == MEGATransferTypeDownload && [[Helper downloadingNodes] objectForKey:base64Handle]) {
        float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue * 100);
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
        NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:transfer.speed.longLongValue countStyle:NSByteCountFormatterCountStyleMemory]];
        
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            NodeTableViewCell *cell = (NodeTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.infoLabel.text = [NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed];
            cell.downloadProgressView.progress = transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue;
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"permissionTitle", nil) message:AMLocalizedString(@"permissionMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        } else if (error.type == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
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
