#import "AchievementsTableViewCell.h"

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
    
    self.storageQuotaRewardView.backgroundColor = [UIColor mnz_blueForTraitCollection:self.traitCollection];
    self.storageQuotaRewardLabel.textColor = UIColor.whiteColor;
}

@end
