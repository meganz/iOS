#import <UIKit/UIKit.h>

@class NodeTableViewCell;

@protocol NodeTableViewCellDelegate

@optional

@property (nonatomic, readonly, getter=isPseudoEditing) BOOL pseudoEdit;
- (void)selectCell:(NodeTableViewCell *)cell;

@end

@interface NodeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *upImageView;
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *downImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *downloadingArrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalLineLayoutConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;

@property (nonatomic) uint64_t nodeHandle;

@property (nonatomic, assign) id <NodeTableViewCellDelegate> customEditDelegate;

@end
