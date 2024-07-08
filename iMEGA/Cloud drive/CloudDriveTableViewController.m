#import "CloudDriveTableViewController.h"

#import "UIImageView+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "MEGANode+MNZCategory.h"

#import "CloudDriveViewController.h"
#import "NodeTableViewCell.h"

@import MEGAFoundation;
@import MEGAL10nObjc;

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
    self.tableView.separatorColor = self.tableViewSeparatorColor;
}

- (void)registerNibWithName:(NSString *)nibName andReuseIdentifier:(NSString *)reuseIdentifier {
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
}

- (UIView *)prepareBucketHeaderView {
    BucketHeaderView *bucketHeaderView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BucketHeaderViewID"];
    
    NSString *dateString;
    if (self.cloudDrive.recentActionBucket.timestamp.isToday) {
        dateString = LocalizedString(@"Today", @"");
    } else if (self.cloudDrive.recentActionBucket.timestamp.isYesterday) {
        dateString = LocalizedString(@"Yesterday", @"");
    } else {
        dateString = self.cloudDrive.recentActionBucket.timestamp.mnz_formattedDateMediumStyle;
    }
    
    MEGANode *parentNode = [MEGASdk.shared nodeForHandle:self.cloudDrive.recentActionBucket.parentHandle];
    bucketHeaderView.parentFolderNameLabel.text = [NSString stringWithFormat:@"%@ •", parentNode.name.uppercaseString];
    bucketHeaderView.uploadOrVersionImageView.image = self.cloudDrive.recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
    bucketHeaderView.dateLabel.text = dateString.uppercaseString;
    
    bucketHeaderView.backgroundColor = [self bucketHeaderViewBackgroundColor];
    bucketHeaderView.parentFolderNameLabel.textColor
    = bucketHeaderView.dateLabel.textColor
    = self.bucketHeaderViewTextColor;

    return bucketHeaderView;
}


#pragma mark - Public

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
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
            numberOfRows = self.cloudDrive.nodes.size;
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
    [cell configureCellForNode:node
 shouldApplySensitiveBehaviour:!self.cloudDrive.isFromSharedItem
                           api:MEGASdk.shared];
    
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
        
        [self.cloudDrive toolbarActionsWithNodeArray:self.cloudDrive.selectedNodesArray];
        
        [self.cloudDrive setToolbarActionsEnabled:YES];
        
        if (self.cloudDrive.selectedNodesArray.count == self.cloudDrive.nodes.size) {
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
    if (indexPath.row > self.cloudDrive.nodes.size) {
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
        
        [self.cloudDrive toolbarActionsWithNodeArray:self.cloudDrive.selectedNodesArray];
        
        if (self.cloudDrive.selectedNodesArray.count == 0) {
            [self.cloudDrive setToolbarActionsEnabled:NO];
        } else {
            [self.cloudDrive setToolbarActionsEnabled:YES];
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
    return [self configureSwipeActionsForIndex:indexPath];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:^UIViewController * _Nullable {
        if (node.isFolder) {
            // not replacing this with CloudDriveViewController factory as this is used inside
            // legacy CloudDriveViewControlle
            CloudDriveViewController *cloudDriveVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = node;
            return cloudDriveVC;
        } else {
            return nil;
        }
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *selectAction = [UIAction actionWithTitle:LocalizedString(@"select", @"")
                                                     image:[UIImage imageNamed:@"select"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            
            if(!self.isEditing) {
                [self.cloudDrive toggleWithEditModeActive:YES];
            }
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
