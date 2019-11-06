
#import "OfflineCollectionViewController.h"

#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "MEGASdkManager.h"

#import "NodeCollectionViewCell.h"
#import "OfflineViewController.h"
#import "OpenInActivity.h"

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
    [self.offline setViewEditing:editing];
    
    for (NodeCollectionViewCell *cell in self.collectionView.visibleCells) {
        cell.selectImageView.hidden = !editing;
        cell.selectImageView.image = [UIImage imageNamed:@"checkBoxUnselected"];
    }
}

- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger rows = self.offline.searchController.isActive ? self.offline.searchItemsArray.count : self.offline.offlineSortedItems.count;
    [self.offline enableButtonsByNumberOfItems];
    return rows;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NodeCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionID" forIndexPath:indexPath];
    
    NSString *directoryPathString = [self.offline currentOfflinePath];
    NSString *nameString = [[self.offline itemAtIndexPath:indexPath] objectForKey:kFileName];
    NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:nameString];
    
    cell.nameLabel.text = nameString;
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    NSString *handleString = [offNode base64Handle];
    
    cell.thumbnailPlayImageView.hidden = YES;
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        cell.thumbnailImageView.image = [Helper folderImage];
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
    cell.nameLabel.text = [[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:nameString];
    
    if (self.collectionView.allowsMultipleSelection) {
        cell.selectImageView.hidden = NO;
        BOOL selected = NO;
        for (NSURL *url in self.offline.selectedItems) {
            if ([url.path isEqualToString:pathForItem]) {
                selected = YES;
                [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
        [cell selectCell:selected];
    } else {
        cell.selectImageView.hidden = YES;
    }
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.allowsMultipleSelection) {
        NSURL *filePathURL = [[self.offline itemAtIndexPath:indexPath] objectForKey:kPath];
        [self.offline.selectedItems addObject:filePathURL];
        
        [self.offline updateNavigationBarTitle];
        [self.offline enableButtonsBySelectedItems];
        
        self.offline.allItemsSelected = (self.offline.selectedItems.count == self.offline.offlineSortedItems.count);
        
        NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell selectCell:YES];
        
        return;
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
        
        NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell selectCell:NO];
        
        return;
    }
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
    
    UIAlertController *infoAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [infoAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSString *itemPath = [[self.offline currentOfflinePath] stringByAppendingPathComponent:cell.nameLabel.text];
    
    UIAlertAction *removeItemAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.offline removeOfflineNodeCell:itemPath];
    }];
    [removeItemAction mnz_setTitleTextColor:UIColor.mnz_label];
    [infoAlertController addAction:removeItemAction];
    
    BOOL isDirectory;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
    if (fileExistsAtPath && !isDirectory) {
        UIAlertAction *shareItemAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected ") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
            
            OpenInActivity *openInActivity = [[OpenInActivity alloc] initOnView:self.view];
            [activitiesMutableArray addObject:openInActivity];
            
            NSURL *itemPathURL = [NSURL fileURLWithPath:itemPath];
            
            NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:1];
            [selectedItems addObject:itemPathURL];
            
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:selectedItems applicationActivities:activitiesMutableArray];
            
            [activityViewController setCompletionWithItemsHandler:nil];
                        
            if (UIDevice.currentDevice.iPadDevice) {
                activityViewController.modalPresentationStyle = UIModalPresentationPopover;
                activityViewController.popoverPresentationController.sourceView = sender;
                activityViewController.popoverPresentationController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
            }
            
            [self presentViewController:activityViewController animated:YES completion:nil];
        }];
        
        [shareItemAction mnz_setTitleTextColor:UIColor.mnz_label];
        [infoAlertController addAction:shareItemAction];
    }
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        infoAlertController.modalPresentationStyle = UIModalPresentationPopover;
        infoAlertController.popoverPresentationController.sourceView = sender;
        infoAlertController.popoverPresentationController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
    }
    
    [self presentViewController:infoAlertController animated:YES completion:nil];
}

@end
