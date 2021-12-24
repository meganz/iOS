
#import "CloudDriveCollectionViewController.h"

#import "NSString+MNZCategory.h"

#import "MEGANode+MNZCategory.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "CloudDriveViewController.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "MEGA-Swift.h"

@interface CloudDriveCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, NodeCollectionViewCellDelegate>

@property (nonatomic, strong) NSArray<MEGANode *> *fileList;
@property (nonatomic, strong) NSArray<MEGANode *> *folderList;
@property (strong, nonatomic) CHTCollectionViewWaterfallLayout *layout;
@property (strong, nonatomic) DynamicTypeCollectionManager *dtCollectionManager;

@end

@implementation CloudDriveCollectionViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCollectionView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.layout configThumbnailListColumnCount];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {}];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
        [self.dtCollectionManager resetCollectionItems];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

#pragma mark - CollectionView UI Setup

- (void)setupCollectionView {
    self.layout = CHTCollectionViewWaterfallLayout.alloc.init;
    self.layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.layout.minimumColumnSpacing = 8;
    self.layout.minimumInteritemSpacing = 8;
    [self.layout configThumbnailListColumnCount];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"FileNodeCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"NodeCollectionFileID"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"FolderNodeCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"NodeCollectionFolderID"];
    
    self.collectionView.collectionViewLayout = self.layout;
    
    self.dtCollectionManager = [DynamicTypeCollectionManager.alloc initWithDelegate:self];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == ThumbnailSectionFile ? self.fileList.count : self.folderList.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ThumbnailSectionCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self thumbnailNodeAtIndexPath:indexPath];
    NodeCollectionViewCell *cell = indexPath.section == 1 ? [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionFileID" forIndexPath:indexPath] : [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionFolderID" forIndexPath:indexPath];
    [cell configureCellForNode:node allowedMultipleSelection:self.collectionView.allowsMultipleSelection sdk:MEGASdkManager.sharedMEGASdk delegate:self];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView.allowsMultipleSelection) {
        MEGANode *node = [self thumbnailNodeAtIndexPath:indexPath];

        NSArray *filteredArray = [self.cloudDrive.selectedNodesArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return ((MEGANode*)evaluatedObject).handle == node.handle;
        }]];
        
        if ([filteredArray count] != 0) {
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        [cell setSelected:[filteredArray count] != 0];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self thumbnailNodeAtIndexPath:indexPath];
    if (node == nil) {
        return;
    }
    
    if (collectionView.allowsMultipleSelection) {
        
        [self.cloudDrive.selectedNodesArray addObject:node];
        
        [self.cloudDrive updateNavigationBarTitle];
        
        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];
        
        [self.cloudDrive setToolbarActionsEnabled:YES];
        
        self.cloudDrive.allNodesSelected = (self.cloudDrive.selectedNodesArray.count == self.cloudDrive.nodes.size.integerValue);
        
        return;
    } else {
        [collectionView clearSelectedItemsWithAnimated:NO];
    }
    
    [self.cloudDrive didSelectNode:node];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.cloudDrive.nodes.size.integerValue) {
        return;
    }
    
    if (collectionView.allowsMultipleSelection) {
        MEGANode *node = [self thumbnailNodeAtIndexPath:indexPath];

        NSMutableArray *tempArray = [self.cloudDrive.selectedNodesArray copy];
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
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setCollectionViewEditing:YES animated:YES];
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView
    contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath
                                         point:(CGPoint)point {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:^UIViewController * _Nullable {
        if ([node isFolder]) {
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
            [self setCollectionViewEditing:YES animated:YES];
            [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
        }];
        return [UIMenu menuWithTitle:@"" children:@[selectAction]];
    }];
    return configuration;
}

- (void)collectionView:(UICollectionView *)collectionView
willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
              animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    if ([animator.previewViewController isKindOfClass:CloudDriveViewController.class]) {
        CloudDriveViewController *previewViewController = (CloudDriveViewController *)animator.previewViewController;
        [animator addCompletion:^{
            [self.navigationController pushViewController:previewViewController animated:NO];
        }];
    }
    
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dtCollectionManager currentItemSizeFor:indexPath];
}

#pragma mark - NodeCollectionViewCellDelegate

- (void)infoTouchUpInside:(UIButton *)sender {
    if (self.collectionView.allowsMultipleSelection) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonPosition];
    
    MEGANode *node = [self thumbnailNodeAtIndexPath:indexPath];
    if (node == nil) {
        return;
    }
    
    [self.cloudDrive showCustomActionsForNode:node sender:sender];
}

#pragma mark - Public

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated {
    self.collectionView.allowsMultipleSelection = editing;
    
    if (@available(iOS 14.0, *)) {
        self.collectionView.allowsMultipleSelectionDuringEditing = editing;
    }
    
    [self.cloudDrive setViewEditing:editing];
    
    [self.collectionView reloadData];
}

- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)reloadData {
    self.fileList = nil;
    self.folderList = nil;
    [self.collectionView reloadData];
}

- (void)reloadFileItem:(MEGAHandle)nodeHandle {
    [self reloadItem:nodeHandle section:ThumbnailSectionFile];
}

- (void)reloadFolderItem:(MEGAHandle)nodeHandle {
    [self reloadItem:nodeHandle section:ThumbnailSectionFolder];
}

#pragma mark - Private methods

- (nullable MEGANode *)thumbnailNodeAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ThumbnailSectionFile ? [self.fileList objectOrNilAtIndex:indexPath.row] : [self.folderList objectOrNilAtIndex:indexPath.row];
}

- (NSArray *)buildListFor:(FileType) fileOrFolder {
    NSMutableArray *list = NSMutableArray.alloc.init;
    if (self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
        for (MEGANode *tempNode in self.cloudDrive.searchNodesArray) {
            if ((fileOrFolder == FileTypeFile && tempNode.isFile) || (fileOrFolder == FileTypeFolder && tempNode.isFolder)) {
                [list addObject:tempNode];
            }
        }
    } else {
        for (int index = 0; index < [self.cloudDrive.nodes.size intValue]; index++) {
            MEGANode *tempNode = [self.cloudDrive.nodes nodeAtIndex:index];
            if ((fileOrFolder == FileTypeFile && tempNode.isFile) || (fileOrFolder == FileTypeFolder && tempNode.isFolder)) {
                [list addObject:tempNode];
            }
        }
    }
    return list.copy;
}

- (void)reloadItem:(MEGAHandle)nodeHandle section:(ThumbnailSection)section {
    [UIView performWithoutAnimation:^{
        if (nodeHandle) {
            if (self.collectionView.numberOfSections > section) {
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
            }
        }
    }];
}


#pragma mark - getters

- (NSArray *)folderList {
    if (!_folderList) {
        _folderList = [self buildListFor:FileTypeFolder];
    }
    return _folderList;
}

- (NSArray *)fileList {
    if (!_fileList) {
        _fileList = [self buildListFor:FileTypeFile];
    }
    return _fileList;
}

@end
