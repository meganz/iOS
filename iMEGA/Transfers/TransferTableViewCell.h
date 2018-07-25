#import <UIKit/UIKit.h>

@class MEGATransfer, TransferTableViewCell, PHAsset;

@protocol TransferTableViewCellDelegate

- (void)pauseTransferCell:(TransferTableViewCell *)cell;

@end

@interface TransferTableViewCell : UITableViewCell

@property (assign, nonatomic) id<TransferTableViewCellDelegate> delegate;

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)configureCellForAsset:(PHAsset *)asset delegate:(id<TransferTableViewCellDelegate>)delegate;

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer;

@end
