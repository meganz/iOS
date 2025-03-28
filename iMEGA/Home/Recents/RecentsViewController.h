#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RecentNodeActionDelegate <NSObject>

- (void)showCustomActionsForNode:(MEGANode *)node fromSender:(id)sender;

- (void)showSelectedNodeInViewController:(nullable UIViewController *)viewController;

@end

@interface RecentsViewController : UIViewController

@property (nonatomic, weak, nullable) id<RecentNodeActionDelegate> delegate;
@property (nonatomic, copy, nullable) void (^didUpdateMiniPlayerHeight)(CGFloat);

@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *getRecentActionsActivityIndicatorView;

@property (strong, nonatomic) NSArray<MEGARecentActionBucket *> *recentActionBucketArray;

@end

NS_ASSUME_NONNULL_END
