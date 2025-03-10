#import "LaunchViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class InitialLaunchViewModel;

@interface InitialLaunchViewController : LaunchViewController

@property (nonatomic, strong) InitialLaunchViewModel *viewModel;
@property (nonatomic) BOOL showViews;

- (void)performAnimation;

@end

NS_ASSUME_NONNULL_END
