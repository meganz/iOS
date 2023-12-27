#import "PhotoCollectionViewCell.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

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
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.thumbnailVideoDurationLabel.textColor = UIColor.mnz_whiteFFFFFF;
}

@end
