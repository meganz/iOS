#import "SelectableTableViewCell.h"
#import "MEGA-Swift.h"

@implementation SelectableTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self imageViewDesignToken];
    
    self.redCheckmarkImageView.image = [UIImage megaImageWithNamed:@"turquoise_checkmark"];
}

@end
