#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class MEGATransfer, MOUploadTransfer, TransferTableViewCellViewModel;

@protocol TransferTableViewCellDelegate

- (void)pauseTransfer:(MEGATransfer *)transfer;
- (void)cancelQueuedUploadTransfer:(NSString *)localIdentifier;

@end

@interface TransferTableViewCell : UITableViewCell

@property (weak, nonatomic) id<TransferTableViewCellDelegate> delegate;
@property (nonatomic, assign) BOOL overquota;
@property (nonatomic, assign) PHImageRequestID imageRequestID;

@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (nonatomic, strong) TransferTableViewCellViewModel *viewModel;

- (void)configureCellForTransfer:(MEGATransfer *)transfer overquota:(BOOL)overquota delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)reconfigureCellWithTransfer:(MEGATransfer *)transfer;
- (void)configureCellForQueuedTransfer:(NSString *)uploadTransferLocalIdentifier delegate:(id<TransferTableViewCellDelegate>)delegate;

- (void)configureCellWithTransferState:(MEGATransferState)transferState;
- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer;
- (void)updateTransferIfNewState:(MEGATransfer *)transfer;
- (IBAction)cancelTransfer:(id)sender;
@end
