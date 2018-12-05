
#import "NotificationTableViewCell.h"

@implementation NotificationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.theNewLabel.text = AMLocalizedString(@"New", @"Label shown inside an unseen notification").uppercaseString;
}

@end
