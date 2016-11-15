#import <UIKit/UIKit.h>

@interface UnavailableLinkView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewCenterYLayoutConstraint;

@end
