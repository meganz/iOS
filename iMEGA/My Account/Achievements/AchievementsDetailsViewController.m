
#import "AchievementsDetailsViewController.h"

#import "NSDate+DateTools.h"

#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@interface AchievementsDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImageView;

@property (weak, nonatomic) IBOutlet UIView *bonusExpireInView;
@property (weak, nonatomic) IBOutlet UILabel *bonusExpireInLabel;

@property (weak, nonatomic) IBOutlet UIView *howItWorksTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *howItWorksView;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksExplanationLabel;

@property (weak, nonatomic) IBOutlet UILabel *howItWorksCompletedExplanationLabel;

@end

@implementation AchievementsDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *achievementImage;
    
    NSString *navigationTitle = @"";
    NSString *howItWorksExplanationLabel = @"";
    
    NSInteger awardId = [self.achievementsDetails awardIdAtIndex:self.index];
    long long classStorageReward = [self.achievementsDetails rewardStorageByAwardId:awardId];
    long long classTransferReward = [self.achievementsDetails rewardTransferByAwardId:awardId];
    
    MEGAAchievement achievementClass = [self.achievementsDetails awardClassAtIndex:self.index];
    switch (achievementClass) {
        case MEGAAchievementWelcome: {
            navigationTitle = AMLocalizedString(@"registrationBonus", @"achievement type");
            achievementImage = [UIImage imageNamed:@"achievementsRegistration"];
            NSString *registrationBonusExplanation = AMLocalizedString(@"registrationBonusExplanation", @"Message shown on the achievements dialog for achieved achievements, %1 is replaced with e.g. 20 GB");
            howItWorksExplanationLabel = [registrationBonusExplanation stringByReplacingOccurrencesOfString:@"%1" withString:[Helper memoryStyleStringFromByteCount:classStorageReward]];
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            navigationTitle = AMLocalizedString(@"installMEGASync", @"");
            achievementImage = [UIImage imageNamed:@"achievementsInstallMega"];
            
            NSString *installMEGASyncCompletedExplanation = AMLocalizedString(@"installMEGASyncCompletedExplanation", @"Message shown on the achievements dialog for achieved achievements, %1 and %2 are replaced with e.g. 20 GB");
            installMEGASyncCompletedExplanation = [installMEGASyncCompletedExplanation stringByReplacingOccurrencesOfString:@"%1" withString:[Helper memoryStyleStringFromByteCount:classStorageReward]];
            howItWorksExplanationLabel = [installMEGASyncCompletedExplanation stringByReplacingOccurrencesOfString:@"%2" withString:[Helper memoryStyleStringFromByteCount:classTransferReward]];
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            navigationTitle = AMLocalizedString(@"installOurMobileApp", @"");
            achievementImage = [UIImage imageNamed:@"achievementsInstallMobile"];
            
            NSString *installOurMobileAppCompletedExplanation = AMLocalizedString(@"installOurMobileAppCompletedExplanation", @"");
            installOurMobileAppCompletedExplanation = [installOurMobileAppCompletedExplanation stringByReplacingOccurrencesOfString:@"%1" withString:[Helper memoryStyleStringFromByteCount:classStorageReward]];
            howItWorksExplanationLabel = [installOurMobileAppCompletedExplanation stringByReplacingOccurrencesOfString:@"%2" withString:[Helper memoryStyleStringFromByteCount:classTransferReward]];
            break;
        }
            
        case MEGAAchievementAddPhone: {
            navigationTitle = AMLocalizedString(@"Add Phone Number", nil);
            achievementImage = [UIImage imageNamed:@"addPhoneNumberSmall"];
            
            howItWorksExplanationLabel = [[AMLocalizedString(@"You have received %1$s storage space and %2$s transfer quota for verifying your phone number.", nil) stringByReplacingOccurrencesOfString:@"%1$s" withString:[Helper memoryStyleStringFromByteCount:classStorageReward]] stringByReplacingOccurrencesOfString:@"%2$s" withString:[Helper memoryStyleStringFromByteCount:classTransferReward]];
            break;
        }

        default:
            break;
    }
    
    self.navigationItem.title = navigationTitle;
    
    self.achievementImageView.image = achievementImage.imageFlippedForRightToLeftLayoutDirection;
    
    [self setBonusExpireInLabelText];
    
    self.howItWorksLabel.hidden = YES;
    self.howItWorksExplanationLabel.hidden = YES;
    self.howItWorksCompletedExplanationLabel.text = howItWorksExplanationLabel;
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.bonusExpireInView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    
    self.howItWorksTopSeparatorView.backgroundColor = [UIColor mnz_separatorColorForTraitCollection:self.traitCollection];
    self.howItWorksView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
}

#pragma - Private

- (void)setBonusExpireInLabelText {
    NSDate *awardExpirationdDate = [self.achievementsDetails awardExpirationAtIndex:self.index];
    NSString *bonusExpiresIn = AMLocalizedString(@"bonusExpiresIn", @"%1 will be replaced by a numeric value and %2 will be 'days' or 'months', for example (Expires in [S]10[/S] days)");
    bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"(" withString:@""];
    bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@")" withString:@""];
    bonusExpiresIn = [bonusExpiresIn mnz_removeWebclientFormatters];
    
    if (awardExpirationdDate.daysUntil == 0) {
        bonusExpiresIn = AMLocalizedString(@"expired", @"Label to show that an error related with expiration occurs during a SDK operation.");
        self.bonusExpireInLabel.textColor = [UIColor mnz_redMainForTraitCollection:(self.traitCollection)];
        self.bonusExpireInView.layer.borderColor = [UIColor mnz_redMainForTraitCollection:(self.traitCollection)].CGColor;
    } else {
        self.bonusExpireInView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.14].CGColor;
        
        if (awardExpirationdDate.daysUntil > 30) {
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%zd", awardExpirationdDate.monthsUntil]];
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%2" withString:AMLocalizedString(@"months", @"Used to display the number of months a plan was purchased for e.g. 3 months, 6 months.")];
        } else {
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%zd", awardExpirationdDate.daysUntil]];
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%2" withString:AMLocalizedString(@"days", @"")];
        }
    }
    
    self.bonusExpireInLabel.text = bonusExpiresIn;
}

@end
