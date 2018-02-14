#import "MGSwipeTableCell.h"
#import "CustomEditCellDelegate.h"

@interface OfflineTableViewCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (strong, nonatomic) NSString *itemNameString;

@property (nonatomic, assign) id <CustomEditCellDelegate> customEditDelegate;

@property (assign, nonatomic) BOOL isSwiping;

@end
