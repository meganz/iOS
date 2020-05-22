
#import "MEGAMessageRichPreviewView.h"

@implementation MEGAMessageRichPreviewView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
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
    self.richPreviewView.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    
    self.descriptionLabel.textColor = self.linkLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}

@end
