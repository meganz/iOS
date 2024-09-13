#import "RecentsTableViewHeaderFooterView.h"

#import "MEGA-Swift.h"

@implementation RecentsTableViewHeaderFooterView 

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupWithTrait:self.traitCollection];
    
    self.bottomSeparatorView.layer.borderWidth = 0.5;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setupWithTrait:self.traitCollection];
}

#pragma mark - Private

- (void)setupWithTrait:(UITraitCollection *)trait {
    [self configureTokenColors];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self setupWithTrait:self.traitCollection];
    }
}

@end
