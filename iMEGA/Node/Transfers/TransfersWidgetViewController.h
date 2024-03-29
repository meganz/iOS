#import <UIKit/UIKit.h>

@class ProgressIndicatorView;

@interface TransfersWidgetViewController : UIViewController

@property (weak, nonatomic, nullable) ProgressIndicatorView *progressView;
@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;

@property (nonatomic, nonnull) NSLayoutConstraint *progressViewWidthConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewHeightConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewBottomConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewLeadingConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewTraillingConstraint;

+ (instancetype _Nonnull)sharedTransferViewController;
- (void)clearNode:(MEGANode *_Nonnull)node;

@end
