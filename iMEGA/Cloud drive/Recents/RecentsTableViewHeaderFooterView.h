#import <Foundation/Foundation.h>

@interface RecentsTableViewHeaderFooterView : UITableViewHeaderFooterView

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *bottomSeparatorView;

@end
