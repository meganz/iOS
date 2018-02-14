#import "MGSwipeTableCell.h"
#import "CustomEditCellDelegate.h"

@interface SharedItemsTableViewCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *permissionsButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (nonatomic) uint64_t nodeHandle;

@property (nonatomic, assign) id <CustomEditCellDelegate> customEditDelegate;

@property (assign, nonatomic) BOOL isSwiping;

@end
