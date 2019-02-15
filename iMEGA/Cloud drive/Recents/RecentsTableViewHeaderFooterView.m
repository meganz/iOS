#import "RecentsTableViewHeaderFooterView.h"

@implementation RecentsTableViewHeaderFooterView 

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = UIColor.whiteColor;
    
    self.topSeparatorView.layer.borderColor = self.bottomSeparatorView.layer.borderColor = UIColor.mnz_grayCCCCCC.CGColor;
    self.topSeparatorView.layer.borderWidth = self.bottomSeparatorView.layer.borderWidth = 0.5;
}

@end
