#import "AchievementsDetailsViewController.h"
#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@import MEGAL10nObjc;

@interface AchievementsDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImageView;

@end

@implementation AchievementsDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureImages];
    [self setupTitleImage];
    [self setupView];
    [self setupColors];
}

#pragma mark - IBActions

- (IBAction)tapAddPhoneNumberButton:(id)sender {
    [self showAddPhoneNumber];
}

#pragma mark - Private

- (void)configureImages {
    self.checkImageView.image = [UIImage megaImageWithNamed:@"achievementsCheck"];
}

- (void)setupTitleImage {
    UIImage *achievementImage;
    switch (self.achievementClass) {
        case MEGAAchievementWelcome: {
            self.navigationItem.title = LocalizedString(@"account.achievement.registration.title", @"");
            achievementImage = [UIImage megaImageWithNamed:@"achievementsRegistration"];
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            self.navigationItem.title = LocalizedString(@"account.achievement.desktopApp.title", @"");
            achievementImage = [UIImage megaImageWithNamed:@"achievementsInstallMega"];
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            self.navigationItem.title = LocalizedString(@"account.achievement.mobileApp.title", @"");
            achievementImage = [UIImage megaImageWithNamed:@"achievementsInstallMobile"];
            break;
        }

        case MEGAAchievementVPNFreeTrial:
            self.navigationItem.title = LocalizedString(@"account.achievement.vpnFreeTrial.title", @"");
            achievementImage = [UIImage megaImageWithNamed:@"achievementsFreeTrialVPN"];
            break;

        case MEGAAchievementPassFreeTrial:
            self.navigationItem.title = LocalizedString(@"account.achievement.passFreeTrial.title", @"");
            achievementImage = [UIImage megaImageWithNamed:@"achievementsFreeTrialPass"];
            break;

        default:
            break;
    }
    self.achievementImageView.image = achievementImage.imageFlippedForRightToLeftLayoutDirection;
    self.checkImageView.hidden = self.completedAchievementIndex == nil;
}

@end
