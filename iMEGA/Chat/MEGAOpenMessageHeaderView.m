#import "MEGAOpenMessageHeaderView.h"

@interface MEGAOpenMessageHeaderView ()

@end

@implementation MEGAOpenMessageHeaderView

+ (UINib *)nib {
    return [UINib nibWithNibName:@"MEGAOpenMessageHeaderView" bundle:nil];
}

+ (NSString *)headerReuseIdentifier {
    return @"MEGAOpenMessageHeaderViewID";
}

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
    self.chattingWithLabel.textColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    self.introductionLabel.textColor = self.confidentialityLabel.textColor = self.authenticityLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
}

@end
