
#import "DocumentPickerViewController.h"

#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "LaunchViewController.h"
#import "MEGALogger.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGARequestDelegate.h"

#import "BrowserViewController.h"

#define kAppKey @"EVtjzb7R"
#define kUserAgent @"MEGAiOS"

@interface DocumentPickerViewController () <BrowserViewControllerDelegate, MEGARequestDelegate, MEGATransferDelegate, LTHPasscodeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *megaLogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@property (nonatomic) LaunchViewController *launchVC;
@property (nonatomic, getter=isFirstFetchNodesRequestUpdate) BOOL firstFetchNodesRequestUpdate;
@property (nonatomic, getter=isFirstAPI_EAGAIN) BOOL firstAPI_EAGAIN;
@property (nonatomic) NSTimer *timerAPI_EAGAIN;

@property (nonatomic) NSString *session;
@property (nonatomic) UIView *privacyView;

@property (nonatomic) BOOL pickerPresented;
@property (nonatomic) BOOL passcodePresented;

@end

@implementation DocumentPickerViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"logging"]) {
        [[MEGALogger sharedLogger] enableSDKlogs];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"logs"] path];
        if (![fileManager fileExistsAtPath:logsPath]) {
            [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [[MEGALogger sharedLogger] startLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.docExt.log"]];
    }
    
    [self copyDatabasesFromMainApp];
    
    self.pickerPresented = NO;
    self.passcodePresented = NO;
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    [self languageCompatibility];

#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [[MEGALogger sharedLogger] enableSDKlogs];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    // Add observers to get notified when the extension goes to background and comes back to foreground:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive)
                                                 name:NSExtensionHostWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)
                                                 name:NSExtensionHostDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)
                                                 name:NSExtensionHostDidEnterBackgroundNotification
                                               object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.pickerPresented) {
        [self configureUI];
    }
}

- (void)willResignActive {
    if (self.session) {
        if ([MEGAReachabilityManager isReachable]) {
            UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
            privacyVC.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
            self.privacyView = privacyVC.view;
            [self.view addSubview:self.privacyView];
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [self presentPasscode];
            } else {
                [self presentDocumentPicker];
            }
        }
    }
}

- (void)didBecomeActive {
    if (self.privacyView) {
        [self.privacyView removeFromSuperview];
        self.privacyView = nil;
    }
    
    if (self.session) {
        if ([LTHPasscodeViewController doesPasscodeExist] && !self.passcodePresented) {
            [self presentPasscode];
        }
    } else {
        [self configureUI];
    }
}

- (void)didEnterBackground {
    self.passcodePresented = NO;
}

#pragma mark - Language

- (void)languageCompatibility {
    NSString *languageCode = [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] objectForKey:@"languageCode"];
    if (languageCode) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageCode];
        [[MEGASdkManager sharedMEGASdk] setLanguageCode:languageCode];
    } else {
        NSString *currentLanguageID = [[LocalizationSystem sharedLocalSystem] getLanguage];
        
        if ([Helper isLanguageSupported:currentLanguageID]) {
            [[LocalizationSystem sharedLocalSystem] setLanguage:currentLanguageID];
        } else {
            [self setLanguage:currentLanguageID];
        }
    }
}

- (void)setLanguage:(NSString *)languageID {
    NSDictionary *componentsFromLocaleID = [NSLocale componentsFromLocaleIdentifier:languageID];
    NSString *languageDesignator = [componentsFromLocaleID valueForKey:NSLocaleLanguageCode];
    if ([Helper isLanguageSupported:languageDesignator]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageDesignator];
    } else {
        [self setSystemLanguage];
    }
}

- (void)setSystemLanguage {
    NSDictionary *globalDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"NSGlobalDomain"];
    NSArray *languages = [globalDomain objectForKey:@"AppleLanguages"];
    NSString *systemLanguageID = [languages objectAtIndex:0];
    
    if ([Helper isLanguageSupported:systemLanguageID]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:systemLanguageID];
        return;
    }
    
    NSDictionary *componentsFromLocaleID = [NSLocale componentsFromLocaleIdentifier:systemLanguageID];
    NSString *languageDesignator = [componentsFromLocaleID valueForKey:NSLocaleLanguageCode];
    if ([Helper isLanguageSupported:languageDesignator]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageDesignator];
    } else {
        [self setDefaultLanguage];
    }
}

- (void)setDefaultLanguage {
    [[MEGASdkManager sharedMEGASdk] setLanguageCode:@"en"];
    [[LocalizationSystem sharedLocalSystem] setLanguage:@"en"];
}

