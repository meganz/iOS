
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEGAMessageGeoLocationView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIView *geolocationInfoView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

NS_ASSUME_NONNULL_END
