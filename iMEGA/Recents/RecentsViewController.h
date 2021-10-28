
#import <UIKit/UIKit.h>

@class CloudDriveViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol RecentNodeActionDelegate <NSObject>

- (void)showCustomActionsForNode:(MEGANode *)node fromSender:(id)sender;

- (void)showSelectedNodeInViewController:(nullable UIViewController *)viewController;

@end

@interface RecentsViewController : UIViewController

@property (nonatomic, weak, nullable) CloudDriveViewController *cloudDrive;

@property (nonatomic, weak, nullable) id<RecentNodeActionDelegate> delegate;

@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;


@end

NS_ASSUME_NONNULL_END
