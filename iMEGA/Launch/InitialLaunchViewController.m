
#import "InitialLaunchViewController.h"

#import "OnboardingViewController.h"
#import "MEGA-Swift.h"

@interface InitialLaunchViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *setupButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (nonatomic) BOOL logoMoved;
@property (nonatomic) BOOL shouldMoveLogo;

@end

@implementation InitialLaunchViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    self.titleLabel.text = AMLocalizedString(@"Setup MEGA", @"Button which triggers the initial setup");
    self.descriptionLabel.text = AMLocalizedString(@"To fully take advantage of your MEGA account we need to ask you some permissions.", @"Detailed explanation of why the user should give some permissions to MEGA");
    [self.setupButton setTitle:AMLocalizedString(@"Setup MEGA", @"Button which triggers the initial setup") forState:UIControlStateNormal];
    [self.skipButton setTitle:AMLocalizedString(@"skipButton", @"Button title that skips the current action") forState:UIControlStateNormal];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (!self.logoMoved) {
        return;
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self moveLogo];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self centerLabels];
    }];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIDevice.currentDevice.iPhoneDevice) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager setupAppearance:self.traitCollection];

            [self updateAppearance];
            if (self.logoMoved) {
                self.shouldMoveLogo = YES;
            }
        }
    }
}

- (void)didBecomeActive {
    if (self.shouldMoveLogo) {
        self.shouldMoveLogo = NO;
        [self moveLogo];
        [self centerLabels];
    }
}

#pragma mark - Private

- (void)moveLogo {
    CGFloat newY = MIN(self.logoImageView.frame.origin.x, 145.0f);
    self.logoImageView.frame = CGRectMake(self.logoImageView.frame.origin.x, newY, self.logoImageView.frame.size.width, self.logoImageView.frame.size.height);
}

- (void)centerLabels {
    CGFloat bottomSeparation = 28.0f;
    CGFloat verticalIncrement = (self.titleLabel.frame.origin.y - (self.logoImageView.frame.origin.y + self.logoImageView.frame.size.height) - bottomSeparation) / 2;
    
    CGRect titleFrame = self.titleLabel.frame;
    titleFrame.origin.y -= verticalIncrement;
    self.titleLabel.frame = titleFrame;
    
    CGRect descriptionFrame = self.descriptionLabel.frame;
    descriptionFrame.origin.y -= verticalIncrement;
    self.descriptionLabel.frame = descriptionFrame;
}

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.descriptionLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    [self.setupButton mnz_setupPrimary:self.traitCollection];
    [self.skipButton mnz_setupBasic:self.traitCollection];
}

#pragma mark - Public

- (void)performAnimation {
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.circularShapeLayer.hidden = YES;
        [self moveLogo];
    } completion:^(BOOL finished) {
        [self centerLabels];
        self.titleLabel.hidden = self.descriptionLabel.hidden = NO;
        self.setupButton.hidden = self.skipButton.hidden = NO;
        self.activityIndicatorView.hidden = YES;
        self.logoMoved = YES;
    }];
}

#pragma mark - IBActions

- (IBAction)setupButtonPressed:(UIButton *)sender {
    OnboardingViewController *setupVC = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypePermissions];
    setupVC.completion = ^{
        [self.delegate setupFinished];
        [self.delegate readyToShowRecommendations];
    };
    if (@available(iOS 13.0, *)) {
        setupVC.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:setupVC animated:NO completion:^{
        self.titleLabel.hidden = self.descriptionLabel.hidden = YES;
        self.setupButton.hidden = self.skipButton.hidden = YES;
    }];
}

- (IBAction)skipButtonPressed:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"The MEGA app may not work as expected without the required permissions. Are you sure?", @"Message warning the user about the risk of not setting up permissions") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate setupFinished];
        [self.delegate readyToShowRecommendations];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"no", nil) style:UIAlertActionStyleCancel handler:nil]];

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
