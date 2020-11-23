#import <UIKit/UIKit.h>

@class ProgressIndicatorView;

@interface TransfersWidgetViewController : UIViewController

@property (weak, nonatomic) ProgressIndicatorView *progressView;
+ (instancetype)sharedTransferViewController;

@end
