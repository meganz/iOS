#import "OnboardingViewController.h"
#import "OnboardingView.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface OnboardingViewController () <UIScrollViewDelegate>

@property (nonatomic) OnboardingType type;

@property (weak, nonatomic) IBOutlet UIStackView *topStackView;

@end

@implementation OnboardingViewController

#pragma mark - Initialization

+ (OnboardingViewController *)instantiateOnboardingWithType:(OnboardingType)type {
    OnboardingViewController *onboardingViewController = [[UIStoryboard storyboardWithName:@"Onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"OnboardingViewControllerID"];
    onboardingViewController.type = type;
    
    return onboardingViewController;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    self.primaryButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.secondaryButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    
    DevicePermissionsHandlerObjC *permissionHandler = [[DevicePermissionsHandlerObjC alloc] init];

    switch (self.type) {
        case OnboardingTypeDefault:
            [self.pageControl addTarget:self action:@selector(pageControlValueChanged) forControlEvents:UIControlEventValueChanged];
            
            [self.primaryButton setTitle:LocalizedString(@"createAccount", @"Button title which triggers the action to create a MEGA account") forState:UIControlStateNormal];
            
            [self.secondaryButton setTitle:LocalizedString(@"login", @"Button title which triggers the action to login in your MEGA account") forState:UIControlStateNormal];

            [self setupTertiaryButton];
            [self.tertiaryButton setTitle:LocalizedString(@"general.joinMeetingAsGuest", @"Button title which triggers the action to join meeting as Guest") forState:UIControlStateNormal];

            if (self.topStackView.arrangedSubviews.count == 4) {
                OnboardingView *onboardingViewEncryption = self.topStackView.arrangedSubviews.firstObject;
                onboardingViewEncryption.type = OnboardingViewTypeEncryptionInfo;
                OnboardingView *onboardingViewChat = self.topStackView.arrangedSubviews[1];
                onboardingViewChat.type = OnboardingViewTypeChatInfo;
                OnboardingView *onboardingViewContacts = self.scrollView.subviews.firstObject.subviews[2];
                onboardingViewContacts.type = OnboardingViewTypeContactsInfo;
                OnboardingView *onboardingViewCameraUploads = self.scrollView.subviews.firstObject.subviews[3];
                onboardingViewCameraUploads.type = OnboardingViewTypeCameraUploadsInfo;
                [self.pageControl setNumberOfPages: self.topStackView.arrangedSubviews.count];
            }
            
            break;
            
        case OnboardingTypePermissions:
            self.scrollView.userInteractionEnabled = NO;
            self.pageControl.hidden = YES;
            self.secondaryButton.hidden = YES;
            self.tertiaryButton.hidden = YES;
            [self.primaryButton setTitle:LocalizedString(@"continue", @"'Next' button in a dialog") forState:UIControlStateNormal];
            
            
            int nextIndex = 0;
            if ([permissionHandler shouldAskForPhotosPermissions]) {
                OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                onboardingView.type = OnboardingViewTypePhotosPermission;
                nextIndex++;
            } else {
                [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            }
            
            [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            
            if ([permissionHandler shouldAskForAudioPermissions] || [permissionHandler shouldAskForVideoPermissions]) {
                OnboardingView *onboardingView = self.scrollView.subviews.firstObject.subviews[nextIndex];
                onboardingView.type = OnboardingViewTypeMicrophoneAndCameraPermissions;
                nextIndex++;
            } else {
                [self.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
            }
            
            // shouldAskForNotificationsPermissionsWithHandler calls handler on the main thread
            __weak __typeof__(self) weakSelf = self;
            [permissionHandler shouldAskForNotificationsPermissionsWithHandler:^(BOOL shouldAskForNotificationPermission) {
                if (shouldAskForNotificationPermission) {
                    OnboardingView *onboardingView = weakSelf.scrollView.subviews.firstObject.subviews[nextIndex];
                    onboardingView.type = OnboardingViewTypeNotificationsPermission;
                    // no need to increment nextIndex as this is last check in the scope
                } else {
                    [weakSelf.scrollView.subviews.firstObject.subviews[nextIndex] removeFromSuperview];
                }
                weakSelf.pageControl.numberOfPages = weakSelf.scrollView.subviews.firstObject.subviews.count;
            }];
            break;
    }
    
    self.scrollView.delegate = self;
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        
        [self updateAppearance];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Rotation

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
        [self.primaryButton setTitle:LocalizedString(@"continue", @"'Next' button in a dialog") forState:UIControlStateNormal];
        self.secondaryButton.hidden = YES;
    }
}

- (void)nextPageOrDismiss {
    NSUInteger nextPage = self.pageControl.currentPage + 1;
    if (nextPage < self.pageControl.numberOfPages) {
        [self scrollTo:nextPage];
    } else {
        [self dismissViewControllerAnimated:YES completion:self.completion];
    }
}

#pragma mark - Targets

- (void)pageControlValueChanged {
    [self scrollTo:self.pageControl.currentPage];
}

#pragma mark - IBActions

- (IBAction)primaryButtonTapped:(UIButton *)sender {
    DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
    switch (self.type) {
        case OnboardingTypeDefault: {
            UINavigationController *createAccountNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CreateAccountNavigationControllerID"];
            createAccountNC.modalPresentationStyle = UIModalPresentationFullScreen;
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
                    [handler requestPhotoAlbumAccessPermissionsWithHandler:^(BOOL granted) {
                        [self nextPageOrDismiss];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeMicrophoneAndCameraPermissions: {
                    [handler requestAudioPermissionWithHandler:^(BOOL granted) {
                        [handler requestVideoPermissionWithHandler:^(BOOL granted) {
                            [self nextPageOrDismiss];
                        }];
                    }];
                    break;
                }
                    
                case OnboardingViewTypeNotificationsPermission: {
                    [handler notificationsPermissionWith:^(BOOL granted) {
                        if (granted) {
                            [UIApplication.sharedApplication registerForRemoteNotifications];
                        }
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
            loginNC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:loginNC animated:YES completion:nil];
            break;
        }
            
        case OnboardingTypePermissions:
            break;
    }
}

- (IBAction)tertiaryButtonTapped:(UIButton *)sender {
    switch (self.type) {
        case OnboardingTypeDefault: {
            [[[EnterMeetingLinkRouter alloc] initWithViewControllerToPresent:self isGuest:NO] start];
            break;
        }
            
        case OnboardingTypePermissions: {
            break;
        }
    }
}

#pragma mark - Public

- (void)presentLoginViewController {
    [self secondaryButtonTapped:nil];
}

- (void)presentCreateAccountViewController {
    if (self.type == OnboardingTypeDefault) {
        [self primaryButtonTapped:nil];
    } else {
        MEGALogDebug(@"Oboarding type is not default");
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger newPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.currentPage = newPage;
}

@end
