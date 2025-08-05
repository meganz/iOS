#import "NotificationTableViewCell.h"
#import "MEGA-Swift.h"

#import "LocalizationHelper.h"

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
