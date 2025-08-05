#import "AchievementsViewController.h"
#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

#import "AchievementsDetailsViewController.h"
#import "AchievementsTableViewCell.h"
#import "InviteFriendsViewController.h"
#import "ReferralBonusesTableViewController.h"
#import "NSArray+MNZCategory.h"

@import MEGAUIKit;
#import "LocalizationHelper.h"

@interface AchievementsViewController () <UITableViewDataSource, UITableViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIView *inviteYourFriendsView;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureIndicatorImageView;
@property (weak, nonatomic) IBOutlet UIImageView *inviteFriendsImageView;

@property (weak, nonatomic) IBOutlet UIView *unlockedBonusesView;
@property (weak, nonatomic) IBOutlet UIView *unlockedBonusesTopSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *unlockedBonusesLabel;
@property (weak, nonatomic) IBOutlet UILabel *unlockedStorageQuotaLabel;
@property (weak, nonatomic) IBOutlet UILabel *storageQuotaLabel;
@property (weak, nonatomic) IBOutlet UIView *unlockedBonusesBottomSeparatorView;

@property (nonatomic) MEGAAchievementsDetails *achievementsDetails;
@property (nonatomic) NSMutableDictionary *achievementsIndexesMutableDictionary;
@property (nonatomic) NSMutableArray<NSNumber *> *displayOrderMutableArray;

@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation AchievementsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    
    self.numberFormatter = NSNumberFormatter.alloc.init;
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.numberFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    self.numberFormatter.maximumFractionDigits = 0;
    
    [self.tableView sizeHeaderToFit];
    
    self.navigationItem.title = LocalizedString(@"achievementsTitle", @"Title of the Achievements section");
    [self configureBackButton];
    
    self.inviteYourFriendsTitleLabel.text = LocalizedString(@"account.achievement.referral.title", @"");
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inviteYourFriendsTapped)];
    self.inviteYourFriendsView.gestureRecognizers = @[tapGestureRecognizer];
    
    
    self.disclosureIndicatorImageView.image = [UIImage megaImageWithNamed:@"standardDisclosureIndicator_designToken"];
    self.disclosureIndicatorImageView.image = self.disclosureIndicatorImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.inviteFriendsImageView.image = [UIImage megaImageWithNamed:@"inviteFriends"];
    
    self.unlockedBonusesLabel.text = LocalizedString(@"unlockedBonuses", @"Header of block with achievements bonuses.");
    self.storageQuotaLabel.text = LocalizedString(@"storageQuota", @"A header/title of a section which contains information about used/available storage space on a user's cloud drive.");
    
    [MEGASdk.shared getAccountAchievementsWithDelegate:self];
    
    if (self.enableCloseBarButton) { //For modal presentations
        UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"skipButton", @"Button title that skips the current action")
                                                                           style:UIBarButtonItemStyleDone
                                                                          target:self
                                                                          action:@selector(dismissViewController)];
        self.navigationItem.rightBarButtonItem = rightButtonItem;
    }
    
    [self setupColors];
}

#pragma mark - Private

- (void)setupColors {
    self.view.backgroundColor = self.tableView.backgroundColor = [UIColor pageBackgroundColor];
    self.unlockedBonusesView.backgroundColor = [UIColor surface1Background];
    self.inviteYourFriendsTitleLabel.textColor = [UIColor primaryTextColor];
    self.unlockedBonusesLabel.textColor = [UIColor primaryTextColor];
    self.storageQuotaLabel.textColor = [UIColor mnz_secondaryTextColor];
    
    self.tableView.separatorColor = [UIColor borderStrong];
    self.inviteYourFriendsView.backgroundColor = [UIColor pageBackgroundColor];
    
    self.unlockedBonusesTopSeparatorView.backgroundColor = self.unlockedBonusesBottomSeparatorView.backgroundColor = [UIColor borderStrong];
    self.unlockedStorageQuotaLabel.textColor = [UIColor textInfoColor];
}

