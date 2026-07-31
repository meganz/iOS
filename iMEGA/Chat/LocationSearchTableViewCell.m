#import "LocationSearchTableViewCell.h"
#import "MEGA-Swift.h"

@implementation LocationSearchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self updateAppearance];
    [self registerForAppearanceChanges];
    [self configureImages];
}

#pragma mark - Private

- (void)registerForAppearanceChanges {
    [self registerForTraitChanges:UITraitCollection.systemTraitsAffectingColorAppearance withTarget:self action:@selector(updateAppearance)];
}

- (void)updateAppearance {
    self.detailLabel.textColor = [UIColor mnz_secondaryTextColor];
}

- (void)configureImages {
    self.locationPinImageView.image = [UIImage megaImageWithNamed:@"locationPin"];
}

@end
