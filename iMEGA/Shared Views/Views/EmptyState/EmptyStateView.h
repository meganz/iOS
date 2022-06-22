
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmptyStateView : UIView

@property (nullable, weak, nonatomic) IBOutlet UIButton *descriptionButton;
@property (nullable, weak, nonatomic) IBOutlet UIButton *button;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (assign, nonatomic) NSUInteger type;

- (UIView *)initWithImage:(nullable UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle;
- (UIView *)initForHomeWithImage:(nullable UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle;
- (void)enableTimelineLayoutConstraint;

@end

NS_ASSUME_NONNULL_END
