
#import "ThumbnailViewerTableViewCell.h"

#import "ItemCollectionViewCell.h"

#import "CloudDriveViewController.h"
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGA-Swift.h"

@interface ThumbnailViewerTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *thumbnailViewerCollectionView;

@end

@implementation ThumbnailViewerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.thumbnailViewerCollectionView.dataSource = self;
    self.thumbnailViewerCollectionView.delegate = self;
    [self updateWithTrait: self.traitCollection];
}

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket {
    self.thumbnailImageView.image = [UIImage imageNamed:@"multiplePhotos"];
    if (@available(iOS 11.0, *)) {
        self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    NSUInteger numberOfPhotos = 0;
    NSUInteger numberOfVideos = 0;
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    for (NSUInteger i = 0; i < nodesArray.count; i++) {
        MEGANode *node = [nodesArray objectAtIndex:i];
        if (node.name.mnz_imagePathExtension) {
            numberOfPhotos++;
        } else if (node.name.mnz_isVideoPathExtension) {
            numberOfVideos++;
        }
    }
    
    NSString *title;
    if (numberOfPhotos == 0) {
        NSString *tempString = AMLocalizedString(@"%2 Videos", @"Multiple videos title shown in recents section of web client.");
        title = [tempString stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%tu", numberOfVideos]];
    } else if (numberOfVideos == 0) {
        NSString *tempString = AMLocalizedString(@"%1 Images", @"Multiple Images title shown in recents section of webclient");
        title = [tempString stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%tu", numberOfPhotos]];
    } else {
        if ((numberOfPhotos == 1) && (numberOfVideos == 1)) {
            title = AMLocalizedString(@"1 Image and 1 Video", @"A single image and single video title shown in recents section of webclient.");
        } else if (numberOfPhotos == 1) {
            NSString *tempString = AMLocalizedString(@"1 Image and %2 Videos", @"One image and multiple videos title in recents.");
            title = [tempString stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%tu", numberOfVideos]];
        } else if (numberOfVideos == 1) {
            NSString *tempString = AMLocalizedString(@"%1 Images and 1 Video", @"Multiple images and 1 video");
            title = [tempString stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%tu", numberOfPhotos]];
        } else {
            NSString *tempString = AMLocalizedString(@"%1 Images and %2 Videos", @"Title for multiple images and multiple videos in recents section");
            tempString = [tempString stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%tu", numberOfPhotos]];
            title = [tempString stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%tu", numberOfVideos]];
        }
    }
    self.nameLabel.text = title;
    
    MEGAShareType shareType = [MEGASdkManager.sharedMEGASdk accessLevelForNode:nodesArray.firstObject];
    if ([recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail]) {
        if (shareType == MEGAShareTypeAccessOwner) {
            MEGANode *firstbornParentNode = [[MEGASdkManager.sharedMEGASdk nodeForHandle:recentActionBucket.parentHandle] mnz_firstbornInShareOrOutShareParentNode];
            if (firstbornParentNode.isOutShare) {
                self.incomingOrOutgoingImageView.hidden = NO;
                self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_outgoing"];
            } else {
                self.incomingOrOutgoingImageView.hidden = YES;
            }
        } else {
            self.addedByLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
            self.incomingOrOutgoingImageView.hidden = NO;
            self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_incoming"];
        }
    } else {
        self.addedByLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
        self.incomingOrOutgoingImageView.hidden = NO;
        self.incomingOrOutgoingImageView.image = (shareType == MEGAShareTypeAccessOwner) ? [UIImage imageNamed:@"mini_folder_outgoing"] : [UIImage imageNamed:@"mini_folder_incoming"];
    }
    
    MEGANode *parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:recentActionBucket.parentHandle];
    self.infoLabel.text = [NSString stringWithFormat:@"%@ ・", parentNode.name];
    
    self.uploadOrVersionImageView.image = recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
    
    self.timeLabel.text = recentActionBucket.timestamp.mnz_formattedHourAndMinutes;
    
    self.infoLabel.textColor = self.timeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    [self.thumbnailViewerCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.nodesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ItemCollectionViewCell *itemCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemCollectionViewCellID" forIndexPath:indexPath];
    
    MEGANode *node  = [self.nodesArray objectAtIndex:indexPath.row];
    [itemCell.avatarImageView mnz_setThumbnailByNode:node];
    if (@available(iOS 11.0, *)) {
        itemCell.avatarImageView.accessibilityIgnoresInvertColors = YES;
        itemCell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    itemCell.thumbnailPlayImageView.hidden = node.hasThumbnail ? !node.name.mnz_isVideoPathExtension : YES;
    itemCell.videoDurationLabel.text = node.name.mnz_isVideoPathExtension ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";
    itemCell.videoOverlayView.hidden = !node.name.mnz_isVideoPathExtension;
    
    return itemCell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:self.nodesArray.mutableCopy api:MEGASdkManager.sharedMEGASdk displayMode:DisplayModeCloudDrive presentingNode:self.nodesArray[indexPath.row] preferredIndex:indexPath.row];

    self.showNodeAction(photoBrowserVC);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateWithTrait:self.traitCollection];
        }
    }
}

- (void)updateWithTrait:(UITraitCollection *)currentTraitCollection {
    self.backgroundColor = [UIColor mnz_backgroundElevated:currentTraitCollection];
    self.thumbnailViewerCollectionView.backgroundColor = [UIColor mnz_backgroundElevated:currentTraitCollection];
}

@end
