#import <UIKit/UIKit.h>

@interface SelectableTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *redCheckmarkImageView;

@property (weak, nonatomic) IBOutlet UIView *lineView;

@end