- (NSMutableAttributedString *)textForUnlockedBonuses:(long long)quota {
    NSString *stringFromByteCount;
    NSRange firstPartRange;
    NSRange secondPartRange;
    
    stringFromByteCount = [NSString memoryStyleStringFromByteCount:quota];

    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    
    NSString *firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    NSNumber *number = [self.numberFormatter numberFromString:firstPartString];
    firstPartString = [self.numberFormatter stringFromNumber:number];
    
    if (firstPartString.length == 0) {
        firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    }
    
    firstPartString = [firstPartString stringByAppendingString:@" "];
    firstPartRange = [firstPartString rangeOfString:firstPartString];
    NSMutableAttributedString *firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
    
    NSString *secondPartString = [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray];
    secondPartRange = [secondPartString rangeOfString:secondPartString];
    NSMutableAttributedString *secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle] range:firstPartRange];
    
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:secondPartRange];
    
    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (void)setStorageQuotaRewardsForCell:(AchievementsTableViewCell *)cell forIndex:(NSInteger)index {
    long long classStorageReward = 0;
    if (index == -1) {
        classStorageReward = self.achievementsDetails.currentStorageReferrals;
    } else {
        NSInteger awardId = [self.achievementsDetails awardIdAtIndex:index];
        classStorageReward = [self.achievementsDetails rewardStorageByAwardId:awardId];
    }
    
    cell.storageQuotaRewardView.backgroundColor = [UIColor supportInfoColor];
    cell.storageQuotaRewardLabel.backgroundColor = [UIColor supportInfoColor];
    cell.storageQuotaRewardLabel.textColor = [UIColor whiteTextColor];
    cell.storageQuotaRewardLabel.text = (classStorageReward == 0) ? LocalizedString(@"— GB", @"") : [NSString memoryStyleStringFromByteCount:classStorageReward];
}

- (void)pushAchievementsDetailsWithIndexPath:(NSIndexPath *)indexPath achievementClass:(MEGAAchievement)achievementClass {
    AchievementsDetailsViewController *achievementsDetailsVC = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsDetailsViewControllerID"];
    achievementsDetailsVC.achievementsDetails = self.achievementsDetails;
    NSNumber *index = [self.achievementsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:achievementClass]];
    achievementsDetailsVC.completedAchievementIndex = index;
    achievementsDetailsVC.achievementClass = achievementClass;
    achievementsDetailsVC.onAchievementDetailsUpdated = ^(MEGAAchievementsDetails* achievementDetails){
        [self setupView:achievementDetails];
    };
    
    [self.navigationController pushViewController:achievementsDetailsVC animated:YES];
}

