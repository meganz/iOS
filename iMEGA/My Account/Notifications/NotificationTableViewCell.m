
#import "NotificationTableViewCell.h"

@implementation NotificationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.theNewView.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    
    self.theNewLabel.textColor = UIColor.whiteColor;
    self.theNewLabel.text = NSLocalizedString(@"New", @"Label shown inside an unseen notification");
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.theNewView.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
}

@end
