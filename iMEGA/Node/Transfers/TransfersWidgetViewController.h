#import <UIKit/UIKit.h>

@class TransfersWidgetViewModel, TransferInventoryUseCaseHelper;

NS_ASSUME_NONNULL_BEGIN

@interface TransfersWidgetViewController : UIViewController

@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;
@property (weak, nonatomic, nullable) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *transfers;
@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *completedTransfers;

@property (strong, nonatomic) TransfersWidgetViewModel *viewModel;
@property (strong, nonatomic) TransferInventoryUseCaseHelper *transferInventoryUseCaseHelper;

+ (instancetype)sharedTransferViewController;
- (void)clearNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
