
#import "CloudDriveTableViewController.h"

#import "UIImageView+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "MEGANode+MNZCategory.h"

#import "CloudDriveViewController.h"
#import "NodeTableViewCell.h"

@interface CloudDriveTableViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate>

@end

@implementation CloudDriveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)dealloc {
    MEGALogInfo(@"CloudDriveTableViewController deallocated");
}

#pragma mark - Public and Private

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath != nil) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    [self.cloudDrive setViewEditing:editing];
    
    if (editing) {
        for (NodeTableViewCell *cell in [self.tableView visibleCells]) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        for (NodeTableViewCell *cell in [self.tableView visibleCells]) {
            cell.selectedBackgroundView = nil;
        }
    }
}

- (void)tableViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = self.cloudDrive.searchController.isActive ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    
    [self.cloudDrive showCustomActionsForNode:node sender:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.cloudDrive.searchController.isActive) {
            numberOfRows = self.cloudDrive.searchNodesArray.count;
        } else {
            numberOfRows = self.cloudDrive.nodes.size.integerValue;
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = self.cloudDrive.searchController.isActive ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];

    [self.cloudDrive.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
    
    BOOL isDownloaded = NO;
    
    NodeTableViewCell *cell;
    if ([[Helper downloadingNodes] objectForKey:node.base64Handle] != nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"downloadingNodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"downloadingNodeCell"];
        }
        
        [cell.downloadingArrowImageView setImage:[UIImage imageNamed:@"downloadQueued"]];
        if (cell.downloadProgressView.progress != 0) {
            [cell.infoLabel setText:AMLocalizedString(@"paused", @"Paused")];
        } else {
            [cell.infoLabel setText:AMLocalizedString(@"queued", @"Queued")];
        }
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
        }
        
        if (node.type == MEGANodeTypeFile) {
            MOOfflineNode *offlineNode = [[MEGAStore shareInstance] offlineNodeWithNode:node];
            
            if (offlineNode) {
                isDownloaded = YES;
            }
        }
        
        cell.infoLabel.text = [Helper sizeAndDateForNode:node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    if ([node isExported]) {
        if (isDownloaded) {
            [cell.upImageView setImage:[UIImage imageNamed:@"linked"]];
            [cell.middleImageView setImage:nil];
            [cell.downImageView setImage:[Helper downloadedArrowImage]];
        } else {
            [cell.upImageView setImage:nil];
            [cell.middleImageView setImage:[UIImage imageNamed:@"linked"]];
            [cell.downImageView setImage:nil];
        }
    } else {
        [cell.upImageView setImage:nil];
        [cell.downImageView setImage:nil];
        
        if (isDownloaded) {
            [cell.middleImageView setImage:[Helper downloadedArrowImage]];
        } else {
            [cell.middleImageView setImage:nil];
        }
    }
    
    cell.nameLabel.text = [node name];
    
    [cell.thumbnailPlayImageView setHidden:YES];
    
    if ([node type] == MEGANodeTypeFile) {
        if ([node hasThumbnail]) {
            [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
        } else {
            [cell.thumbnailImageView mnz_imageForNode:node];
        }
        
        cell.versionedImageView.hidden = ![[MEGASdkManager sharedMEGASdk] hasVersionsForNode:node];
        
    } else if ([node type] == MEGANodeTypeFolder) {
        [cell.thumbnailImageView mnz_imageForNode:node];
        
        cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
        
        cell.versionedImageView.hidden = YES;
    }
    
    cell.nodeHandle = [node handle];
    
    if (self.tableView.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGANode *n in self.cloudDrive.selectedNodesArray) {
            if ([n handle] == [node handle]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    } else {
        cell.delegate = self;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.cloudDrive.searchController.isActive ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];

    if (tableView.isEditing) {
        [self.cloudDrive.selectedNodesArray addObject:node];
        
        [self.cloudDrive updateNavigationBarTitle];

        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];

        [self.cloudDrive setToolbarActionsEnabled:YES];
        
        if (self.cloudDrive.selectedNodesArray.count == self.cloudDrive.nodes.size.integerValue) {
            self.cloudDrive.allNodesSelected = YES;
        } else {
            self.cloudDrive.allNodesSelected = NO;
        }
        
        return;
    }
    
    switch (node.type) {
        case MEGANodeTypeFolder: {
            CloudDriveViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            [cdvc setParentNode:node];
            
            if (self.cloudDrive.displayMode == DisplayModeRubbishBin) {
                [cdvc setDisplayMode:self.cloudDrive.displayMode];
            }
            
            [self.navigationController pushViewController:cdvc animated:YES];
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                [self.cloudDrive showNode:node];
            } else {
                [node mnz_openNodeInNavigationController:self.cloudDrive.navigationController folderLink:NO];
            }
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.cloudDrive.nodes.size.integerValue) {
        return;
    }
    MEGANode *node = [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = [self.cloudDrive.selectedNodesArray copy];
        for (MEGANode *n in tempArray) {
            if (n.handle == node.handle) {
                [self.cloudDrive.selectedNodesArray removeObject:n];
            }
        }
        
        [self.cloudDrive updateNavigationBarTitle];
        
        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];
        
        if (self.cloudDrive.selectedNodesArray.count == 0) {
            [self.cloudDrive setToolbarActionsEnabled:NO];
        } else {
            if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
                [self.cloudDrive setToolbarActionsEnabled:YES];
            }
        }
        
        self.cloudDrive.allNodesSelected = NO;
        
        return;
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.cloudDrive.searchController.isActive ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    
    if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
        return [UISwipeActionsConfiguration configurationWithActions:@[]];
    }
    
    UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        if ([node mnz_downloadNodeOverwriting:NO]) {
            [self reloadRowAtIndexPath:[self.cloudDrive.nodesIndexPathMutableDictionary objectForKey:node.base64Handle]];
        }
        
        [self setTableViewEditing:NO animated:YES];
    }];
    downloadAction.image = [UIImage imageNamed:@"infoDownload"];
    downloadAction.backgroundColor = [UIColor colorWithRed:0 green:0.75 blue:0.65 alpha:1];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[downloadAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.cloudDrive.searchController.isActive ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) {
        return [UISwipeActionsConfiguration configurationWithActions:@[]];
    }
    
    if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
        MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.restoreHandle];
        if (restoreNode && ![[MEGASdkManager sharedMEGASdk] isNodeInRubbish:restoreNode]) {
            UIContextualAction *restoreAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [node mnz_restore];
                [self setTableViewEditing:NO animated:YES];
            }];
            restoreAction.image = [UIImage imageNamed:@"restore"];
            restoreAction.backgroundColor = [UIColor colorWithRed:0 green:0.75 blue:0.65 alpha:1];
            
            return [UISwipeActionsConfiguration configurationWithActions:@[restoreAction]];
        }
    } else {
        UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[node] sender:[self.tableView cellForRowAtIndexPath:indexPath]];
            [self presentViewController:activityVC animated:YES completion:nil];
            [self setTableViewEditing:NO animated:YES];
        }];
        shareAction.image = [UIImage imageNamed:@"shareGray"];
        shareAction.backgroundColor = [UIColor colorWithRed:1.0 green:0.64 blue:0 alpha:1];
        
        return [UISwipeActionsConfiguration configurationWithActions:@[shareAction]];
    }
    
    return [UISwipeActionsConfiguration configurationWithActions:@[]];
}

