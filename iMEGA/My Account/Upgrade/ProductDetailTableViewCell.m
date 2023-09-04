#import "ProductDetailTableViewCell.h"

@implementation ProductDetailTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = UIColor.mnz_background;
    self.periodLabel.textColor = self.priceLabel.textColor = UIColor.mnz_label;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.backgroundColor = UIColor.mnz_background;
    self.periodLabel.textColor = self.priceLabel.textColor = UIColor.mnz_label;
}

@end
