#import "ProductTableViewCell.h"

@implementation ProductTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.productNameView.backgroundColor = self.productPriceLabel.textColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.upperLineView.backgroundColor = [UIColor mnz_separatorColorForTraitCollection:self.traitCollection];
        self.productNameView.backgroundColor = self.productPriceLabel.textColor;
        self.underLineView.backgroundColor = [UIColor mnz_separatorColorForTraitCollection:self.traitCollection];
    }
}

@end
