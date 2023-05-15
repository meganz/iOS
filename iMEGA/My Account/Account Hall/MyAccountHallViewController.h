NS_ASSUME_NONNULL_BEGIN

@class AccountHallViewModel;

@interface MyAccountHallViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buyPROBarButtonItem;
@property (nonatomic, strong, nullable) MEGANode *backupsRootNode;
@property (nonatomic, assign) BOOL isBackupSectionVisible;
@property (nonatomic, strong) AccountHallViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
