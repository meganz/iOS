#import "MGSwipeTableCell.h"

@interface NodeTableViewCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UIImageView *upImageView;
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *downImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *downloadingArrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalLineLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonTrailingConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;

@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (weak, nonatomic) IBOutlet UIView *lineView;

@property (nonatomic) uint64_t nodeHandle;
@property (strong, nonatomic) MEGANode *node;

- (void)hideCancelButton:(BOOL)hide;
- (void)configureCellForNode:(MEGANode *)node delegate:(id<MGSwipeTableCellDelegate>)delegate;

@end
