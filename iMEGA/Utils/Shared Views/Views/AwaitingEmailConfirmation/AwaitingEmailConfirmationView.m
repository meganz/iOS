#import "AwaitingEmailConfirmationView.h"
#import "MEGA-Swift.h"

@implementation AwaitingEmailConfirmationView

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.backgroundColor = [UIColor pageBackgroundForTraitCollection:self.traitCollection];
    self.titleLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor mnz_secondaryTextColor];
    [self.iconImageView.image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    self.iconImageView.tintColor = [UIColor iconSecondaryColor];
}

@end
