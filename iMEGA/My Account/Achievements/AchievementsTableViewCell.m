#import "AchievementsTableViewCell.h"
#import "MEGA-Swift.h"

@implementation AchievementsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupCell];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setupCell];
}

#pragma mark - Private

- (void)setupCell {
    self.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    
    self.storageQuotaRewardView.backgroundColor = [UIColor supportInfoColor];
    self.storageQuotaRewardLabel.textColor =  [UIColor mnz_badgeTextColor];
    self.titleLabel.textColor = [UIColor primaryTextColor];
    self.subtitleLabel.textColor = [UIColor secondaryTextColor];
}

@end
