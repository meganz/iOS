#import "ContactRequestsTableViewCell.h"
#import "MEGA-Swift.h"

@implementation ContactRequestsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    
    [self updateAppearance];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self updateAppearance];
}

@end
