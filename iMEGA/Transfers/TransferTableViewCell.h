#import <UIKit/UIKit.h>

@class MEGATransfer, MOUploadTransfer;

@protocol TransferTableViewCellDelegate

- (void)pauseTransfer:(MEGATransfer *)transfer;
- (void)cancelQueuedUploadTransfer:(NSString *)localIdentifier;

@end

@interface TransferTableViewCell : UITableViewCell

@property (assign, nonatomic) id<TransferTableViewCellDelegate> delegate;

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)reconfigureCellWithTransfer:(MEGATransfer *)transfer;
- (void)configureCellForQueuedTransfer:(MOUploadTransfer *)uploadTransfer delegate:(id<TransferTableViewCellDelegate>)delegate;

- (void)configureCellWithTransferState:(MEGATransferState)transferState;
- (void)reloadThumbnailImage;
- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer;

@end
