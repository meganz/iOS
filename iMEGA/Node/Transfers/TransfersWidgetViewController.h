#import <UIKit/UIKit.h>

@class ProgressIndicatorView;

@interface TransfersWidgetViewController : UIViewController

@property (weak, nonatomic, nullable) ProgressIndicatorView *progressView;

@property (nonatomic, nonnull) NSLayoutConstraint *progressViewWidthConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewHeightConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewBottomConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewLeadingConstraint;
@property (nonatomic, nonnull) NSLayoutConstraint *progressViewTraillingConstraint;

+ (instancetype _Nonnull)sharedTransferViewController;

@end
