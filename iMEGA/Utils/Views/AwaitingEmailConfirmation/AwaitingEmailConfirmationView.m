
#import "AwaitingEmailConfirmationView.h"

@implementation AwaitingEmailConfirmationView

#pragma mark - Lifecycle

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
    self.backgroundColor = UIColor.mnz_background;
}

@end
