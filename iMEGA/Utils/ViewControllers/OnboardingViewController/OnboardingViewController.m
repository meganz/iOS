
#import "OnboardingViewController.h"

#import "DevicePermissionsHelper.h"
#import "OnboardingView.h"
#import "MEGA-Swift.h"

@interface OnboardingViewController () <UIScrollViewDelegate>

@property (nonatomic) OnboardingType type;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *pageLabel;
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;
@property (weak, nonatomic) IBOutlet UIButton *secondaryButton;

@end

@implementation OnboardingViewController

#pragma mark - Initialization

+ (OnboardingViewController *)instanciateOnboardingWithType:(OnboardingType)type {
    OnboardingViewController *onboardingViewController = [[UIStoryboard storyboardWithName:@"Onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"OnboardingViewControllerID"];
    onboardingViewController.type = type;
    
    return onboardingViewController;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateUI];
    
    switch (self.type) {
        case OnboardingTypeDefault:
            [self.pageControl addTarget:self action:@selector(pageControlValueChanged) forControlEvents:UIControlEventValueChanged];
            
            [self.primaryButton setTitle:AMLocalizedString(@"createAccount", @"Button title which triggers the action to create a MEGA account") forState:UIControlStateNormal];
            
            [self.secondaryButton setTitle:AMLocalizedString(@"login", @"Button title which triggers the action to login in your MEGA account") forState:UIControlStateNormal];
            
            if (self.scrollView.subviews.firstObject.subviews.count == 4) {
                OnboardingView *onboardingViewEncryption = self.scrollView.subviews.firstObject.subviews.firstObject;
                onboardingViewEncryption.type = OnboardingViewTypeEncryptionInfo;
                OnboardingView *onboardingViewChat = self.scrollView.subviews.firstObject.subviews[1];
                onboardingViewChat.type = OnboardingViewTypeChatInfo;
                OnboardingView *onboardingViewContacts = self.scrollView.subviews.firstObject.subviews[2];
                onboardingViewContacts.type = OnboardingViewTypeContactsInfo;
                OnboardingView *onboardingViewCameraUploads = self.scrollView.subviews.firstObject.subviews[3];
                onboardingViewCameraUploads.type = OnboardingViewTypeCameraUploadsInfo;
            }
            
            break;
            
        case OnboardingTypePermissions:
            self.scrollView.userInteractionEnabled = NO;
            self.pageControl.hidden = YES;
            
            [self.primaryButton setTitle:AMLocalizedString(@"Allow Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand") forState:UIControlStateNormal];
            
            [self.secondaryButton setTitle:AMLocalizedString(@"notNow", nil) forState:UIControlStateNormal];
            
            int nextIndex = 0;
            if (DevicePermissionsHelper.shouldAskForPhotosPermissions) {
                OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                onboardingView.type = OnboardingViewTypePhotosPermission;
                nextIndex++;
            } else {
                [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            }
            
            if (DevicePermissionsHelper.shouldAskForContactsPermissions) {
                OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                onboardingView.type = OnboardingViewTypeContactsPermission;
                nextIndex++;
            } else {
                [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            }
            
            if (DevicePermissionsHelper.shouldAskForAudioPermissions || DevicePermissionsHelper.shouldAskForVideoPermissions) {
                OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                onboardingView.type = OnboardingViewTypeMicrophoneAndCameraPermissions;
                nextIndex++;
            } else {
                [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            }
            
            if (DevicePermissionsHelper.shouldAskForNotificationsPermissions) {
                OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                onboardingView.type = OnboardingViewTypeNotificationsPermission;
                nextIndex++;
            } else {
                [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            }
            
            self.pageLabel.text = [[AMLocalizedString(@"%1 of %2", @"Shows number of the current page. '%1' will be replaced by current page number. '%2' will be replaced by number of all pages.") stringByReplacingOccurrencesOfString:@"%1" withString:@"1"] stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%tu", self.scrollView.subviews.firstObject.subviews.count]];
            self.pageLabel.hidden = NO;
            
            break;
    }
    
    self.scrollView.delegate = self;
    self.pageControl.numberOfPages = self.scrollView.subviews.firstObject.subviews.count;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager setupAppearance:self.traitCollection];
            [AppearanceManager invalidateViews];
            
            [self updateUI];
        }
    }
}

#pragma mark - Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIDevice.currentDevice.iPhoneDevice) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self scrollTo:self.pageControl.currentPage];
    } completion:nil];
}

#pragma mark - Private

