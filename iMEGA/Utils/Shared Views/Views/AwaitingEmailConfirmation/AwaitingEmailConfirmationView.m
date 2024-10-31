#import "AwaitingEmailConfirmationView.h"
#import "MEGA-Swift.h"

@implementation AwaitingEmailConfirmationView

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupColors];
}

#pragma mark - Private

- (void)setupColors {
    self.backgroundColor = [UIColor pageBackgroundColor];
    self.titleLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor mnz_secondaryTextColor];
    [self.iconImageView.image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    self.iconImageView.tintColor = [UIColor iconSecondaryColor];
}

@end