- (void)inviteYourFriendsTapped {
    InviteFriendsViewController *inviteFriendsViewController = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteFriendsViewControllerID"];
    inviteFriendsViewController.inviteYourFriendsSubtitleString = self.inviteYourFriendsSubtitleLabel.text;
    
    [self.navigationController pushViewController:inviteFriendsViewController animated:YES];
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupView:(MEGAAchievementsDetails *)achievementDetails {
    self.achievementsDetails = achievementDetails;
    bool hasReferralBonuses = NO;
    bool hasWelcomeBonuses = NO;
    self.achievementsIndexesMutableDictionary = [[NSMutableDictionary alloc] init];
    NSUInteger awardsCount = self.achievementsDetails.awardsCount;
    for (NSUInteger i = 0; i < awardsCount; i++) {
        MEGAAchievement achievementClass = [self.achievementsDetails awardClassAtIndex:i];
        if (achievementClass == MEGAAchievementInvite) {
            hasReferralBonuses = YES;
        } else {
            if (achievementClass == MEGAAchievementWelcome) {
                hasWelcomeBonuses = YES;
            }
            if (achievementClass != MEGAAchievementAddPhone) {
                [self.achievementsIndexesMutableDictionary setObject:[NSNumber numberWithInteger:i] forKey:[NSNumber numberWithInteger:achievementClass]];
            }
        }
    }

    self.displayOrderMutableArray = [[NSMutableArray alloc] init];
    if (hasReferralBonuses) {
        [self.displayOrderMutableArray addObject:[NSNumber numberWithInt:MEGAAchievementInvite]];
    }
    if (hasWelcomeBonuses) {
        [self.displayOrderMutableArray addObject:[NSNumber numberWithInt:MEGAAchievementWelcome]];
    }

    NSArray<NSNumber *> *potentialAchievements = @[
        @(MEGAAchievementDesktopInstall),
        @(MEGAAchievementMobileInstall),
        @(MEGAAchievementVPNFreeTrial),
        @(MEGAAchievementPassFreeTrial)
    ];

    for (NSNumber *achievement in potentialAchievements) {
        if ([self.achievementsDetails isValidClass:achievement.integerValue]) {
            [self.displayOrderMutableArray addObject:achievement];
        }
    }

    NSString *inviteStorageString = [NSString memoryStyleStringFromByteCount:[self.achievementsDetails classStorageForClassId:MEGAAchievementInvite]];
    self.inviteYourFriendsSubtitleLabel.text = [NSString stringWithFormat:LocalizedString(@"account.achievement.referral.subtitle", @""), inviteStorageString];

    self.unlockedStorageQuotaLabel.attributedText = [self textForUnlockedBonuses:self.achievementsDetails.currentStorage];

    [self.inviteYourFriendsSubtitleLabel sizeToFit];

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayOrderMutableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAAchievement achievementClass = [[self.displayOrderMutableArray objectOrNilAtIndex:indexPath.row] unsignedIntegerValue];
    NSString *identifier = achievementClass == MEGAAchievementInvite ? @"AchievementsTableViewCellID" : @"AchievementsWithSubtitleTableViewCellID";
    AchievementsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

    switch (achievementClass) {
        case MEGAAchievementInvite: {
            cell.titleLabel.text = LocalizedString(@"account.achievement.referralBonus.title", @"");
            break;
        }
            
        case MEGAAchievementWelcome: {
            cell.titleLabel.text = LocalizedString(@"account.achievement.registration.title", @"");
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            cell.titleLabel.text = LocalizedString(@"account.achievement.desktopApp.title", @"");
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            cell.titleLabel.text = LocalizedString(@"account.achievement.mobileApp.title", @"");
            break;
        }

        case MEGAAchievementVPNFreeTrial: {
            cell.titleLabel.text = LocalizedString(@"account.achievement.vpnFreeTrial.title", @"");
            break;
        }

        case MEGAAchievementPassFreeTrial: {
            cell.titleLabel.text = LocalizedString(@"account.achievement.passFreeTrial.title", @"");
            break;
        }

        default:
            break;
    }
    if (achievementClass == MEGAAchievementInvite) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self setStorageQuotaRewardsForCell:cell forIndex:-1];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSNumber *index = [self.achievementsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:achievementClass]];
        if (index != nil) {
            [self setStorageQuotaRewardsForCell:cell forIndex:index.integerValue];
            [self configureAchievementSubtitleForCell:cell withIndex:index.unsignedIntegerValue forAchievementClass:achievementClass];
        } else {
            NSString *storageString = [NSString memoryStyleStringFromByteCount:[self.achievementsDetails classStorageForClassId:achievementClass]];
            
            cell.storageQuotaRewardLabel.text = storageString;
            
            cell.storageQuotaRewardView.backgroundColor = [UIColor supportInfoColor];
            cell.storageQuotaRewardLabel.backgroundColor = [UIColor supportInfoColor];
            cell.storageQuotaRewardLabel.textColor = [UIColor whiteTextColor];
            cell.subtitleLabel.text = [self subtitleTextForIncompleteAchievementWithStorageString:storageString forAchievementClass:achievementClass];
            cell.subtitleLabel.textColor = [UIColor mnz_secondaryTextColor];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAAchievement achievementClass = [[self.displayOrderMutableArray objectOrNilAtIndex:indexPath.row] unsignedIntegerValue];
    switch (achievementClass) {
        case MEGAAchievementInvite: {
            ReferralBonusesTableViewController *referralBonusesTVC = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"ReferralBonusesTableViewControllerID"];
            referralBonusesTVC.achievementsDetails = self.achievementsDetails;
            [self.navigationController pushViewController:referralBonusesTVC animated:YES];
            break;
        }
        default: {
            [self pushAchievementsDetailsWithIndexPath:indexPath achievementClass:achievementClass];
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

        [self setupView: request.megaAchievementsDetails];
    }
}

#pragma mark - Private Methods

- (void)configureAchievementSubtitleForCell:(AchievementsTableViewCell *)cell withIndex:(NSUInteger)index forAchievementClass:(MEGAAchievement)achievementClass {
    switch (achievementClass) {
        case MEGAAchievementVPNFreeTrial:
        case MEGAAchievementPassFreeTrial:
            cell.subtitleLabel.text = LocalizedString(@"account.achievement.complete.subtitle.permanent", @"");
            cell.subtitleLabel.textColor = [UIColor mnz_secondaryTextColor];
            break;
        default: {
            NSDate *expirationDate = [self.achievementsDetails awardExpirationAtIndex:index];
            NSInteger daysRemaining = expirationDate.daysUntil;
            cell.subtitleLabel.text = [self achievementSubtitleWithRemainingDays:daysRemaining];
            cell.subtitleLabel.textColor = (daysRemaining <= 15) ? [UIColor mnz_errorRed] : [UIColor mnz_secondaryTextColor];
            break;
        }
    }
}

- (NSString *)subtitleTextForIncompleteAchievementWithStorageString:(NSString *)storageString forAchievementClass:(MEGAAchievement)achievementClass {
    NSString *key;
    switch (achievementClass) {
        case MEGAAchievementVPNFreeTrial:
        case MEGAAchievementPassFreeTrial:
            key = @"account.achievement.incomplete.subtitle.permanent";
            break;
        default:
            key = @"account.achievement.incomplete.subtitle";
            break;
    }
    return [NSString stringWithFormat:LocalizedString(key, @""), storageString];
}

@end
