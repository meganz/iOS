#import "ThumbnailViewerTableViewCell.h"

#import "ItemCollectionViewCell.h"

#import "CloudDriveViewController.h"
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGAUser+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGA-Swift.h"
#import "MEGARecentActionBucket+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface ThumbnailViewerTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation ThumbnailViewerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupColors];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumbnailViewerView.hidden = YES;
    
    self.thumbnailViewerCollectionView.dataSource = nil;
    self.thumbnailViewerCollectionView.delegate = nil;
    self.nodesArray = nil;
    [self.thumbnailViewerCollectionView scrollToLeftAnimated:NO];
    [self.thumbnailViewerCollectionView.collectionViewLayout invalidateLayout];
}

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket {
    self.thumbnailImageView.image = [UIImage imageNamed:@"multiplePhotos"];
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    MEGANode *parentNode = [MEGASdk.shared nodeForHandle:recentActionBucket.parentHandle];
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    self.viewModel = [self createViewModelWithNodes:nodesArray];
    
    NSString *imageName = @"standardDisclosureIndicator_designToken";
    
    if (recentActionBucket.mnz_isExpanded) {
        self.indicatorImageView.image = [UIImage imageNamed:imageName].imageByRotateRight90;
        self.thumbnailViewerView.hidden = NO;
        self.thumbnailViewerCollectionView.dataSource = self;
        self.thumbnailViewerCollectionView.delegate = self;
        self.nodesArray = nodesArray;
        [self.thumbnailViewerCollectionView reloadData];
    } else {
        self.indicatorImageView.image = [UIImage imageNamed:imageName];
        self.thumbnailViewerView.hidden = YES;
    }
    
    self.indicatorImageView.tintColor = [self indicatorTintColor];
    
    NSUInteger numberOfPhotos = 0;
    NSUInteger numberOfVideos = 0;
    for (NSUInteger i = 0; i < nodesArray.count; i++) {
        MEGANode *node = [nodesArray objectAtIndex:i];
        if ([FileExtensionGroupOCWrapper verifyIsImage:node.name]) {
            numberOfPhotos++;
        } else if ([FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
            numberOfVideos++;
        }
    }
    
    NSString *title;
    if (numberOfPhotos == 0) {
        NSString *videoCountFormat = LocalizedString(@"recents.section.thumbnail.count.video", @"Multiple videos title shown in recents section of web client.");
        title = [NSString stringWithFormat:videoCountFormat, numberOfVideos];
    } else if (numberOfVideos == 0) {
        NSString *imageCountFormat = LocalizedString(@"recents.section.thumbnail.count.image", @"Multiple Images title shown in recents section of webclient");
        title = [NSString stringWithFormat:imageCountFormat, numberOfPhotos];
    } else {
        NSString *imageCountFormat = LocalizedString(@"recents.section.thumbnail.count.imageAndVideo.image", @"Image count on recents section that will be concatenated with number of videos. e.g 1 image and 1 video, 2 images and 1 video");
        NSString *imageCount = [NSString stringWithFormat:imageCountFormat, numberOfPhotos];
        
        NSString *videoCountFormat = LocalizedString(@"recents.section.thumbnail.count.imageAndVideo.video", @"Video count on recents section that will be concatenated with number of images. e.g 1 image and 1 video, 2 images and 1 video");
        NSString *videoCount = [NSString stringWithFormat:videoCountFormat, numberOfVideos];
        
        title = [NSString stringWithFormat:@"%@ %@", imageCount, videoCount];
    }
    self.nameLabel.text = title;
    
    MEGAShareType shareType = [MEGASdk.shared accessLevelForNode:nodesArray.firstObject];
    if ([recentActionBucket.userEmail isEqualToString:MEGASdk.currentUserEmail]) {
        if (shareType == MEGAShareTypeAccessOwner) {
            MEGANode *firstbornParentNode = [[MEGASdk.shared nodeForHandle:recentActionBucket.parentHandle] mnz_firstbornInShareOrOutShareParentNode];
            if (firstbornParentNode.isOutShare) {
                self.incomingOrOutgoingView.hidden = NO;
                self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_outgoing"];
            } else {
                self.incomingOrOutgoingView.hidden = YES;
            }
        } else {
            self.addedByLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
            self.incomingOrOutgoingView.hidden = NO;
            self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_incoming"];
        }
    } else {
        self.addedByLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
        self.incomingOrOutgoingView.hidden = NO;
        self.incomingOrOutgoingImageView.image = (shareType == MEGAShareTypeAccessOwner) ? [UIImage imageNamed:@"mini_folder_outgoing"] : [UIImage imageNamed:@"mini_folder_incoming"];
    }
    
    self.infoLabel.text = [NSString stringWithFormat:@"%@ ・", parentNode.name];
    
    self.uploadOrVersionImageView.image = recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
    
    self.timeLabel.text = recentActionBucket.timestamp.mnz_formattedHourAndMinutes;
    
    self.infoLabel.textColor = self.timeLabel.textColor = [UIColor mnz_secondaryTextColor];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.nodesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ItemCollectionViewCell *itemCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemCollectionViewCellID" forIndexPath:indexPath];
    
    MEGANode *node = [self.nodesArray objectAtIndex:indexPath.row];
    itemCell.avatarImageView.accessibilityIgnoresInvertColors = YES;
    itemCell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    BOOL isVideoNode = [FileExtensionGroupOCWrapper verifyIsVideo:node.name];
    itemCell.thumbnailPlayImageView.hidden = node.hasThumbnail ? !isVideoNode : YES;
    itemCell.videoDurationLabel.text = isVideoNode ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";
    itemCell.videoOverlayView.hidden = !isVideoNode;
    
    [self configureItemAt:indexPath cell:itemCell];
    
    return itemCell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *photoBrowserVC = [self photosBrowserViewControllerWith:self.nodesArray at:indexPath];
    self.showNodeAction(photoBrowserVC);
}

@end
