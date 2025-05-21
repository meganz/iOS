#import "LocationSearchTableViewCell.h"
#import "MEGA-Swift.h"

@implementation LocationSearchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImages];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.detailLabel.textColor = [UIColor mnz_secondaryTextColor];
}

- (void)configureImages {
    self.locationPinImageView.image = [UIImage megaImageWithNamed:@"locationPin"];
}

@end
