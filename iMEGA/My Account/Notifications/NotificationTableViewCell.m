#import "NotificationTableViewCell.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@implementation NotificationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self updateAppearance];
    self.theNewLabel.text = LocalizedString(@"New", @"Label shown inside an unseen notification");
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self updateAppearance];
}

@end
