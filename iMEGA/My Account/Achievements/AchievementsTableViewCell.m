
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
    
    self.storageQuotaRewardView.backgroundColor = UIColor.mnz_blue2BA6DE;
    self.transferQuotaRewardView.backgroundColor = UIColor.mnz_green31B500;
    self.storageQuotaRewardLabel.textColor = self.transferQuotaRewardLabel.textColor = UIColor.whiteColor;
}

@end
