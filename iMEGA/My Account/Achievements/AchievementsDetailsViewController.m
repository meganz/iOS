
#import "AchievementsDetailsViewController.h"

#import "NSDate+DateTools.h"
#import "UIColor+MNZCategory.h"

@interface AchievementsDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImageView;

@property (weak, nonatomic) IBOutlet UIView *bonusExpireInView;
@property (weak, nonatomic) IBOutlet UILabel *bonusExpireInLabel;

@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksExplanationLabel;

@property (weak, nonatomic) IBOutlet UILabel *howItWorksCompletedExplanationLabel;

@property (nonatomic) NSByteCountFormatter *byteCountFormatter;

@end

@implementation AchievementsDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.byteCountFormatter = [[NSByteCountFormatter alloc] init];
    self.byteCountFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
    
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
            howItWorksExplanationLabel = [registrationBonusExplanation stringByReplacingOccurrencesOfString:@"%1" withString:[self.byteCountFormatter stringFromByteCount:classStorageReward]];
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            navigationTitle = AMLocalizedString(@"installMEGASync", @"");
            achievementImage = [UIImage imageNamed:@"achievementsInstallMega"];
            
            NSString *installMEGASyncCompletedExplanation = AMLocalizedString(@"installMEGASyncCompletedExplanation", @"Message shown on the achievements dialog for achieved achievements, %1 and %2 are replaced with e.g. 20 GB");
            installMEGASyncCompletedExplanation = [installMEGASyncCompletedExplanation stringByReplacingOccurrencesOfString:@"%1" withString:[self.byteCountFormatter stringFromByteCount:classStorageReward]];
            howItWorksExplanationLabel = [installMEGASyncCompletedExplanation stringByReplacingOccurrencesOfString:@"%2" withString:[self.byteCountFormatter stringFromByteCount:classTransferReward]];
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            navigationTitle = AMLocalizedString(@"installOurMobileApp", @"");
            achievementImage = [UIImage imageNamed:@"achievementsInstallMobile"];
            
            NSString *installOurMobileAppCompletedExplanation = AMLocalizedString(@"installOurMobileAppCompletedExplanation", @"");
            installOurMobileAppCompletedExplanation = [installOurMobileAppCompletedExplanation stringByReplacingOccurrencesOfString:@"%1" withString:[self.byteCountFormatter stringFromByteCount:classStorageReward]];
            howItWorksExplanationLabel = [installOurMobileAppCompletedExplanation stringByReplacingOccurrencesOfString:@"%2" withString:[self.byteCountFormatter stringFromByteCount:classTransferReward]];
            break;
        }
            
        default:
            break;
    }
    
    self.navigationItem.title = navigationTitle;
    
    self.achievementImageView.image = achievementImage;
    
    [self setBonusExpireInLabelText];
    
    self.howItWorksLabel.hidden = YES;
    self.howItWorksExplanationLabel.hidden = YES;
    self.howItWorksCompletedExplanationLabel.text = howItWorksExplanationLabel;
    [self.howItWorksCompletedExplanationLabel sizeToFit];
}

#pragma - Private

- (void)setBonusExpireInLabelText {
    NSDate *awardExpirationdDate = [self.achievementsDetails awardExpirationAtIndex:self.index];
    NSString *bonusExpiresIn = AMLocalizedString(@"bonusExpiresIn", @"%1 will be replaced by a numeric value and %2 will be 'days' or 'months', for example (Expires in [S]10[/S] days)");
    bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"(" withString:@""];
    bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@")" withString:@""];
    bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"[S]" withString:@""];
    bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"[/S]" withString:@""];
    
    if (awardExpirationdDate.daysUntil == 0) {
        bonusExpiresIn = AMLocalizedString(@"expired", @"Label to show that an error related with expiration occurs during a SDK operation.");
        self.bonusExpireInLabel.textColor = [UIColor colorFromHexString:@"#F0373A"];
        self.bonusExpireInView.backgroundColor = self.bonusExpireInLabel.backgroundColor = [UIColor colorFromHexString:@"#FEF9F9"];
        
        self.bonusExpireInView.layer.borderColor = [UIColor colorFromHexString:@"#F0373A"].CGColor;
    } else {
        self.bonusExpireInView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.14].CGColor;
        
        if (awardExpirationdDate.daysUntil > 30) {
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%lu", awardExpirationdDate.monthsUntil]];
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%2" withString:AMLocalizedString(@"months", @"Used to display the number of months a plan was purchased for e.g. 3 months, 6 months.")];
        } else {
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%lu", awardExpirationdDate.daysUntil]];
            bonusExpiresIn = [bonusExpiresIn stringByReplacingOccurrencesOfString:@"%2" withString:AMLocalizedString(@"days", @"")];
        }
    }
    
    self.bonusExpireInLabel.text = bonusExpiresIn;
    
    self.bonusExpireInView.layer.borderWidth = 0.5f;
}

@end
