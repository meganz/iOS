#import <UIKit/UIKit.h>

@class MEGATransfer, TransferTableViewCellViewModel;

@protocol TransferTableViewCellDelegate

- (void)pauseTransfer:(MEGATransfer *)transfer;

@end

@interface TransferTableViewCell : UITableViewCell

@property (weak, nonatomic) id<TransferTableViewCellDelegate> delegate;
@property (nonatomic, assign) BOOL overquota;

@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (strong, nonatomic) IBOutlet UIButton *pauseButton;

@property (nonatomic, strong) TransferTableViewCellViewModel *viewModel;

- (void)configureCellForTransfer:(MEGATransfer *)transfer overquota:(BOOL)overquota delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate;
- (void)reconfigureCellWithTransfer:(MEGATransfer *)transfer;

- (void)configureCellWithTransferState:(MEGATransferState)transferState;
- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer;
- (void)updateTransferIfNewState:(MEGATransfer *)transfer;
- (IBAction)cancelTransfer:(id)sender;
@end
