
#import "CloudDriveCollectionViewController.h"

#import "NSString+MNZCategory.h"

#import "MEGANode+MNZCategory.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "CloudDriveViewController.h"
#import "NodeCollectionViewCell.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "MEGA-Swift.h"

@interface CloudDriveCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout>

@property (nonatomic, strong) NSArray<MEGANode *> *fileList;
@property (nonatomic, strong) NSArray<MEGANode *> *folderList;
@property (strong, nonatomic) CHTCollectionViewWaterfallLayout *layout;

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
        self.layout.columnCount = [self calculateColumnCount];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {}];
}

#pragma mark - CollectionView UI Setup

- (void)setupCollectionView {
    self.layout = CHTCollectionViewWaterfallLayout.alloc.init;
    self.layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.layout.minimumColumnSpacing = 8;
    self.layout.minimumInteritemSpacing = 8;
    self.layout.columnCount = [self calculateColumnCount];
    
    self.collectionView.collectionViewLayout = self.layout;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == ThumbnailSectionFile ? self.fileList.count : self.folderList.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ThumbnailSectionCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self getNodeAtIndexPath:indexPath];
    NodeCollectionViewCell *cell = indexPath.section == 1 ? [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionFileID" forIndexPath:indexPath] : [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionFolderID" forIndexPath:indexPath];
    [cell configureCellForNode:node api:MEGASdkManager.sharedMEGASdk];
    cell.selectImageView.hidden = !self.collectionView.allowsMultipleSelection;
    cell.moreButton.hidden = self.collectionView.allowsMultipleSelection;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView.allowsMultipleSelection) {
        MEGANode *node = [self getNodeAtIndexPath:indexPath];

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
    MEGANode *node = [self getNodeAtIndexPath:indexPath];
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
        MEGANode *node = [self getNodeAtIndexPath:indexPath];

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

#pragma mark - CHTCollectionViewDelegateWaterfallLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ThumbnailSectionFile ? CGSizeMake(ThumbnailSizeWidth, ThumbnailSizeHeightFile) : CGSizeMake(ThumbnailSizeWidth, ThumbnailSizeHeightFolder);
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.collectionView.allowsMultipleSelection) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonPosition];
    
    MEGANode *node = [self getNodeAtIndexPath:indexPath];
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
    
    [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
}

- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)reloadData {
    self.fileList = nil;
    self.folderList = nil;
    [self.collectionView reloadData];
}

#pragma mark - Private methods

- (nullable MEGANode *)getNodeAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ThumbnailSectionFile ? [self.fileList objectOrNilAtIndex:indexPath.row] : [self.folderList objectOrNilAtIndex:indexPath.row];
}

- (NSInteger)calculateColumnCount {
    CGFloat containerWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    return (NSInteger) ((containerWidth - self.layout.sectionInset.left - self.layout.sectionInset.right) / ThumbnailSizeWidth);
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