#pragma mark - Private

- (void)configureUI {
    [self configureProgressHUD];
    [SVProgressHUD setViewForExtension:self.view];
    self.session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (self.session) {
        // Common scenario, present the browser after passcode.
        [[LTHPasscodeViewController sharedUser] setDelegate:self];
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
            }
            [self presentPasscode];
        } else {
            [self loginToMEGA];
        }
    } else {
        // The user either needs to login or logged in before the current version of the MEGA app, so there is
        // no session stored in the shared keychain. In both scenarios, a ViewController from MEGA app is to be pushed.
        self.loginLabel.text = AMLocalizedString(@"openMEGAAndSignInToContinue", @"Text shown when you try to use a MEGA extension in iOS and you aren't logged");
        [self.openButton setTitle:AMLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
        self.megaLogoImageView.hidden = NO;
        self.loginLabel.hidden = NO;
        self.openButton.hidden = NO;
    }
}

- (void)configureProgressHUD {
    [SVProgressHUD setFont:[UIFont mnz_SFUIRegularWithSize:12.0f]];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setRingNoTextRadius:18.0];
    [SVProgressHUD setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [SVProgressHUD setForegroundColor:[UIColor mnz_gray666666]];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setHapticsEnabled:YES];
    
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hudSuccess"]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hudError"]];
}

- (NSString *)appGroupContainerURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"File Provider Storage"] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return storagePath;
}

- (void)documentReadyAtPath:(NSString *)path withBase64Handle:(NSString *)base64Handle{
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
    // URLByResolvingSymlinksInPath avoids the /private
    NSString *key = [[NSURL fileURLWithPath:path].URLByResolvingSymlinksInPath absoluteString];
    [mySharedDefaults setObject:base64Handle forKey:key];
    
    [self dismissGrantingAccessToURL:[NSURL fileURLWithPath:path]];
}

- (IBAction)openMegaTouchUpInside:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mega://#loginrequired"]];
}

- (void)loginToMEGA {
    self.navigationItem.title = @"MEGA";
    
    LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
    launchVC.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.launchVC = launchVC;
    [self.view addSubview:launchVC.view];
    
    [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:self.session delegate:self];
}

- (void)presentDocumentPicker {
    if (!self.pickerPresented) {
        UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:[NSBundle bundleForClass:BrowserViewController.class]];
        MEGANavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.browserAction = BrowserActionDocumentProvider;
        browserVC.browserViewControllerDelegate = self;
        
        [self addChildViewController:navigationController];
        [navigationController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:navigationController.view];
        self.pickerPresented = YES;
    }
    if (self.launchVC) {
        [self.launchVC.view removeFromSuperview];
        self.launchVC = nil;
    }    
}

- (void)presentPasscode {
    if (!self.passcodePresented) {
        LTHPasscodeViewController *passcodeVC = [LTHPasscodeViewController sharedUser];
        [passcodeVC showLockScreenOver:self.view.superview
                         withAnimation:YES
                            withLogout:YES
                        andLogoutTitle:AMLocalizedString(@"logoutLabel", nil)];
        
        [passcodeVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self presentViewController:passcodeVC animated:NO completion:nil];
        self.passcodePresented = YES;
    }
}

- (void)startTimerAPI_EAGAIN {
    self.timerAPI_EAGAIN = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showServersTooBusy) userInfo:nil repeats:NO];
}

- (void)invalidateTimerAPI_EAGAIN {
    [self.timerAPI_EAGAIN invalidate];
    
    self.launchVC.label.text = @"";
}

- (void)showServersTooBusy {
    self.launchVC.label.text = AMLocalizedString(@"takingLongerThanExpected", @"Message shown when you open the app and when it is logging in, you don't receive server response, that means that it may take some time until you log in");
}

