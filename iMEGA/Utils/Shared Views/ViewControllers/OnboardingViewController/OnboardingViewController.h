#import <UIKit/UIKit.h>

#import "OnboardingType.h"

NS_ASSUME_NONNULL_BEGIN

@interface OnboardingViewController : UIViewController

+ (OnboardingViewController *)instantiateOnboardingWithType:(OnboardingType)type;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *tertiaryButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;
@property (weak, nonatomic) IBOutlet UIButton *secondaryButton;

@property (nonatomic, copy) void (^completion)(void);

- (void)presentLoginViewController;
- (void)presentCreateAccountViewController;

@end

NS_ASSUME_NONNULL_END
