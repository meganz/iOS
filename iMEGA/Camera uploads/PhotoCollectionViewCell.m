#import "PhotoCollectionViewCell.h"

@implementation PhotoCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self updateAppearance];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.thumbnailSelectionOverlayView.hidden = !selected;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.thumbnailVideoDurationLabel.textColor = UIColor.whiteColor;
}

@end
