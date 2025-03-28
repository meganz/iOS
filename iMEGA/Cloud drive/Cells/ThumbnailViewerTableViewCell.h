#import <UIKit/UIKit.h>

@protocol NodeDisplayDelegate <NSObject>

- (void)showSelectedNodeInViewController:(UIViewController *)viewController;

@end

typedef void (^ShowSelectedNodeAction)(UIViewController *);

@class ThumbnailViewerTableViewCellViewModel;

@interface ThumbnailViewerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UICollectionView *thumbnailViewerCollectionView;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *addedByLabel;

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIImageView *incomingOrOutgoingImageView;
@property (weak, nonatomic) IBOutlet UIView *incomingOrOutgoingView;
@property (weak, nonatomic) IBOutlet UIImageView *uploadOrVersionImageView;
@property (weak, nonatomic) IBOutlet UIImageView *indicatorImageView;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIView *disclosureIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *thumbnailViewerView;

@property (strong, nonatomic) NSArray<MEGANode *> *nodesArray;

@property (nonatomic, copy) ShowSelectedNodeAction showNodeAction;

@property (strong, nonatomic) ThumbnailViewerTableViewCellViewModel *viewModel;
@property (strong, nonatomic) NSSet<id> *cancellables;

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket;

@end