- (void)copyDatabasesFromMainApp {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
    }
    
    NSURL *groupSupportURL = [[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"GroupSupport"];
    if (![fileManager fileExistsAtPath:groupSupportURL.path]) {
        [fileManager createDirectoryAtURL:groupSupportURL withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSDate *incomingDate = [self newestMegaclientModificationDateForDirectoryAtUrl:groupSupportURL];
    NSDate *extensionDate = [self newestMegaclientModificationDateForDirectoryAtUrl:applicationSupportDirectoryURL];
    
    if ([incomingDate compare:extensionDate] == NSOrderedDescending) {
        NSArray *applicationSupportContent = [fileManager contentsOfDirectoryAtPath:applicationSupportDirectoryURL.path error:&error];
        for (NSString *filename in applicationSupportContent) {
            if ([filename containsString:@"megaclient"]) {
                if(![fileManager removeItemAtPath:[applicationSupportDirectoryURL.path stringByAppendingPathComponent:filename] error:&error]) {
                    MEGALogError(@"Remove item at path failed with error: %@", error);
                }
            }
        }
        
        NSArray *groupSupportPathContent = [fileManager contentsOfDirectoryAtPath:groupSupportURL.path error:&error];
        for (NSString *filename in groupSupportPathContent) {
            if ([filename containsString:@"megaclient"]) {
                if (![fileManager copyItemAtURL:[groupSupportURL URLByAppendingPathComponent:filename] toURL:[applicationSupportDirectoryURL URLByAppendingPathComponent:filename] error:&error]) {
                    MEGALogError(@"Copy item at path failed with error: %@", error);
                }
            }
        }
    }
}

- (NSDate *)newestMegaclientModificationDateForDirectoryAtUrl:(NSURL *)url {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDate *newestDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    NSArray *pathContent = [fileManager contentsOfDirectoryAtPath:url.path error:&error];
    for (NSString *filename in pathContent) {
        if ([filename containsString:@"megaclient"]) {
            NSDate *date = [[fileManager attributesOfItemAtPath:[url.path stringByAppendingPathComponent:filename] error:nil] fileModificationDate];
            if ([date compare:newestDate] == NSOrderedDescending) {
                newestDate = date;
            }
        }
    }
    return newestDate;
}

#pragma mark - BrowserViewControllerDelegate

- (void)didSelectNode:(MEGANode *)node {
    NSString *destinationPath = [self appGroupContainerURL];
    NSString *fileName = node.name;
    NSString *documentFilePath = [destinationPath stringByAppendingPathComponent:fileName];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:documentFilePath];
    if (fileExists) {
        // Because MEGA does not support file versioning yet, if the fingerprints are not equal we keep the cloud
        // version of the file deleting the local copy. If the file exists locally and the fingerprints are
        // the same, the local version may be used safely.
        // With file versioning, we may add the local copy to the array of versions before deleting it.
        NSString *localFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:documentFilePath];
        if ([localFingerprint isEqualToString:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:node]]) {
            [self documentReadyAtPath:documentFilePath withBase64Handle:node.base64Handle];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:documentFilePath error:nil];
            if ([Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];
            }
        }
    } else {
        if ([Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            self.launchVC.activityIndicatorView.hidden = NO;
            [self.launchVC.activityIndicatorView startAnimating];
            
            self.firstAPI_EAGAIN = YES;
            self.firstFetchNodesRequestUpdate = YES;
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeFetchNodes) {
        [self invalidateTimerAPI_EAGAIN];
        
        float progress = (request.transferredBytes.floatValue / request.totalBytes.floatValue);
        
        if (self.isFirstFetchNodesRequestUpdate) {
            [self.launchVC.activityIndicatorView stopAnimating];
            self.launchVC.activityIndicatorView.hidden = YES;
        
            [self.launchVC.logoImageView.layer addSublayer:self.launchVC.circularShapeLayer];
            self.launchVC.circularShapeLayer.strokeStart = 0.0f;
        }
        
        if (progress > 0 && progress <= 1.0) {
            self.launchVC.circularShapeLayer.strokeEnd = progress;
        }
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [self invalidateTimerAPI_EAGAIN];
            
            [api fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [self invalidateTimerAPI_EAGAIN];
            
            [self presentDocumentPicker];
            break;
        }
            
        default: {
            break;
        }
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch (request.type) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if (self.isFirstAPI_EAGAIN) {
                [self startTimerAPI_EAGAIN];
                self.firstAPI_EAGAIN = NO;
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue);
    if (percentage >= 0.01) {
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage * 100];
        [SVProgressHUD showProgress:percentage status:percentageCompleted];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    [self documentReadyAtPath:transfer.path withBase64Handle:[MEGASdk base64HandleForHandle:transfer.nodeHandle]];
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    [self dismissViewControllerAnimated:YES completion:^{
        self.passcodePresented = YES;
        if ([MEGAReachabilityManager isReachable]) {
            [self loginToMEGA];
        } else {
            [self presentDocumentPicker];
        }
    }];
}

- (void)maxNumberOfFailedAttemptsReached {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
}

@end
