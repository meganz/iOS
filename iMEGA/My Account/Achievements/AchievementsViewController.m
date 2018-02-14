
#import "AchievementsViewController.h"

#import "NSDate+DateTools.h"

#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "AchievementsDetailsViewController.h"
#import "AchievementsTableViewCell.h"
#import "InviteFriendsViewController.h"
#import "ReferralBonusesTableViewController.h"

@interface AchievementsViewController () <UITableViewDataSource, UITableViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIView *inviteYourFriendsView;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsSubtitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *unlockedBonusesLabel;
@property (weak, nonatomic) IBOutlet UILabel *unlockedStorageQuotaLabel;
@property (weak, nonatomic) IBOutlet UILabel *storageQuotaLabel;
@property (weak, nonatomic) IBOutlet UILabel *unlockedTransferQuotaLabel;
@property (weak, nonatomic) IBOutlet UILabel *transferQuotaLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSByteCountFormatter *byteCountFormatter;

@property (nonatomic) MEGAAchievementsDetails *achievementsDetails;
@property (nonatomic) NSMutableArray *achievementsIndexesMutableArray;

@property (nonatomic, getter=haveReferralBonuses) BOOL referralBonuses;

@end

@implementation AchievementsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.byteCountFormatter = [[NSByteCountFormatter alloc] init];
    self.byteCountFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
    
    self.navigationItem.title = AMLocalizedString(@"achievementsTitle", @"Title of the Achievements section");
    
    self.inviteYourFriendsTitleLabel.text = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inviteYourFriendsTapped)];
    self.inviteYourFriendsView.gestureRecognizers = @[tapGestureRecognizer];
    
    self.unlockedBonusesLabel.text = AMLocalizedString(@"unlockedBonuses", @"Header of block with achievements bonuses.");
    self.storageQuotaLabel.text = AMLocalizedString(@"storageQuota", @"A header/title of a section which contains information about used/available storage space on a user's cloud drive.");
    self.transferQuotaLabel.text = AMLocalizedString(@"transferQuota", @"The header/title of a block/section which contains information about the user's used/available transfer allowance for their account.");
    
    [[MEGASdkManager sharedMEGASdk] getAccountAchievementsWithDelegate:self];
    
    if (self.enableCloseBarButton) { //For modal presentations
        UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"skipButton", @"Button title that skips the current action")
                                                                           style:UIBarButtonItemStyleDone
                                                                          target:self
                                                                          action:@selector(dismissViewController)];
        self.navigationItem.rightBarButtonItem = rightButtonItem;
    }
}

#pragma mark - Private

- (NSMutableAttributedString *)textForUnlockedBonuses:(long long)quota {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.locale = [NSLocale currentLocale];
    numberFormatter.maximumFractionDigits = 0;
    
    NSString *stringFromByteCount;
    NSRange firstPartRange = NSMakeRange(0, 0);
    NSRange secondPartRange  = NSMakeRange(0, 0);;
    
    stringFromByteCount = [self.byteCountFormatter stringFromByteCount:quota];

    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    
    NSString *firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    NSNumber *number = [numberFormatter numberFromString:firstPartString];
    firstPartString = [numberFormatter stringFromNumber:number];
    
    if (firstPartString.length == 0) {
        firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    }
    
    firstPartString = [firstPartString stringByAppendingString:@" "];
    firstPartRange = [firstPartString rangeOfString:firstPartString];
    NSMutableAttributedString *firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
    
    NSString *secondPartString = [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray];
    secondPartRange = [secondPartString rangeOfString:secondPartString];
    NSMutableAttributedString *secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont mnz_SFUIRegularWithSize:32.0f]
                                             range:firstPartRange];
    
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                              value:[UIFont mnz_SFUIRegularWithSize:17.0f]
                                              range:secondPartRange];
    
    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (void)setStorageAndTransferQuotaRewardsForCell:(AchievementsTableViewCell *)cell forIndex:(NSInteger)index {
    long long classStorageReward = 0;
    long long classTransferReward = 0;
    if (index == -1) {
        classStorageReward = self.achievementsDetails.currentStorageReferrals;
        classTransferReward = self.achievementsDetails.currentTransferReferrals;
    } else {
        NSInteger awardId = [self.achievementsDetails awardIdAtIndex:index];
        classStorageReward = [self.achievementsDetails rewardStorageByAwardId:awardId];
        classTransferReward = [self.achievementsDetails rewardTransferByAwardId:awardId];
    }
    
    cell.storageQuotaRewardView.backgroundColor = cell.storageQuotaRewardLabel.backgroundColor = ((classStorageReward == 0) ? [UIColor mnz_grayCCCCCC] : [UIColor mnz_blue2BA6DE]);
    cell.storageQuotaRewardLabel.text = (classStorageReward == 0) ? @"— GB" : [self.byteCountFormatter stringFromByteCount:classStorageReward];
    
    cell.transferQuotaRewardView.backgroundColor = cell.transferQuotaRewardLabel.backgroundColor = ((classTransferReward == 0) ? [UIColor mnz_grayCCCCCC] : [UIColor mnz_green31B500]);
    cell.transferQuotaRewardLabel.text = (classTransferReward == 0) ? @"— GB" : [self.byteCountFormatter stringFromByteCount:classTransferReward];
}

- (void)pushAchievementsDetailsWithIndexPath:(NSIndexPath *)indexPath {
    AchievementsDetailsViewController *achievementsDetailsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsDetailsViewControllerID"];
    achievementsDetailsVC.achievementsDetails = self.achievementsDetails;
    NSUInteger numberOfStaticCells = self.haveReferralBonuses ? 1 : 0;
    NSNumber *index = [self.achievementsIndexesMutableArray objectAtIndex:(indexPath.row - numberOfStaticCells)];
    achievementsDetailsVC.index = index.unsignedIntegerValue;
    
    [self.navigationController pushViewController:achievementsDetailsVC animated:YES];
}

