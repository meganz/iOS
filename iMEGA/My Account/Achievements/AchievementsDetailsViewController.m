#import "AchievementsDetailsViewController.h"
#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@import MEGAL10nObjc;

@interface AchievementsDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImageView;

@property (weak, nonatomic) IBOutlet UIView *howItWorksTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *howItWorksView;

@end

@implementation AchievementsDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTitleImage];
    [self setupView];
    [self setupColors];
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
            self.navigationItem.title = LocalizedString(@"account.achievement.registration.title", @"");
            achievementImage = [UIImage imageNamed:@"achievementsRegistration"];
            break;
        }
            
        case MEGAAchievementDesktopInstall: {
            self.navigationItem.title = LocalizedString(@"account.achievement.desktopApp.title", @"");
            achievementImage = [UIImage imageNamed:@"achievementsInstallMega"];
            break;
        }
            
        case MEGAAchievementMobileInstall: {
            self.navigationItem.title = LocalizedString(@"account.achievement.mobileApp.title", @"");
            achievementImage = [UIImage imageNamed:@"achievementsInstallMobile"];
            break;
        }

        default:
            break;
    }
    self.achievementImageView.image = achievementImage.imageFlippedForRightToLeftLayoutDirection;
    self.checkImageView.hidden = self.completedAchievementIndex == nil;
}

- (void)setupColors {
    self.view.backgroundColor = [self defaultBackgroundColor];
    self.subtitleView.backgroundColor = [self defaultBackgroundColor];
    self.howItWorksTopSeparatorView.backgroundColor = [self separatorColor];
    self.howItWorksView.backgroundColor = [self defaultBackgroundColor];
    [self.addPhoneNumberButton mnz_setupPrimary];
}

@end
