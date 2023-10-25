#import "ProductDetailTableViewCell.h"

@implementation ProductDetailTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = UIColor.systemBackgroundColor;
    self.periodLabel.textColor = self.priceLabel.textColor = UIColor.labelColor;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.backgroundColor = UIColor.systemBackgroundColor;
    self.periodLabel.textColor = self.priceLabel.textColor = UIColor.labelColor;
}

@end
