
#import "CloudDriveTableViewController.h"

#import "UIImageView+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGANode+MNZCategory.h"

#import "CloudDriveViewController.h"
#import "NodeTableViewCell.h"

@interface CloudDriveTableViewController () <UITableViewDelegate, UITableViewDataSource>
@end

@implementation CloudDriveTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerNibWithName:@"NodeTableViewCell" andReuseIdentifier:@"nodeCell"];
    [self registerNibWithName:@"DownloadingNodeCell" andReuseIdentifier:@"downloadingNodeCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BucketHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BucketHeaderViewID"];

    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.tableHeaderView = UIView.alloc.init;
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.cloudDrive.recentActionBucket) {
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 45;
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

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

- (void)registerNibWithName:(NSString *)nibName andReuseIdentifier:(NSString *)reuseIdentifier {
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
}

- (UIView *)prepareBucketHeaderView {
    BucketHeaderView *bucketHeaderView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BucketHeaderViewID"];
    
    NSString *dateString;
    if (self.cloudDrive.recentActionBucket.timestamp.isToday) {
        dateString = NSLocalizedString(@"Today", @"").localizedUppercaseString;
    } else if (self.cloudDrive.recentActionBucket.timestamp.isYesterday) {
        dateString = NSLocalizedString(@"Yesterday", @"").localizedUppercaseString;
    } else {
        dateString = self.cloudDrive.recentActionBucket.timestamp.mnz_formattedDateMediumStyle;
    }
    
    MEGANode *parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:self.cloudDrive.recentActionBucket.parentHandle];
    bucketHeaderView.parentFolderNameLabel.text = [NSString stringWithFormat:@"%@ •", parentNode.name.uppercaseString];
    bucketHeaderView.uploadOrVersionImageView.image = self.cloudDrive.recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
    bucketHeaderView.dateLabel.text = dateString.uppercaseString;
    
    bucketHeaderView.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    bucketHeaderView.parentFolderNameLabel.textColor = bucketHeaderView.dateLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    
    return bucketHeaderView;
}


#pragma mark - Public

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    [self.cloudDrive setViewEditing:editing];
    
    if (editing) {
        for (NodeTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        for (NodeTableViewCell *cell in self.tableView.visibleCells){
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
    
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    if (node != nil) {
        [self.cloudDrive showCustomActionsForNode:node sender:sender];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
            numberOfRows = self.cloudDrive.searchNodesArray.count;
        } else {
            numberOfRows = self.cloudDrive.nodes.size.integerValue;
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    NodeTableViewCell *cell;
    
    if (node == nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    } else {
        [self.cloudDrive.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
        
        __weak typeof(self) weakself = self;
        cell.moreButtonAction = ^(UIButton * moreButton) {
            [weakself infoTouchUpInside:moreButton];
        };
    }
    
    cell.recentActionBucket = self.cloudDrive.recentActionBucket ?: nil;
    cell.cellFlavor = NodeTableViewCellFlavorCloudDrive;
    [cell configureCellForNode:node api:[MEGASdkManager sharedMEGASdk]];
    
    if (self.tableView.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGANode *tempNode in self.cloudDrive.selectedNodesArray) {
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.cloudDrive.recentActionBucket ? [self prepareBucketHeaderView] : [UIView.alloc initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.cloudDrive.recentActionBucket ? UITableViewAutomaticDimension : 0.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    if (node == nil) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    if (tableView.isEditing) {
        
        for (MEGANode *tempNode in self.cloudDrive.selectedNodesArray) {
            if (tempNode.handle == node.handle) {
                return;
            }
        }
        
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
    
    [self.cloudDrive didSelectNode:node];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.cloudDrive.nodes.size.integerValue) {
        return;
    }
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    
    if (tableView.isEditing) {
        
        NSMutableArray *tempArray = self.cloudDrive.selectedNodesArray.copy;
        for (MEGANode *tempNode in tempArray) {
            if (tempNode.handle == node.handle) {
                [self.cloudDrive.selectedNodesArray removeObject:tempNode];
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

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setTableViewEditing:YES animated:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    if (node == nil || [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) {
        return [UISwipeActionsConfiguration configurationWithActions:@[]];
    }
    
    if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
        MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.restoreHandle];
        if (restoreNode && ![[MEGASdkManager sharedMEGASdk] isNodeInRubbish:restoreNode]) {
            UIContextualAction *restoreAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [node mnz_restore];
                [self setTableViewEditing:NO animated:YES];
            }];
            restoreAction.image = [[UIImage imageNamed:@"restore"] imageWithTintColor:UIColor.whiteColor];
            restoreAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection] ;
            
            return [UISwipeActionsConfiguration configurationWithActions:@[restoreAction]];
        }
    } else {
        UIContextualAction *shareLinkAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            if (MEGAReachabilityManager.isReachableHUDIfNot) {
                [CopyrightWarningViewController presentGetLinkViewControllerForNodes:@[node] inViewController:UIApplication.mnz_presentingViewController];
            }
            [self setTableViewEditing:NO animated:YES];
        }];
        shareLinkAction.image = [[UIImage imageNamed:@"link"] imageWithTintColor:UIColor.whiteColor];
        shareLinkAction.backgroundColor = UIColor.systemOrangeColor;
        
        UIContextualAction *rubbishBinAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self.cloudDrive moveToRubbishBinFor:node];
            [self setTableViewEditing:NO animated:YES];
        }];
        
        rubbishBinAction.image = [[UIImage imageNamed:@"rubbishBin"] imageWithTintColor:UIColor.whiteColor];

        rubbishBinAction.backgroundColor = UIColor.mnz_redError;
        UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            if (node != nil) {
                [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:@[node] presenter:self isFolderLink:NO];
            }
            [self.cloudDrive setEditMode:NO];
        }];
        downloadAction.image = [[UIImage imageNamed:@"offline"] imageWithTintColor:UIColor.whiteColor];
        downloadAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
        
        return [UISwipeActionsConfiguration configurationWithActions:@[rubbishBinAction, shareLinkAction, downloadAction]];
    }
    
    return [UISwipeActionsConfiguration configurationWithActions:@[]];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:^UIViewController * _Nullable {
        if (node.isFolder) {
            CloudDriveViewController *cloudDriveVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = node;
            return cloudDriveVC;
        } else {
            return nil;
        }
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *selectAction = [UIAction actionWithTitle:NSLocalizedString(@"select", nil)
                                                     image:[UIImage imageNamed:@"select"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [self setTableViewEditing:YES animated:YES];
            [self tableView:tableView didSelectRowAtIndexPath:indexPath];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }];
        return [UIMenu menuWithTitle:@"" children:@[selectAction]];
    }];
    return configuration;
}

- (void)tableView:(UITableView *)tableView
willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
         animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    if ([animator.previewViewController isKindOfClass:CloudDriveViewController.class]) {
        CloudDriveViewController *previewViewController = (CloudDriveViewController *)animator.previewViewController;
        [animator addCompletion:^{
            [self.navigationController pushViewController:previewViewController animated:NO];
        }];
    }
}


@end
