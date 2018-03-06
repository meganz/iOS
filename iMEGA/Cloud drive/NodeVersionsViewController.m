
#import "NodeVersionsViewController.h"

#import "SVProgressHUD.h"

#import "MEGAStore.h"
#import "MEGASdkManager.h"
#import "MEGANode+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGARemoveVersionRequestDelegate.h"
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

@property (weak, nonatomic) IBOutlet UILabel *currentVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *videoIconImageView;

@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@end

@implementation NodeVersionsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = AMLocalizedString(@"versions", @"Title of section to display number of all historical versions of files.");
    self.currentVersionLabel.text = AMLocalizedString(@"currentVersion", @"Title of section to display information of the current version of a file").uppercaseString;
    
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
        [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    }
}

#pragma mark - Layout

- (void)reloadUI {
    self.titleLabel.text = self.node.name;
    
    if (self.node.isFile) {
        [self.thumbnailImageView mnz_setThumbnailByNodeHandle:self.node.handle];
    } else if (self.node.isFolder) {
        self.thumbnailImageView.image = [Helper imageForNode:self.node];
    }
    self.subtitleLabel.text = [Helper sizeAndDateForNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    
    [self.nodesIndexPathMutableDictionary removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - TableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.node.mnz_numberOfVersions;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = [self.node.mnz_versions objectAtIndex:indexPath.row];

    [self.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
    
    BOOL isDownloaded = NO;
    
    NodeTableViewCell *cell;
    if ([[Helper downloadingNodes] objectForKey:node.base64Handle] != nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"downloadingNodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"downloadingNodeCell"];
        }
        
        cell.downloadingArrowImageView.image = [UIImage imageNamed:@"downloadQueued"];
        cell.infoLabel.text = AMLocalizedString(@"queued", @"Queued");
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
        }
        
        if (node.type == MEGANodeTypeFile) {
            MOOfflineNode *offlineNode = [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]];
            
            if (offlineNode) {
                isDownloaded = YES;
            }
        }
        
        cell.infoLabel.text = [Helper sizeAndDateForNode:node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    if ([node isExported]) {
        if (isDownloaded) {
            cell.upImageView.image = [UIImage imageNamed:@"linked"];
            cell.middleImageView.image = nil;
            cell.downImageView.image = [Helper downloadedArrowImage];
        } else {
            cell.upImageView.image = nil;
            cell.middleImageView.image = [UIImage imageNamed:@"linked"];
            cell.downImageView.image = nil;
        }
    } else {
        cell.upImageView.image = nil;
        cell.downImageView.image = nil;
        
        if (isDownloaded) {
            cell.middleImageView.image = [Helper downloadedArrowImage];
        } else {
            cell.middleImageView.image = nil;
        }
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:UIColor.mnz_grayF7F7F7];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    cell.nameLabel.text = [node name];
    
    [cell.thumbnailPlayImageView setHidden:YES];
    
    if (node.isFile) {
        if ([node hasThumbnail]) {
            [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
        } else {
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
    } else if (node.isFolder) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        
        cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    cell.nodeHandle = [node handle];
    
    if (self.tableView.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGANode *n in self.selectedNodesArray) {
            if ([n handle] == [node handle]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    } else {
        cell.delegate = self;
    }
    
    [cell setEditing:self.isEditing];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = [self.node.mnz_versions objectAtIndex:indexPath.row];

    if (tableView.isEditing) {
        [self.selectedNodesArray addObject:node];
        
        [self updateNavigationBarTitle];
        
        [self setToolbarActionsEnabled:YES];
        
        if (self.selectedNodesArray.count == self.node.mnz_versions.count) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
        
        return;
    }
    
    if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
        [node mnz_openImageInNavigationController:self.navigationController withNodes:self.node.mnz_versions folderLink:NO displayMode:DisplayModeNodeVersions];
    } else {
        [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.node.mnz_versions.count) {
        return;
    }

    if (tableView.isEditing) {
        
        MEGANode *node = [self.node.mnz_versions objectAtIndex:indexPath.row];
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = [self.selectedNodesArray copy];
        for (MEGANode *n in tempArray) {
            if (n.handle == node.handle) {
                [self.selectedNodesArray removeObject:n];
            }
        }
        
        [self updateNavigationBarTitle];
        
        [self setToolbarActionsEnabled:self.selectedNodesArray.count != 0];
        
        allNodesSelected = NO;
        
        return;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *sectionHeader = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoHeader"];
    
    UILabel *titleSection = (UILabel*)[sectionHeader viewWithTag:1];
    titleSection.text = AMLocalizedString(@"previousVersions", @"A button label which opens a dialog to display the full version history of the selected file").uppercaseString;
    UILabel *versionsSize = (UILabel*)[sectionHeader viewWithTag:2];
    versionsSize.text = [NSByteCountFormatter stringFromByteCount:self.node.mnz_versionsSize.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory];
    
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
    MEGANode *node = [self.node.mnz_versions objectAtIndex:indexPath.row];
    self.selectedNodesArray = [[NSMutableArray alloc] initWithObjects:node, nil];
    
    UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [node mnz_downloadNodeOverwriting:YES];
        [self setEditing:NO animated:YES];
    }];
    downloadAction.image = [UIImage imageNamed:@"infoDownload"];
    downloadAction.backgroundColor = [UIColor colorWithRed:0 green:0.75 blue:0.65 alpha:1];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[downloadAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    isSwipeEditing = YES;
    MEGANode *node = [self.node.mnz_versions objectAtIndex:indexPath.row];
    self.selectedNodesArray = [[NSMutableArray alloc] initWithObjects:node, nil];
    
    UIContextualAction *revertAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        self.selectedNodesArray = [NSMutableArray arrayWithObject:[self.node.mnz_versions objectAtIndex:indexPath.row]];
        [self revertAction:nil];
        [self setEditing:NO animated:YES];
    }];
    revertAction.image = [UIImage imageNamed:@"history"];
    revertAction.backgroundColor = UIColor.darkGrayColor;
    
    UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        self.selectedNodesArray = [NSMutableArray arrayWithObject:[self.node.mnz_versions objectAtIndex:indexPath.row]];
        [self removeAction:nil];
        [self setEditing:NO animated:YES];
    }];
    removeAction.image = [UIImage imageNamed:@"delete"];
    removeAction.backgroundColor = UIColor.mnz_redF0373A;
    
    return [UISwipeActionsConfiguration configurationWithActions:@[revertAction, removeAction]];
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
            [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
            self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        
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
    self.revertBarButtonItem.enabled = self.selectedNodesArray.count == 1 ? boolValue : NO;
    self.removeBarButtonItem.enabled = boolValue;
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressGestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        
        if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section]) {
            return;
        }
        
        if (self.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedNodesArray.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedNodesArray.count == 1) {
                MEGANode *nodeSelected = self.selectedNodesArray.firstObject;
                MEGANode *nodePressed = [self.node.mnz_versions objectAtIndex:indexPath.row];
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
        MEGARemoveVersionRequestDelegate *removeVersionRD = [[MEGARemoveVersionRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            [self reloadUI];
        }];
        
        for (MEGANode *node in self.selectedNodesArray) {
            [[MEGASdkManager sharedMEGASdk] removeVersionNode:node delegate:removeVersionRD];
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
        
        for (NSInteger i = 0; i < self.node.mnz_numberOfVersions; i++) {
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
    actionController.node = [self.node.mnz_versions objectAtIndex:indexPath.row];
    actionController.displayMode = DisplayModeNodeVersions;
    actionController.actionDelegate = self;
    actionController.actionSender = sender;
    
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
    return !self.isEditing;
}

-(void) swipeTableCellWillBeginSwiping:(nonnull MGSwipeTableCell *) cell {
    NodeTableViewCell *nodeCell = (NodeTableViewCell *)cell;
    [nodeCell hideCancelButton:YES];
}

-(void) swipeTableCellWillEndSwiping:(nonnull MGSwipeTableCell *) cell {
    NodeTableViewCell *nodeCell = (NodeTableViewCell *)cell;
    [nodeCell hideCancelButton:NO];
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
    expansionSettings.fillOnTrigger = NO;
    expansionSettings.threshold = 2;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    MEGANode *node = [self.node.mnz_versions objectAtIndex:indexPath.row];
    self.selectedNodesArray = [[NSMutableArray alloc] initWithObjects:node, nil];
    
    if (direction == MGSwipeDirectionLeftToRight && [[Helper downloadingNodes] objectForKey:node.base64Handle] == nil) {
        
        MGSwipeButton *downloadButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"infoDownload"] backgroundColor:[UIColor colorWithRed:0.0 green:0.75 blue:0.65 alpha:1.0] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
            [node mnz_downloadNodeOverwriting:YES];
            return YES;
        }];
        downloadButton.tintColor = UIColor.whiteColor;
        
        return @[downloadButton];
    } else if (direction == MGSwipeDirectionRightToLeft) {
        
        MGSwipeButton *revertButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"history"] backgroundColor:UIColor.darkGrayColor padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
            self.selectedNodesArray = [NSMutableArray arrayWithObject:[self.node.mnz_versions objectAtIndex:indexPath.row]];
            [self revertAction:nil];
            return YES;
        }];
        revertButton.tintColor = UIColor.whiteColor;
        
        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete"] backgroundColor:UIColor.mnz_redF0373A padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
            self.selectedNodesArray = [NSMutableArray arrayWithObject:[self.node.mnz_versions objectAtIndex:indexPath.row]];
            [self removeAction:nil];
            return YES;
        }];
        deleteButton.tintColor = UIColor.whiteColor;
        
        return @[deleteButton, revertButton];
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
                    [self  reloadUI];
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
