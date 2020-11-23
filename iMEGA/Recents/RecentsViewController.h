
#import <UIKit/UIKit.h>

@class CloudDriveViewController;

@protocol RecentNodeActionDelegate <NSObject>

- (void)showCustomActionsForNode:(MEGANode *)node fromSender:(id)sender;

- (void)showSelectedNodeInViewController:(UIViewController *)viewController;

@end

@interface RecentsViewController : UIViewController

@property (nonatomic, weak) CloudDriveViewController *cloudDrive;

@property (nonatomic, weak) id<RecentNodeActionDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end
