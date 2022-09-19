
@interface MyAccountHallViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL isBackupSectionVisible;

- (void)openOffline;
- (void)openAchievements;

@end
