
#import "MEGAMessageDialogView.h"

@implementation MEGAMessageDialogView

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

- (IBAction)didTapButton:(UIButton *)sender {
    [self.delegate dialogView:self didChooseOption:(MEGAMessageDialogOption)sender.tag];
}

#pragma mark - Private

- (void)updateAppearance {
    self.contentView.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    
    self.descriptionLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.alwaysAllowButton.titleLabel.textColor = self.notNowButton.titleLabel.textColor = UIColor.mnz_label;
    self.neverButton.titleLabel.textColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    
    self.firstLineView.backgroundColor = self.secondLineView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

@end
