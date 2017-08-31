
@interface AchievementsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *storageQuotaRewardView;
@property (weak, nonatomic) IBOutlet UILabel *storageQuotaRewardLabel;

@property (weak, nonatomic) IBOutlet UIView *transferQuotaRewardView;
@property (weak, nonatomic) IBOutlet UILabel *transferQuotaRewardLabel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIImageView *disclosureIndicatorImageView;

@end
