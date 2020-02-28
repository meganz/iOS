
#import "InitialLaunchViewController.h"

#import "OnboardingViewController.h"

@interface InitialLaunchViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *setupButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (nonatomic) BOOL logoMoved;

@end

@implementation InitialLaunchViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateUI];
    
    self.titleLabel.text = AMLocalizedString(@"Setup MEGA", @"Button which triggers the initial setup");
    self.descriptionLabel.text = AMLocalizedString(@"To fully take advantage of your MEGA account we need to ask you some permissions.", @"Detailed explanation of why the user should give some permissions to MEGA");
    [self.setupButton setTitle:AMLocalizedString(@"Setup MEGA", @"Button which triggers the initial setup") forState:UIControlStateNormal];
    [self.skipButton setTitle:AMLocalizedString(@"skipButton", @"Button title that skips the current action") forState:UIControlStateNormal];
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
            [self updateUI];
        }
    }
}

#pragma mark - Private

- (void)performAnimation {
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.circularShapeLayer.hidden = YES;
        [self moveLogo];
    } completion:^(BOOL finished) {
        [self centerLabels];
        self.titleLabel.hidden = self.descriptionLabel.hidden = NO;
        self.setupButton.hidden = self.skipButton.hidden = NO;
        [self.activityIndicatorView stopAnimating];
        self.logoMoved = YES;
    }];
}

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

- (void)updateUI {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.descriptionLabel.textColor = [UIColor mnz_subtitlesColorForTraitCollection:self.traitCollection];
    
    self.setupButton.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    [self.setupButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.setupButton.layer.shadowColor = UIColor.blackColor.CGColor;
    
    self.skipButton.backgroundColor = [UIColor mnz_basicButtonForTraitCollection:self.traitCollection];
    [self.skipButton setTitleColor:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection]  forState:UIControlStateNormal];
    self.skipButton.layer.shadowColor = UIColor.blackColor.CGColor;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performAnimation];
        });
    }
}

@end
