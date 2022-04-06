
#import "AchievementsDetailsViewController.h"
#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@import DateToolsObjc;

@interface AchievementsDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImageView;

@property (weak, nonatomic) IBOutlet UIView *subtitleView;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIView *howItWorksTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *howItWorksView;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksExplanationLabel;

@property (weak, nonatomic) IBOutlet UILabel *howItWorksCompletedExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *addPhoneNumberButton;

@end

@implementation AchievementsDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTitleImage];
    
    if (self.completedAchievementIndex != nil) {
        [self setupCompletedAchievementDetail];
    } else {
        [self setupIncompletedAchievementDetail];
    }
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - IBActions

- (IBAction)tapAddPhoneNumberButton:(id)sender {
    [[[SMSVerificationViewRouter alloc] initWithVerificationType:SMSVerificationTypeAddPhoneNumber presenter:self] start];
}

#pragma mark - Private

- (void)setupTitleImage {
    UIImage *achievementImage;
    switch (self.achievementClass) {
        case MEGAAchievementWelcome: {
            self.navigationItem.title = NSLocalizedString(@"account.achievement.registration.title", nil);
            achievementImage = [UIImage imageNamed:@"achievementsRegistration"];
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            self.navigationItem.title = NSLocalizedString(@"account.achievement.desktopApp.title", nil);
            achievementImage = [UIImage imageNamed:@"achievementsInstallMega"];
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            self.navigationItem.title = NSLocalizedString(@"account.achievement.mobileApp.title", nil);
            achievementImage = [UIImage imageNamed:@"achievementsInstallMobile"];
            break;
        }
            
        case MEGAAchievementAddPhone: {
            self.navigationItem.title = NSLocalizedString(@"Add Phone Number", nil);
            achievementImage = [UIImage imageNamed:@"addPhoneNumberSmall"];
            break;
        }

        default:
            break;
    }
    self.achievementImageView.image = achievementImage.imageFlippedForRightToLeftLayoutDirection;
    self.checkImageView.hidden = self.completedAchievementIndex == nil;
}

- (void)setupCompletedAchievementDetail {
    NSInteger awardId = [self.achievementsDetails awardIdAtIndex:[self.completedAchievementIndex unsignedIntegerValue]];
    NSString *storageRewardString = [Helper memoryStyleStringFromByteCount:[self.achievementsDetails rewardStorageByAwardId:awardId]];
    NSString *howItWorksCompletedExplanation = @"";
    switch (self.achievementClass) {
        case MEGAAchievementWelcome: {
            howItWorksCompletedExplanation = NSLocalizedString(@"account.achievement.registration.explanation.label", nil);
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            howItWorksCompletedExplanation = NSLocalizedString(@"account.achievement.desktopApp.complete.explaination.label", nil);
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            howItWorksCompletedExplanation = NSLocalizedString(@"account.achievement.mobileApp.complete.explaination.label", nil);
            break;
        }
            
        case MEGAAchievementAddPhone: {
            howItWorksCompletedExplanation = NSLocalizedString(@"account.achievement.phoneNumber.complete.explaination.label", nil);
            break;
        }

        default:
            break;
    }
    [self setBonusExpireInLabelText];
    self.howItWorksCompletedExplanationLabel.text = [NSString stringWithFormat:howItWorksCompletedExplanation, storageRewardString];
}

- (void)setupIncompletedAchievementDetail {
    self.subtitleView.layer.borderWidth = 0;
    NSString *storageString = [Helper memoryStyleStringFromByteCount:[self.achievementsDetails classStorageForClassId:self.achievementClass]];
    self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"account.achievement.incomplete.subtitle", nil), storageString];
    
    self.howItWorksLabel.text = NSLocalizedString(@"howItWorks", nil);
    
    NSString *howItWorksExplanation = @"";
    switch (self.achievementClass) {
        case MEGAAchievementDesktopInstall: {
            howItWorksExplanation = NSLocalizedString(@"account.achievement.desktopApp.incomplete.explaination.label", nil);
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            howItWorksExplanation = NSLocalizedString(@"account.achievement.mobileApp.incomplete.explaination.label", nil);
            break;
        }
            
        case MEGAAchievementAddPhone: {
            self.addPhoneNumberButton.hidden = NO;
            howItWorksExplanation = NSLocalizedString(@"account.achievement.phoneNumber.incomplete.explaination.label", nil);
            break;
        }

        default:
            break;
    }
    self.howItWorksExplanationLabel.text = [NSString stringWithFormat:howItWorksExplanation, storageString];
}

- (void)setBonusExpireInLabelText {
    NSDate *awardExpirationdDate = [self.achievementsDetails awardExpirationAtIndex:[self.completedAchievementIndex unsignedIntegerValue]];
    NSString *bonusExpiresIn = @"";
    
    if (awardExpirationdDate.daysUntil == 0) {
        bonusExpiresIn = NSLocalizedString(@"Expired", nil);
        self.subtitleLabel.textColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
        self.subtitleView.layer.borderColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)].CGColor;
    } else {
        bonusExpiresIn = [NSString stringWithFormat:NSLocalizedString(@"account.achievement.complete.valid.detail.subtitle", nil), [NSString stringWithFormat:@"%zd", awardExpirationdDate.daysUntil]];
        self.subtitleView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.14].CGColor;
    }
    
    self.subtitleLabel.text = bonusExpiresIn;
}

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.subtitleView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    
    self.howItWorksTopSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.howItWorksView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    [self.addPhoneNumberButton mnz_setupPrimary:self.traitCollection];
}

@end
