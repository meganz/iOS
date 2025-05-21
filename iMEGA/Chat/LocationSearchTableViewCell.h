#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocationSearchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *locationPinImageView;

@end

NS_ASSUME_NONNULL_END
