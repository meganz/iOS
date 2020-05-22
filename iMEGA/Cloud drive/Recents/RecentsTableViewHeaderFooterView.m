#import "RecentsTableViewHeaderFooterView.h"

@implementation RecentsTableViewHeaderFooterView 

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setup];
    
    self.bottomSeparatorView.layer.borderWidth = 0.5;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setup];
}

#pragma mark - Private

- (void)setup {
    self.contentView.backgroundColor = [UIColor mnz_notificationSeenBackgroundForTraitCollection:self.traitCollection];
    
    self.dateLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    
    self.bottomSeparatorView.layer.borderColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection].CGColor;
}

@end
