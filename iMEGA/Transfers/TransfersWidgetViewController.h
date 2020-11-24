#import <UIKit/UIKit.h>

@class ProgressIndicatorView;

@interface TransfersWidgetViewController : UIViewController

@property (weak, nonatomic, nullable) ProgressIndicatorView *progressView;
+ (instancetype _Nonnull)sharedTransferViewController;

@end
