#import "ProductTableViewCell.h"

#import "MEGA-Swift.h"

@implementation ProductTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupCell];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.productNameView.backgroundColor = self.productPriceLabel.textColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.productNameView.backgroundColor = self.productPriceLabel.textColor;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setupCell];
}

#pragma mark - Private

- (void)setupCell {
    self.backgroundColor = [UIColor mnz_backgroundElevated];
    
    self.productNameLabel.textColor = UIColor.mnz_whiteFFFFFF;
}

@end
