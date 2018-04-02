#import "MGSwipeTableCell.h"

@interface SharedItemsTableViewCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *permissionsButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (weak, nonatomic) IBOutlet UIView *lineView;

@property (nonatomic) uint64_t nodeHandle;

@end
