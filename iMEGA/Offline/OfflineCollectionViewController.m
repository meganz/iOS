
#import "OfflineCollectionViewController.h"

#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "MEGASdkManager.h"

#import "NodeCollectionViewCell.h"
#import "OfflineViewController.h"
#import "OpenInActivity.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "MEGA-Swift.h"

static NSString *kFileName = @"kFileName";
static NSString *kFileSize = @"kFileSize";
static NSString *kDuration = @"kDuration";
static NSString *kPath = @"kPath";

@interface OfflineCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout>
@property (nonatomic, strong) NSArray *fileList;
@property (nonatomic, strong) NSArray *folderList;
@property (strong, nonatomic) CHTCollectionViewWaterfallLayout *layout;

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

#pragma mark - Public

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated {
    self.collectionView.allowsMultipleSelection = editing;
    
    if (@available(iOS 14.0, *)) {
        self.collectionView.allowsMultipleSelectionDuringEditing = editing;
    }
    
    [self.offline setViewEditing:editing];
    
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    [self.offline enableButtonsByNumberOfItems];
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
    NSString *nameString = item[kFileName];
    NSString *pathForItem = [[self.offline currentOfflinePath] stringByAppendingPathComponent:nameString];
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    
    cell.nameLabel.text = nameString;
    
    NSString *handleString = [offNode base64Handle];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        cell.thumbnailIconView.image = UIImage.mnz_folderImage;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^(void){
            // heavy non-UI work
            FolderContentStat *folderContentStat = [[NSFileManager defaultManager] mnz_folderContentStatWithPathForItem:pathForItem];
            NSInteger files = folderContentStat.fileCount;
            NSInteger folders = folderContentStat.folderCount;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                // update UI
                cell.infoLabel.text = [NSString mnz_stringByFiles:files andFolders:folders];
            });
        });
    } else {
        cell.infoLabel.text = [Helper memoryStyleStringFromByteCount:[item[kFileSize] longLongValue]];
        NSString *extension = nameString.pathExtension.lowercaseString;
        
        if (!handleString) {
            NSString *fpLocal = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:pathForItem];
            if (fpLocal) {
                MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fpLocal];
                if (node) {
                    handleString = node.base64Handle;
                    [[MEGAStore shareInstance] insertOfflineNode:node api:[MEGASdkManager sharedMEGASdk] path:[[Helper pathRelativeToOfflineDirectory:pathForItem] decomposedStringWithCanonicalMapping]];
                }
            }
        }
        
        NSString *thumbnailFilePath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
        thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath] && handleString) {
            UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
            if (thumbnailImage) {
                cell.thumbnailImageView.image = thumbnailImage;
            }
            cell.thumbnailIconView.hidden = YES;
        } else {
            if (nameString.mnz_isImagePathExtension) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                    [[MEGASdkManager sharedMEGASdk] createThumbnail:pathForItem destinatioPath:thumbnailFilePath];
                }
                cell.thumbnailIconView.hidden = YES;
            } else {
                cell.thumbnailIconView.hidden = NO;
                [cell.thumbnailIconView mnz_setImageForExtension:extension];
                cell.thumbnailImageView.image = nil;
            }
        }
    
    }
    cell.nameLabel.text = [[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:nameString destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
    
    cell.selectImageView.hidden = !self.collectionView.allowsMultipleSelection;
    cell.moreButton.hidden = self.collectionView.allowsMultipleSelection;
    cell.durationLabel.hidden = !nameString.mnz_isVideoPathExtension;
    if (!cell.durationLabel.hidden) {
        cell.durationLabel.layer.cornerRadius = 4;
        cell.durationLabel.layer.masksToBounds = true;
        cell.durationLabel.text = nameString.mnz_isVideoPathExtension ? [NSString mnz_stringFromTimeInterval:[item[kDuration] doubleValue]] : @"";
    }

    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    }
    [cell setupAppearance];
    
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
    [self.offline itemTapped:cell.nameLabel.text atIndexPath:indexPath];
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
    
    NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSString *itemPath = [[self.offline currentOfflinePath] stringByAppendingPathComponent:cell.nameLabel.text];
    
    [self.offline showInfoFilePath:itemPath at:indexPath from:sender];
}

#pragma mark - Private

- (BOOL)shouldSelectIndexPath:(NSIndexPath * _Nonnull)indexPath {
    NSArray *filteredArray = [self.offline.selectedItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return (NSURL*)evaluatedObject == [[self getItemAtIndexPath:indexPath] objectForKey:kPath];
    }]];
    return [filteredArray count] != 0;
}

- (nullable NSDictionary *)getItemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ThumbnailSectionFile ? [self.fileList objectOrNilAtIndex:indexPath.row] : [self.folderList objectOrNilAtIndex:indexPath.row];
}

- (NSInteger)calculateColumnCount {
    CGFloat containerWidth = CGRectGetWidth(UIScreen.mainScreen.bounds) - self.layout.sectionInset.left - self.layout.sectionInset.right;
    if (@available(iOS 11.0, *)) {
        containerWidth = containerWidth - UIApplication.sharedApplication.keyWindow.safeAreaInsets.left - UIApplication.sharedApplication.keyWindow.safeAreaInsets.right;
    }
    NSInteger columns = ((containerWidth) / ThumbnailSizeWidth);

    return MAX(2, columns);
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
