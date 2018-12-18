
#import <UIKit/UIKit.h>

#import "OnboardingViewType.h"

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface OnboardingView : UIView

@property (nonatomic) UIView *customView;
@property (nonatomic) OnboardingViewType type;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

NS_ASSUME_NONNULL_END
