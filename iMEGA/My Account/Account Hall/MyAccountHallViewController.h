NS_ASSUME_NONNULL_BEGIN

@class AccountHallViewModel, MEGALabel;

@interface MyAccountHallViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buyPROBarButtonItem;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *tableFooterView;
@property (weak, nonatomic) IBOutlet UILabel *tableFooterLabel;
@property (weak, nonatomic) IBOutlet MEGALabel *nameLabel;
@property (nonatomic, strong, nullable) MEGANode *backupsRootNode;
@property (nonatomic, assign) BOOL isBackupSectionVisible;
@property (nonatomic, strong) AccountHallViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
