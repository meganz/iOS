#import <UIKit/UIKit.h>

@protocol NodeDisplayDelegate <NSObject>

- (void)showSelectedNodeInViewController:(UIViewController *)viewController;

@end

typedef void (^ShowSelectedNodeAction)(UIViewController *);

@class CloudDriveViewController;

@interface ThumbnailViewerTableViewCell : UITableViewCell

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

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket;

@end
