#import "InitialLaunchViewController.h"

#import "OnboardingViewController.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface InitialLaunchViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *setupButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@end

@implementation InitialLaunchViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    self.titleLabel.text = LocalizedString(@"Setup MEGA", @"Button which triggers the initial setup");
    self.descriptionLabel.text = LocalizedString(@"To fully take advantage of your MEGA account we need to ask you some permissions.", @"Detailed explanation of why the user should give some permissions to MEGA");
    [self.setupButton setTitle:LocalizedString(@"Setup MEGA", @"Button which triggers the initial setup") forState:UIControlStateNormal];
    [self.skipButton setTitle:LocalizedString(@"skipButton", @"Button title that skips the current action") forState:UIControlStateNormal];
    
    self.setupButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.skipButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    
    [self createViewModel];
    self.setupButton.hidden = self.skipButton.hidden = !self.showViews;
    self.titleLabel.hidden = self.descriptionLabel.hidden = !self.showViews;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    self.titleLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor mnz_secondaryTextColor];
    
    [self.setupButton mnz_setupPrimary:self.traitCollection];
    [self.skipButton mnz_setupSecondary:self.traitCollection];
}

#pragma mark - Public

- (void)performAnimation {
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.circularShapeLayer.hidden = YES;
    } completion:^(BOOL finished) {
        self.titleLabel.hidden = self.descriptionLabel.hidden = NO;
        self.setupButton.hidden = self.skipButton.hidden = NO;
    }];
}

#pragma mark - IBActions

- (IBAction)setupButtonPressed:(UIButton *)sender {
    [self didTapSetupButton];
    
    OnboardingViewController *setupVC = [OnboardingViewController instantiateOnboardingWithType:OnboardingTypePermissions];
    setupVC.completion = ^{
        [self.delegate setupFinished];
        [self.delegate readyToShowRecommendations];
    };
    setupVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:setupVC animated:NO completion:^{
        self.titleLabel.hidden = self.descriptionLabel.hidden = YES;
        self.setupButton.hidden = self.skipButton.hidden = YES;
    }];
}

- (IBAction)skipButtonPressed:(UIButton *)sender {
    [self didTapSkipSetupButton];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"attention", @"Alert title to attract attention") message:LocalizedString(@"The MEGA app may not work as expected without the required permissions. Are you sure?", @"Message warning the user about the risk of not setting up permissions") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"yes", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate setupFinished];
        [self.delegate readyToShowRecommendations];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"no", @"") style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (request.type == MEGARequestTypeFetchNodes) {
        [self performAnimation];
    }
}

@end
