#import "OfflineCollectionViewController.h"

#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"

#import "NodeCollectionViewCell.h"
#import "OfflineViewController.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"

@import MEGAUIKit;

static NSString *kFileName = @"kFileName";
static NSString *kPath = @"kPath";

@interface OfflineCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, NodeCollectionViewCellDelegate>
@property (nonatomic, strong) NSArray *fileList;
@property (nonatomic, strong) NSArray *folderList;
@property (strong, nonatomic) CHTCollectionViewWaterfallLayout *layout;
@property (strong, nonatomic) DynamicTypeCollectionManager *dtCollectionManager;

@end

@implementation OfflineCollectionViewController

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

#pragma mark - Public

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated {
    self.collectionView.allowsMultipleSelection = editing;
    
    self.collectionView.allowsMultipleSelectionDuringEditing = editing;
    
    [self.offline setViewEditing:editing];
    
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == ThumbnailSectionFile ? [self.fileList count] : [self.folderList count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ThumbnailSectionCount;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView.allowsMultipleSelection) {
        BOOL shouldSelectActualCell = [self shouldSelectIndexPath:indexPath];
        
        if (shouldSelectActualCell) {
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        [cell setSelected:shouldSelectActualCell];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NodeCollectionViewCell *cell = indexPath.section == ThumbnailSectionFile ? [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionFileID" forIndexPath:indexPath] : [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionFolderID" forIndexPath:indexPath];
   
    NSDictionary *item = [self getItemAtIndexPath:indexPath];
    [cell configureCellForOfflineItem:item itemPath:[[self.offline currentOfflinePath] stringByAppendingPathComponent:item[kFileName]] allowedMultipleSelection:self.collectionView.allowsMultipleSelection sdk:MEGASdk.shared delegate: self];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.allowsMultipleSelection) {
        [self.offline.selectedItems addObject:[[self getItemAtIndexPath:indexPath] objectForKey:kPath]];
        
        [self.offline updateNavigationBarTitle];
        [self.offline enableButtonsBySelectedItems];
        
        self.offline.allItemsSelected = (self.offline.selectedItems.count == self.offline.offlineSortedItems.count);
        
        return;
    } else {
        [collectionView clearSelectedItemsWithAnimated:NO];
    }
    
    NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self.offline itemTapped:cell.itemName atIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.allowsMultipleSelection) {
        NSURL *filePathURL = [self getItemAtIndexPath:indexPath][kPath];
        
        NSMutableArray *tempArray = self.offline.selectedItems.copy;
        for (NSURL *url in tempArray) {
            if ([url.filePathURL isEqual:filePathURL]) {
                [self.offline.selectedItems removeObject:url];
            }
        }
        
        [self.offline updateNavigationBarTitle];
        [self.offline enableButtonsBySelectedItems];
        
        self.offline.allItemsSelected = NO;
        
        return;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return self.offline.flavor == AccountScreen;
}

- (void)collectionView:(UICollectionView *)collectionView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setCollectionViewEditing:YES animated:YES];
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView
  contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                         point:(CGPoint)point {
    if (self.offline.flavor != AccountScreen || indexPaths.count == 0) return nil;
    
    NSIndexPath *indexPath = indexPaths.firstObject;
    NSString *path = [[self.offline currentOfflinePath] stringByAppendingPathComponent:[self getItemAtIndexPath:indexPath][kFileName]];
    
    return [self collectionView:collectionView contextMenuConfigurationForItemAt:indexPath itemPath:path];
}

- (void)collectionView:(UICollectionView *)collectionView
willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
              animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    [self willPerformPreviewActionForMenuWithAnimator:animator];
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dtCollectionManager currentItemSizeFor:indexPath];
}

#pragma mark - NodeCollectionViewCell

- (void)showMoreMenuForNode:(MEGANode *)node from:(UIButton *)sender {
    if (self.collectionView.allowsMultipleSelection) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonPosition];
    
    NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSString *itemPath = [[self.offline currentOfflinePath] stringByAppendingPathComponent:cell.itemName];
    
    [self.offline showInfoFilePath:itemPath at:indexPath from:sender];
}

#pragma mark - Private

- (BOOL)shouldSelectIndexPath:(NSIndexPath * _Nonnull)indexPath {
    NSURL *itemURL = [self getItemAtIndexPath:indexPath][kPath];
    for (NSURL *selectedURL in self.offline.selectedItems) {
        if ([selectedURL isEqual:itemURL]) {
            return YES;
        }
    }
    return NO;
}

- (nullable NSDictionary *)getItemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ThumbnailSectionFile ? [self.fileList objectOrNilAtIndex:indexPath.row] : [self.folderList objectOrNilAtIndex:indexPath.row];
}

- (NSArray *)buildListFor:(FileType) fileOrFolder {
    NSMutableArray *list = NSMutableArray.alloc.init;
    NSArray *items = self.offline.searchController.isActive ? self.offline.searchItemsArray : self.offline.offlineSortedItems;
    NSString *directoryPathString = [self.offline currentOfflinePath];
    for (NSDictionary *tempItem in items) {
        NSString *nameString = tempItem[kFileName];
        NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:nameString];
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
        if ((fileOrFolder == FileTypeFile && !isDirectory) || (fileOrFolder == FileTypeFolder && isDirectory)) {
            [list addObject:tempItem];
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
