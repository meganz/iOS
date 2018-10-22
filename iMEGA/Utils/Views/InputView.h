
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InputView : UIView

@property (nonatomic) UIView *customView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

- (void)setErrorState:(BOOL)error withText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
