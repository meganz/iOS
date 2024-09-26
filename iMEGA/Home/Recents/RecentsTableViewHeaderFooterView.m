#import "RecentsTableViewHeaderFooterView.h"

#import "MEGA-Swift.h"

@implementation RecentsTableViewHeaderFooterView 

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureTokenColors];
    
    self.bottomSeparatorView.layer.borderWidth = 0.5;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self configureTokenColors];
}

@end
