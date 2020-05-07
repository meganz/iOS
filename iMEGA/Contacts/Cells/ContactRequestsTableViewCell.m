
#import "ContactRequestsTableViewCell.h"

@implementation ContactRequestsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 11.0, *)) {
        self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    [self setup];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self setup];
}

#pragma mark - Private

- (void)setup {
    self.timeAgoLabel.textColor = [UIColor mnz_subtitlesColorForTraitCollection:self.traitCollection];
}

@end
