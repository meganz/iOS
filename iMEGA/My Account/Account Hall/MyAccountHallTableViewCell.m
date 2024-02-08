#import "MyAccountHallTableViewCell.h"

#import "MEGA-Swift.h"

@implementation MyAccountHallTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupCell];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setupCell];
}

#pragma mark - Private

- (void)setupCell {
    self.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    
    self.sectionLabel.textColor = [UIColor mnz_defaultLabelTextColor];
    
    self.detailLabel.text = @"";
    self.detailLabel.textColor = [UIColor mnz_secondaryLabelTextColor];
    
    self.pendingView.backgroundColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    self.pendingLabel.textColor = [UIColor mnz_badgeTextColor];
    
    if (self.pendingView != nil) {
        [self layoutPendingView];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self setupCell];
    }
}

@end
