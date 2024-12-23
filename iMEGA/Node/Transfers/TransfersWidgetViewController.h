#import <UIKit/UIKit.h>

@class ProgressIndicatorView, TransfersWidgetViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface TransfersWidgetViewController : UIViewController

@property (weak, nonatomic, nullable) ProgressIndicatorView *progressView;
@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray<NSString *> *queuedUploadTransfers;
@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *transfers;
@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *completedTransfers;

@property (nonatomic, nonnull) NSLayoutConstraint *progressViewWidthConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewHeightConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewBottomConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewLeadingConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewTraillingConstraint;

@property (strong, nonatomic) TransfersWidgetViewModel *viewModel;

+ (instancetype)sharedTransferViewController;
- (void)clearNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
