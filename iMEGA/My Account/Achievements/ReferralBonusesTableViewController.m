
#import "ReferralBonusesTableViewController.h"

#import "NSDate+DateTools.h"

#import "Helper.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "MEGAUser+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "AchievementsTableViewCell.h"

@interface ReferralBonusesTableViewController () <UITableViewDataSource>

@property (nonatomic) NSMutableArray *inviteAchievementsIndexesMutableArray;
@property (nonatomic) NSMutableArray *inviteAchievementsEmailsMutableArray;

@end

@implementation ReferralBonusesTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"referralBonuses", @"achievement type");
    
    self.inviteAchievementsIndexesMutableArray = [[NSMutableArray alloc] init];
    NSUInteger awardsCount = self.achievementsDetails.awardsCount;
    for (NSUInteger i = 0; i < awardsCount; i++) {
        MEGAAchievement achievementClass = [self.achievementsDetails awardClassAtIndex:i];
        if (achievementClass == MEGAAchievementInvite) {
            [self.inviteAchievementsIndexesMutableArray addObject:[NSNumber numberWithInteger:i]];
        }
    }
    
    self.inviteAchievementsEmailsMutableArray = [[NSMutableArray alloc] init];
    for (NSNumber *index in self.inviteAchievementsIndexesMutableArray) {
        MEGAStringList *stringList = [self.achievementsDetails awardEmailsAtIndex:index.unsignedIntegerValue];
        NSString *email = [stringList stringAtIndex:0];
        [self.inviteAchievementsEmailsMutableArray addObject:email];
    }
}

#pragma mark - Private

- (void)setStorageAndTransferQuotaRewardsForCell:(AchievementsTableViewCell *)cell withAwardId:(NSInteger)awardId {
    long long classStorageReward = [self.achievementsDetails rewardStorageByAwardId:awardId];
    long long classTransferReward = [self.achievementsDetails rewardTransferByAwardId:awardId];
    
    cell.storageQuotaRewardView.backgroundColor = cell.storageQuotaRewardLabel.backgroundColor = ((classStorageReward == 0) ? [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection] : UIColor.mnz_blue2BA6DE);
    cell.storageQuotaRewardLabel.text = (classStorageReward == 0) ? @"— GB" : [Helper memoryStyleStringFromByteCount:classStorageReward];
    
    cell.transferQuotaRewardView.backgroundColor = cell.transferQuotaRewardLabel.backgroundColor = ((classTransferReward == 0) ? [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection] : UIColor.mnz_green31B500);
    cell.transferQuotaRewardLabel.text = (classTransferReward == 0) ? @"— GB" : [Helper memoryStyleStringFromByteCount:classTransferReward];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.inviteAchievementsEmailsMutableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"ContactReferralAchievementTableViewCellID";
    AchievementsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AchievementsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    NSString *email = [self.inviteAchievementsEmailsMutableArray objectAtIndex:indexPath.row];
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:email];
    
    if (user) {
        [cell.avatarImageView mnz_setImageForUserHandle:user.handle];
        cell.titleLabel.text = user.mnz_displayName;
    } else {
        MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithEmail:email];
        if (moUser) {
            [cell.avatarImageView mnz_setImageForUserHandle:MEGAInvalidHandle name:moUser.fullName];
            cell.titleLabel.text = moUser.displayName;
        } else {
            [cell.avatarImageView mnz_setImageForUserHandle:MEGAInvalidHandle];
            cell.titleLabel.text = @"";
            MEGAGetAttrUserRequestDelegate *delegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                [tableView reloadData];
            }];
            [[MEGASdkManager sharedMEGASdk] getUserAttributeForEmailOrHandle:email type:MEGAUserAttributeFirstname delegate:delegate];
            [[MEGASdkManager sharedMEGASdk] getUserAttributeForEmailOrHandle:email type:MEGAUserAttributeLastname delegate:delegate];
        }
    }
    
    NSInteger inviteIndexPath = [[self.inviteAchievementsIndexesMutableArray objectAtIndex:indexPath.row] integerValue];
    NSInteger awardId = [self.achievementsDetails awardIdAtIndex:inviteIndexPath];
    [self setStorageAndTransferQuotaRewardsForCell:cell withAwardId:awardId];
    
    NSDate *awardExpirationdDate = [self.achievementsDetails awardExpirationAtIndex:inviteIndexPath];
    cell.daysLeftTrailingLabel.text = [AMLocalizedString(@"xDaysLeft", @"") stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%td", awardExpirationdDate.daysUntil]];
    cell.daysLeftTrailingLabel.textColor = (awardExpirationdDate.daysUntil <= 15) ? [UIColor mnz_redMainForTraitCollection:(self.traitCollection)] : [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    
    return cell;
}

@end
