
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface InputView : UIView

@property (nonatomic) UIView *customView;
@property (nonatomic) IBOutlet UIView *topSeparatorView;
@property (nonatomic) IBInspectable UIImage *iconImage;
@property (nonatomic) IBInspectable NSString *topLabelTextKey;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (nonatomic) IBOutlet UIView *bottomSeparatorView;

@property (nonatomic, getter=isUsingDefaultBackgroundColor) BOOL usingDefaultBackgroundColor;

- (void)setErrorState:(BOOL)error withText:(NSString *)text;

- (void)updateAppearance;

@end

NS_ASSUME_NONNULL_END
