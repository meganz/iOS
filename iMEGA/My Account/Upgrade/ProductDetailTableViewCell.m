#import "ProductDetailTableViewCell.h"
#import "MEGA-Swift.h"

@implementation ProductDetailTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self updateAppearance];
}

@end
