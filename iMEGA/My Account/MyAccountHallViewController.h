NS_ASSUME_NONNULL_BEGIN
@interface MyAccountHallViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong, nullable) MEGANode *myBackupsNode;
@property (nonatomic, assign) BOOL isBackupSectionVisible;

- (void)openOffline;
- (void)openAchievements;

@end
NS_ASSUME_NONNULL_END
