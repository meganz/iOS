#import "MGSwipeTableCell.h"

@interface NodeTableViewCell : MGSwipeTableCell


@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *linkImageView;

@property (weak, nonatomic) IBOutlet UIImageView *downloadingArrowImageView;

@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIImageView *incomingOrOutgoingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *uploadOrVersionImageView;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;

@property (weak, nonatomic) IBOutlet UIView *disclosureIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *separatorView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonTrailingConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;

@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (weak, nonatomic) IBOutlet UIImageView *versionedImageView;

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) MEGARecentActionBucket *recentActionBucket;

- (void)configureCellForNode:(MEGANode *)node delegate:(id<MGSwipeTableCellDelegate>)delegate api:(MEGASdk *)api;

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket;

@end
