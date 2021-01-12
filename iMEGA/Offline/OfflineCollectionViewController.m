
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

#import "MEGA-Swift.h"

static NSString *kFileName = @"kFileName";
static NSString *kPath = @"kPath";

@interface OfflineCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *searchView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewTopConstraint;

@property (assign, nonatomic, getter=isSearchViewVisible) BOOL searchViewVisible;

@end

@implementation OfflineCollectionViewController

#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.searchView addSubview:self.offline.searchController.searchBar];
    self.offline.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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

#pragma mark - Private

- (BOOL)shouldSelectIndexPath:(NSIndexPath * _Nonnull)indexPath {
    NSArray *filteredArray = [self.offline.selectedItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return (NSURL*)evaluatedObject == [[self.offline itemAtIndexPath:indexPath] objectForKey:kPath];
    }]];
    return [filteredArray count] != 0;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger rows = self.offline.searchController.isActive ? self.offline.searchItemsArray.count : self.offline.offlineSortedItems.count;
    [self.offline enableButtonsByNumberOfItems];
    return rows;
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
    
    NodeCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionID" forIndexPath:indexPath];
    
    NSString *directoryPathString = [self.offline currentOfflinePath];
    NSString *nameString = [[self.offline itemAtIndexPath:indexPath] objectForKey:kFileName];
    NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:nameString];
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    
    cell.nameLabel.text = nameString;
    
    NSString *handleString = [offNode base64Handle];
    
    cell.thumbnailPlayImageView.hidden = YES;
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        cell.thumbnailImageView.image = UIImage.mnz_folderImage;
    } else {
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
                if (nameString.mnz_isVideoPathExtension) {
                    cell.thumbnailPlayImageView.hidden = NO;
                }
            }
            
        } else {
            if (nameString.mnz_isImagePathExtension) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                    [[MEGASdkManager sharedMEGASdk] createThumbnail:pathForItem destinatioPath:thumbnailFilePath];
                }
            } else {
                [cell.thumbnailImageView mnz_setImageForExtension:extension];
            }
        }
    
    }
    cell.nameLabel.text = [[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:nameString destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
    
    cell.selectImageView.hidden = !self.collectionView.allowsMultipleSelection;
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.allowsMultipleSelection) {
        [self.offline.selectedItems addObject:[[self.offline itemAtIndexPath:indexPath] objectForKey:kPath]];
        
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
        NSURL *filePathURL = [[self.offline itemAtIndexPath:indexPath] objectForKey:kPath];
        
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

#pragma mark - UIScrolViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isSearchViewVisible) {
        self.searchViewTopConstraint.constant = - scrollView.contentOffset.y;
        if (scrollView.contentOffset.y > 50 && !self.offline.searchController.isActive) { //hide search view when collection offset up is higher than search view height
            self.searchViewVisible = NO;
            self.collectionViewTopConstraint.constant = 0;
        }
    } else {
        if (scrollView.contentOffset.y < 0) { //keep the search view next to collection view offset when scroll down
            self.searchViewTopConstraint.constant = - scrollView.contentOffset.y - 50;
        }
    }
    
    if (self.offline.searchController.isActive) {
        [self.offline.searchController.searchBar resignFirstResponder];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView.contentOffset.y < -50) { //show search view when collection offset down is higher than search view height
        self.searchViewVisible = YES;
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.collectionViewTopConstraint.constant = 50;
            self.collectionView.contentOffset = CGPointMake(0, 0);
            
            [self.view layoutIfNeeded];
        } completion:nil];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.searchViewVisible) {
        if (scrollView.contentOffset.y > 0) {
            if (scrollView.contentOffset.y < 20) { //simulate that search bar is inside collection view and offset items to show search bar and items at top of scroll
                [UIView animateWithDuration:.2 animations:^{
                    self.collectionView.contentOffset = CGPointMake(0, 0);
                    [self.view layoutIfNeeded];
                }];
            } else if (scrollView.contentOffset.y < 50) { //hide search bar when offset collection up between 20 and 50 points of the search view
                self.searchViewVisible = NO;
                [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.collectionViewTopConstraint.constant = 0;
                    self.collectionView.contentOffset = CGPointMake(0, 0);
                    self.searchViewTopConstraint.constant = -50;
                    [self.view layoutIfNeeded];
                } completion:nil];
            }
        }
    } else {
        if (scrollView.contentOffset.y < 0) { //show search bar when drag collection view down
            self.searchViewVisible = YES;
            self.searchViewTopConstraint.constant = 0 - scrollView.contentOffset.y;
            [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.collectionViewTopConstraint.constant = 50;
                [self.view layoutIfNeeded];
            } completion:nil];
        }
    }
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

@end