- (void)inviteYourFriendsTapped {
    InviteFriendsViewController *inviteFriendsViewController = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteFriendsViewControllerID"];
    inviteFriendsViewController.inviteYourFriendsSubtitleString = self.inviteYourFriendsSubtitleLabel.text;
    
    [self.navigationController pushViewController:inviteFriendsViewController animated:YES];
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger numberOfStaticCells = self.haveReferralBonuses ? 1 : 0;
    
    return numberOfStaticCells + self.achievementsIndexesMutableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    if (indexPath.row == 0) {
        identifier = self.haveReferralBonuses ? @"AchievementsTableViewCellID" : @"AchievementsWithSubtitleTableViewCellID";
    } else {
        identifier = @"AchievementsWithSubtitleTableViewCellID";
    }
    
    AchievementsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AchievementsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    if (indexPath.row == 0 && self.haveReferralBonuses) {
        cell.titleLabel.text = AMLocalizedString(@"referralBonuses", @"achievement type");
        
        cell.disclosureIndicatorImageView.hidden = NO;
        
        [self setStorageAndTransferQuotaRewardsForCell:cell forIndex:-1];
    } else {
        NSUInteger numberOfStaticCells = self.haveReferralBonuses ? 1 : 0;
        NSNumber *index = [self.achievementsIndexesMutableArray objectAtIndex:(indexPath.row - numberOfStaticCells)];
        MEGAAchievement achievementClass = [self.achievementsDetails awardClassAtIndex:index.unsignedIntegerValue];
        
        [self setStorageAndTransferQuotaRewardsForCell:cell forIndex:index.integerValue];
        
        switch (achievementClass) {
            case MEGAAchievementWelcome: {
                cell.titleLabel.text = AMLocalizedString(@"registrationBonus", @"achievement type");
                break;
            }
                
            case MEGAAchievementDesktopInstall: {
                cell.titleLabel.text = AMLocalizedString(@"installMEGASync", @"");
                break;
            }
                
            case MEGAAchievementMobileInstall: {
                cell.titleLabel.text = AMLocalizedString(@"installOurMobileApp", @"");
                break;
            }
                
            default:
                break;
        }
        
        NSDate *awardExpirationdDate = [self.achievementsDetails awardExpirationAtIndex:index.unsignedIntegerValue];
        cell.subtitleLabel.text = (awardExpirationdDate.daysUntil == 0) ? AMLocalizedString(@"expired", @"Label to show that an error related with expiration occurs during a SDK operation.") : [AMLocalizedString(@"xDaysLeft", @"") stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%lu", awardExpirationdDate.daysUntil]];
        cell.subtitleLabel.textColor = (awardExpirationdDate.daysUntil <= 15) ? [UIColor mnz_redF0373A] : [UIColor mnz_gray666666];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            if (self.haveReferralBonuses) {
                ReferralBonusesTableViewController *referralBonusesTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"ReferralBonusesTableViewControllerID"];
                referralBonusesTVC.achievementsDetails = self.achievementsDetails;
                [self.navigationController pushViewController:referralBonusesTVC animated:YES];
            } else {
                [self pushAchievementsDetailsWithIndexPath:indexPath];
            }
            break;
        }
            
        default: {
            [self pushAchievementsDetailsWithIndexPath:indexPath];
            break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (request.type == MEGARequestTypeGetAchievements) {
        if (error.type) {
            return;
        }
        
        self.achievementsDetails = request.megaAchievementsDetails;
        
        self.achievementsIndexesMutableArray = [[NSMutableArray alloc] init];
        NSUInteger awardsCount = self.achievementsDetails.awardsCount;
        for (NSUInteger i = 0; i < awardsCount; i++) {
            MEGAAchievement achievementClass = [self.achievementsDetails awardClassAtIndex:i];
            if (achievementClass == MEGAAchievementInvite) {
                self.referralBonuses = YES;
            } else {
                [self.achievementsIndexesMutableArray addObject:[NSNumber numberWithInteger:i]];
            }
        }
        
        NSString *inviteStorageString = [self.byteCountFormatter stringFromByteCount:[self.achievementsDetails classStorageForClassId:MEGAAchievementInvite]];
        NSString *inviteTransferString = [self.byteCountFormatter stringFromByteCount:[self.achievementsDetails classTransferForClassId:MEGAAchievementInvite]];
        NSString *inviteFriendsAndGetForEachReferral = AMLocalizedString(@"inviteFriendsAndGetForEachReferral", @"title of the introduction for the achievements screen");
        inviteFriendsAndGetForEachReferral = [inviteFriendsAndGetForEachReferral stringByReplacingOccurrencesOfString:@"%1$s" withString:inviteStorageString];
        inviteFriendsAndGetForEachReferral = [inviteFriendsAndGetForEachReferral stringByReplacingOccurrencesOfString:@"%2$s" withString:inviteTransferString];
        self.inviteYourFriendsSubtitleLabel.text = inviteFriendsAndGetForEachReferral;
        
        self.unlockedStorageQuotaLabel.attributedText = [self textForUnlockedBonuses:self.achievementsDetails.currentStorage];
        self.unlockedTransferQuotaLabel.attributedText = [self textForUnlockedBonuses:self.achievementsDetails.currentTransfer];
        
        [self.inviteYourFriendsSubtitleLabel sizeToFit];
        
        [self.tableView reloadData];
    }
}

@end
