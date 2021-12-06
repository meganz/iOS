
#import "OnboardingViewController.h"

#import "DevicePermissionsHelper.h"
#import "OnboardingView.h"
#import "MEGA-Swift.h"

@interface OnboardingViewController () <UIScrollViewDelegate>

@property (nonatomic) OnboardingType type;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;
@property (weak, nonatomic) IBOutlet UIButton *secondaryButton;
@property (weak, nonatomic) IBOutlet UIButton *thirdButton;

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
    
    [self updateAppearance];
    
    self.primaryButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.secondaryButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    
    switch (self.type) {
        case OnboardingTypeDefault:
            [self.pageControl addTarget:self action:@selector(pageControlValueChanged) forControlEvents:UIControlEventValueChanged];
            
            [self.primaryButton setTitle:NSLocalizedString(@"createAccount", @"Button title which triggers the action to create a MEGA account") forState:UIControlStateNormal];
            
            [self.secondaryButton setTitle:NSLocalizedString(@"login", @"Button title which triggers the action to login in your MEGA account") forState:UIControlStateNormal];
           
            [self.thirdButton setTitle:NSLocalizedString(@"Join Meeting as Guest", @"Button title which triggers the action to join meeting as Guest") forState:UIControlStateNormal];

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
            self.secondaryButton.hidden = YES;
            self.thirdButton.hidden = YES;
            [self.primaryButton setTitle:NSLocalizedString(@"continue", @"'Next' button in a dialog") forState:UIControlStateNormal];
            
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
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        
        [self updateAppearance];
    }
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
        [self.primaryButton setTitle:NSLocalizedString(@"continue", @"'Next' button in a dialog") forState:UIControlStateNormal];
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

- (void)updateAppearance {
    self.view.backgroundColor = self.scrollView.backgroundColor = UIColor.mnz_background;
    
    self.pageControl.currentPageIndicatorTintColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    self.pageControl.pageIndicatorTintColor = [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection];
    self.pageControl.backgroundColor = UIColor.mnz_background;
    
    [self.primaryButton mnz_setupPrimary:self.traitCollection];
    [self.secondaryButton mnz_setupBasic:self.traitCollection];
    [self.thirdButton setTitleColor:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection] forState:UIControlStateNormal];

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

- (IBAction)thirdButtonTapped:(UIButton *)sender {
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
