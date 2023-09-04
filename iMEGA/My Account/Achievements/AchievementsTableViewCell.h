@interface AchievementsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *storageQuotaRewardView;
@property (weak, nonatomic) IBOutlet UILabel *storageQuotaRewardLabel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *daysLeftTrailingLabel;

@end
