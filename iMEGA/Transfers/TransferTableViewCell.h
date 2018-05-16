#import <UIKit/UIKit.h>

@class MEGATransfer, TransferTableViewCell;

@protocol TransferTableViewCellDelegate

- (void)pauseTransferCell:(TransferTableViewCell *)cell;

@end

@interface TransferTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentageLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;

@property (weak, nonatomic) IBOutlet UIView *lineView;

@property (assign, nonatomic) id<TransferTableViewCellDelegate> delegate;

@property (strong, nonatomic) MEGATransfer *transfer;

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate;

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer;

@end