- (void)scrollTo:(NSUInteger)page {
    CGFloat newX = (CGFloat)page * self.scrollView.frame.size.width;
    BOOL animated = self.type == OnboardingTypeDefault;
    [self.scrollView setContentOffset:CGPointMake(newX, 0.0f) animated:animated];
    self.pageControl.currentPage = page;
    
    OnboardingView *currentView = self.scrollView.subviews.firstObject.subviews[page];
    if (currentView.type == OnboardingViewTypeNotificationsPermission) {
        [self.primaryButton setTitle:AMLocalizedString(@"continue", @"'Next' button in a dialog") forState:UIControlStateNormal];
        self.secondaryButton.hidden = YES;
    }
    
    self.pageLabel.text = [[AMLocalizedString(@"%1 of %2", @"Shows number of the current page. '%1' will be replaced by current page number. '%2' will be replaced by number of all pages.") stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%td", page + 1]] stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%tu", self.scrollView.subviews.firstObject.subviews.count]];
}

- (void)nextPageOrDismiss {
    NSUInteger nextPage = self.pageControl.currentPage + 1;
    if (nextPage < self.pageControl.numberOfPages) {
        [self scrollTo:nextPage];
    } else {
        [self dismissViewControllerAnimated:YES completion:self.completion];
    }
}

- (void)updateUI {
    self.view.backgroundColor = self.scrollView.backgroundColor = UIColor.mnz_background;
    
    self.pageControl.currentPageIndicatorTintColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    self.pageControl.pageIndicatorTintColor = [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection];
    self.pageControl.backgroundColor = UIColor.mnz_background;
    
    self.primaryButton.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    [self.primaryButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.primaryButton.layer.shadowColor = UIColor.blackColor.CGColor;
    
    self.secondaryButton.backgroundColor = [UIColor mnz_basicButtonForTraitCollection:self.traitCollection];
    [self.secondaryButton setTitleColor:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection]  forState:UIControlStateNormal];
    self.secondaryButton.layer.shadowColor = UIColor.blackColor.CGColor;
}

#pragma mark - Targets

- (void)pageControlValueChanged {
    [self scrollTo:self.pageControl.currentPage];
}

#pragma mark - IBActions

- (IBAction)primaryButtonTapped:(UIButton *)sender {
    switch (self.type) {
        case OnboardingTypeDefault: {
            UINavigationController *createAccountNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CreateAccountNavigationControllerID"];
            if (@available(iOS 13.0, *)) {
                createAccountNC.modalPresentationStyle = UIModalPresentationFullScreen;
            }
            [self presentViewController:createAccountNC animated:YES completion:nil];
            break;
        }
            
        case OnboardingTypePermissions: {
            if (self.scrollView.subviews.firstObject.subviews.count <= self.pageControl.currentPage) {
                return;
            }
            
            OnboardingView *currentView = self.scrollView.subviews.firstObject.subviews[self.pageControl.currentPage];
            switch (currentView.type) {
                case OnboardingViewTypePhotosPermission: {
                    [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
                        [self nextPageOrDismiss];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeContactsPermission: {
                    [DevicePermissionsHelper contactsPermissionWithCompletionHandler:^(BOOL granted) {
                        [self nextPageOrDismiss];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeMicrophoneAndCameraPermissions: {
                    [DevicePermissionsHelper audioPermissionModal:NO forIncomingCall:NO withCompletionHandler:^(BOOL granted) {
                        [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                            [self nextPageOrDismiss];
                        }];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeNotificationsPermission: {
                    [DevicePermissionsHelper notificationsPermissionWithCompletionHandler:^(BOOL granted) {
                        [self nextPageOrDismiss];
                    }];
                    break;
                }
                    
                default:
                    [self nextPageOrDismiss];
                    break;
            }
            break;
        }
    }
}

- (IBAction)secondaryButtonTapped:(UIButton *)sender {
    switch (self.type) {
        case OnboardingTypeDefault: {
            UINavigationController *loginNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginNavigationControllerID"];
            if (@available(iOS 13.0, *)) {
                loginNC.modalPresentationStyle = UIModalPresentationFullScreen;
            }
            [self presentViewController:loginNC animated:YES completion:nil];
            break;
        }
            
        case OnboardingTypePermissions:
            [self nextPageOrDismiss];
            break;
    }
}

#pragma mark - Public

- (void)presentLoginViewController {
    [self secondaryButtonTapped:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger newPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.currentPage = newPage;
}

@end
