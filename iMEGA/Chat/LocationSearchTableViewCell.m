#import "LocationSearchTableViewCell.h"
#import "MEGA-Swift.h"

@implementation LocationSearchTableViewCell

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.detailLabel.textColor = [UIColor mnz_subtitles];
}

@end