#pragma clang diagnostic pop

#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction fromPoint:(CGPoint)point {
    return !self.tableView.isEditing;
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
    MEGANode *node = self.cloudDrive.searchController.isActive ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];

    if (direction == MGSwipeDirectionLeftToRight && [[Helper downloadingNodes] objectForKey:node.base64Handle] == nil) {
        if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
            return nil;
        } else {
            MGSwipeButton *downloadButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"infoDownload"] backgroundColor:[UIColor colorWithRed:0.0 green:0.75 blue:0.65 alpha:1.0] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                [node mnz_downloadNodeOverwriting:NO];
                return YES;
            }];
            [downloadButton iconTintColor:[UIColor whiteColor]];
            
            return @[downloadButton];
        }
    } else if (direction == MGSwipeDirectionRightToLeft) {
        if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) {
            return nil;
        }
        
        if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
            MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.restoreHandle];
            if (restoreNode && ![[MEGASdkManager sharedMEGASdk] isNodeInRubbish:restoreNode]) {
                MGSwipeButton *restoreButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"restore"] backgroundColor:[UIColor colorWithRed:0.0 green:0.75 blue:0.65 alpha:1.0] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                    [node mnz_restore];
                    return YES;
                }];
                [restoreButton iconTintColor:[UIColor whiteColor]];
                
                return @[restoreButton];
            }
        } else {
            MGSwipeButton *shareButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"shareGray"] backgroundColor:[UIColor colorWithRed:1.0 green:0.64 blue:0 alpha:1.0] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[node] sender:[self.tableView cellForRowAtIndexPath:indexPath]];
                [self presentViewController:activityVC animated:YES completion:nil];
                return YES;
            }];
            [shareButton iconTintColor:[UIColor whiteColor]];
            
            return @[shareButton];
        }
    }
    
    return nil;
}

@end
