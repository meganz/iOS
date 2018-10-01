
#import "LaunchViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol InitialLaunchViewControllerDelegate <NSObject>

- (void)setupFinished;

@end

@interface InitialLaunchViewController : LaunchViewController

@property (nonatomic, weak) id<InitialLaunchViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
