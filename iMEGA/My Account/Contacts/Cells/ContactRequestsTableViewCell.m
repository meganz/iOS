
#import "ContactRequestsTableViewCell.h"

@implementation ContactRequestsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    
    [self setup];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self setup];
}

#pragma mark - Private

- (void)setup {
    self.timeAgoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}

@end
