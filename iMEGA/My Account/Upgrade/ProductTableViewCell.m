#import "ProductTableViewCell.h"

@implementation ProductTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        view.userInteractionEnabled = NO;
        self.selectedBackgroundView = view;
        
        self.productNameView.backgroundColor = self.productPriceLabel.textColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        self.selectedBackgroundView = view;
        
        self.upperLineView.backgroundColor = UIColor.mnz_grayCCCCCC;
        self.productNameView.backgroundColor = self.productPriceLabel.textColor;
        self.underLineView.backgroundColor = UIColor.mnz_grayCCCCCC;
    }
}

@end
