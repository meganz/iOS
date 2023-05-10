NS_ASSUME_NONNULL_BEGIN
@interface MyAccountHallViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buyPROBarButtonItem;
@property (nonatomic, strong, nullable) MEGANode *backupsRootNode;
@property (nonatomic, assign) BOOL isBackupSectionVisible;

@end
NS_ASSUME_NONNULL_END
