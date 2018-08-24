#import <UIKit/UIKit.h>

@class MEGATransfer, TransferTableViewCell, QueuedTransferItem;

@protocol TransferTableViewCellDelegate

- (void)pauseTransferCell:(TransferTableViewCell *)cell;

@end

@interface TransferTableViewCell : UITableViewCell

@property (assign, nonatomic) id<TransferTableViewCellDelegate> delegate;

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)configureCellForQueuedTransfer:(QueuedTransferItem *)queuedTransferItem delegate:(id<TransferTableViewCellDelegate>)delegate;

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer;

@end
