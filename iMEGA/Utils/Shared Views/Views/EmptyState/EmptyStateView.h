
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmptyStateView : UIView

@property (nullable, weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nullable, weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nullable, weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (nullable, weak, nonatomic) IBOutlet UIButton *descriptionButton;
@property (nullable, weak, nonatomic) IBOutlet UIButton *button;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;

- (UIView *)initWithImage:(nullable UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle;
- (UIView *)initForHomeWithImage:(nullable UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle;
- (UIView *)initForTimelineWithImage:(nullable UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle;
- (void)enableTimelineLayoutConstraint;

@end

NS_ASSUME_NONNULL_END
