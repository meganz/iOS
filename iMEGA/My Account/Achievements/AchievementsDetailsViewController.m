
#import "AchievementsDetailsViewController.h"
#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@interface AchievementsDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImageView;

@property (weak, nonatomic) IBOutlet UIView *howItWorksTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *howItWorksView;

@property (weak, nonatomic) IBOutlet UILabel *howItWorksCompletedExplanationLabel;

@end

@implementation AchievementsDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTitleImage];
    [self setupView];
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
    [self showAddPhoneNumber];
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

        default:
            break;
    }
    self.achievementImageView.image = achievementImage.imageFlippedForRightToLeftLayoutDirection;
    self.checkImageView.hidden = self.completedAchievementIndex == nil;
}

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.subtitleView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    
    self.howItWorksTopSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.howItWorksView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    [self.addPhoneNumberButton mnz_setupPrimary:self.traitCollection];
}

@end
