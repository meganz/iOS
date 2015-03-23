/**
 * @file PhotosViewController.m
 * @brief View controller that show your photos upload to Camera Uploads folder
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "PhotosViewController.h"
#import "PhotoCollectionViewCell.h"
#import "HeaderCollectionReusableView.h"
#import "Helper.h"
#import "MEGAPreview.h"
#import "SVProgressHUD.h"
#import "CameraUploads.h"

@interface PhotosViewController ()

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;
@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;
@property (nonatomic, strong) NSMutableArray *previewsArray;

@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (weak, nonatomic) IBOutlet UIView *uploadProgressView;
@property (weak, nonatomic) IBOutlet UILabel *photoNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *transferredBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalBytesLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadProgressViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photosCollectionViewTopLayoutConstraint;

@end

@implementation PhotosViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [self reloadUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods

- (void)reloadUI {
    NSMutableDictionary *photosByMonthYearDictionary = [NSMutableDictionary new];
    
    self.photosByMonthYearArray = [NSMutableArray new];
    NSMutableArray *photosArray = [NSMutableArray new];
    
    self.parentNode = [[MEGASdkManager sharedMEGASdk] childNodeForParent:[[MEGASdkManager sharedMEGASdk] rootNode] name:@"Camera Uploads"];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode order:MEGASortOrderTypeModificationDesc];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMMM yyyy"];
    
    for (NSInteger i = 0; i < [self.nodeList.size integerValue]; i++) {
        MEGANode *node = [self.nodeList nodeAtIndex:i];
        
        if (!isImage([node name].lowercaseString.pathExtension)) {
            continue;
        }
        
        NSString *currentMonthYearString = [df stringFromDate:[node modificationTime]];
        
        if (![photosByMonthYearDictionary objectForKey:currentMonthYearString]) {
            photosByMonthYearDictionary = [NSMutableDictionary new];
            photosArray = [NSMutableArray new];
            [photosArray addObject:node];
            [photosByMonthYearDictionary setObject:photosArray forKey:currentMonthYearString];
            [self.photosByMonthYearArray addObject:photosByMonthYearDictionary];
            
        } else {
            [photosArray addObject:node];
        }
    }
    
    [self.navigationItem setTitle:NSLocalizedString(@"photosTitle", @"Photos")];
    
    [self.photosCollectionView reloadData];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        
        MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
        NSInteger transferListSize = [[transferList size] integerValue];
        
        for (NSInteger i = 0; i < transferListSize; i++) {
            
            MEGATransfer *transfer = [transferList transferAtIndex:i];
            
            if (([transfer type] == MEGATransferTypeUpload) && (self.uploadProgressViewTopLayoutConstraint != 0)) {
                [self showProgressView];
            }
        }
    } else {
        
        self.uploadProgressViewTopLayoutConstraint.constant = -60;
        self.photosCollectionViewTopLayoutConstraint.constant = 0;
    }
}

- (void)showProgressView {
    [UIView animateWithDuration:1 animations:^{
        self.uploadProgressViewTopLayoutConstraint.constant = 0;
        self.photosCollectionViewTopLayoutConstraint.constant = 60;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)hideProgressView {
    [UIView animateWithDuration:1 animations:^{
        self.uploadProgressViewTopLayoutConstraint.constant = -60;
        self.photosCollectionViewTopLayoutConstraint.constant = 0;
        
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UICollectioViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.photosByMonthYearArray count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:section];
    NSString *key = [[dict allKeys] objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    
    return [array count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"photoCellId";
    
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    MEGANode *node = nil;
    
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *key = [[dict allKeys] objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    
    node = [array objectAtIndex:indexPath.row];
    
    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
    
    if (!fileExists && [node hasThumbnail]) {
        [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:self];
    }
    
    if (!fileExists) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    } else {
        [cell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
    }
    
    cell.nodeHandle = [node handle];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        static NSString *headerIdentifier = @"photoHeaderId";
        
        HeaderCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier forIndexPath:indexPath];
        
        if (!header) {
            header = [[HeaderCollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 40)];
        }
        
        
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
        NSString *month = [[dict allKeys] objectAtIndex:0];
        
        NSString *photosPerMonth = nil;
        NSInteger numberPhotosPerMonth = [[dict objectForKey:month] count];
        if ( numberPhotosPerMonth > 1) {
            photosPerMonth = [NSString stringWithFormat:NSLocalizedString(@"photosPerMonth", @"Number of photos by section"), numberPhotosPerMonth];
        } else {
            photosPerMonth = [NSString stringWithFormat:NSLocalizedString(@"photoPerMonth", @"Number of photos by section"), numberPhotosPerMonth];
        }
        
        NSString *sectionText = [NSString stringWithFormat:@"%@ (%@)", month, photosPerMonth];
        
        [header.dateLabel setText:sectionText];
        
        return header;
    } else {
        return nil;
    }
}

#pragma mark - UICollectioViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.previewsArray = [NSMutableArray new];
    
    for (NSInteger i = 0; i < [[self.nodeList size] integerValue]; i++) {
        MEGANode *n = [self.nodeList nodeAtIndex:i];
        MEGAPreview *preview = [MEGAPreview photoWithNode:n];
        preview.caption = [n name];
        [self.previewsArray addObject:preview];
    }
    
    // Get the index of the array using the indexPath
    NSInteger index = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:i];
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *array = [dict objectForKey:key];
        index += array.count;
    }
    
    index += indexPath.row;
    
    MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    photoBrowser.displayActionButton = YES;
    photoBrowser.displayNavArrows = YES;
    photoBrowser.displaySelectionButtons = NO;
    photoBrowser.zoomPhotosToFill = YES;
    photoBrowser.alwaysShowControls = NO;
    photoBrowser.enableGrid = YES;
    photoBrowser.startOnGrid = NO;
    
    // Optionally set the current visible photo before displaying
    //    [browser setCurrentPhotoIndex:1];
    
    [self.navigationController pushViewController:photoBrowser animated:YES];
    
    [photoBrowser showNextPhotoAnimated:YES];
    [photoBrowser showPreviousPhotoAnimated:YES];
    [photoBrowser setCurrentPhotoIndex:index];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.previewsArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.previewsArray.count) {
        return [self.previewsArray objectAtIndex:index];
    }
    
    return nil;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrFile: {
            for (PhotoCollectionViewCell *pcvc in [self.photosCollectionView visibleCells]) {
                if ([request nodeHandle] == [pcvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [pcvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (self.uploadProgressViewTopLayoutConstraint.constant == -60) {
        [self showProgressView];
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        [self.photoNameLabel setText:[transfer fileName]];
        float percentage = [[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue];
        [self.transferredBytesLabel setText:[NSByteCountFormatter stringFromByteCount:[[transfer transferredBytes] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        [self.totalBytesLabel setText:[NSByteCountFormatter stringFromByteCount:[[transfer totalBytes] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        [self.speedLabel setText:[NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]]];
        [self.progressView setProgress:percentage];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([[[CameraUploads syncManager] assetUploadArray] count] == 1) {
        [self hideProgressView];
    }
}

@end
