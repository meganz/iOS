
#import "DocumentPickerViewController.h"
#import <PureLayout/PureLayout.h>
#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "LaunchViewController.h"
#import "MEGALogger.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGARequestDelegate.h"
#import "NSFileManager+MNZCategory.h"
#import "BrowserViewController.h"

@interface DocumentPickerViewController () <BrowserViewControllerDelegate, MEGARequestDelegate, MEGATransferDelegate, LTHPasscodeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *megaLogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@property (nonatomic) LaunchViewController *launchVC;

@property (nonatomic) NSString *session;
@property (nonatomic) UIView *privacyView;

@property (nonatomic) BOOL pickerPresented;
@property (nonatomic) BOOL passcodePresented;

@property (nonatomic) NSDate *lastProgressChange;

@end

@implementation DocumentPickerViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [MEGASdk setLogToConsole:YES];
    
    if ([[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] boolForKey:@"logging"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionLogsFolder] path];
        if (![fileManager fileExistsAtPath:logsPath]) {
            [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [[MEGALogger sharedLogger] startLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.docExt.log"]];
    }
    
    [self copyDatabasesFromMainApp];
    
    self.pickerPresented = NO;
    self.passcodePresented = NO;
    
    [self languageCompatibility];

#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
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
    
    self.lastProgressChange = [NSDate new];
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
            privacyVC.view.backgroundColor = UIColor.mnz_background;
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
    if ([self.presentedViewController isKindOfClass:LTHPasscodeViewController.class]) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    self.passcodePresented = NO;
}

#pragma mark - Language

- (void)languageCompatibility {
    NSString *languageCode = [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] objectForKey:@"languageCode"];
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
    NSString *systemLanguageID = languages.firstObject;
    
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
            if ([NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps]) {
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
    [SVProgressHUD setFont:[UIFont systemFontOfSize:12.0f]];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setRingNoTextRadius:18.0];
    [SVProgressHUD setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [SVProgressHUD setForegroundColor:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setHapticsEnabled:YES];
    
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hudSuccess"]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hudError"]];
}

- (NSString *)appGroupContainerURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAFileExtensionStorageFolder] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return storagePath;
}

- (void)documentReadyAtPath:(NSString *)path withBase64Handle:(NSString *)base64Handle{
    NSUserDefaults *mySharedDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    // URLByResolvingSymlinksInPath avoids the /private
    NSString *key = [[NSURL fileURLWithPath:path].URLByResolvingSymlinksInPath absoluteString];
    [mySharedDefaults setObject:base64Handle forKey:key];
    
    [self dismissGrantingAccessToURL:[NSURL fileURLWithPath:path]];
}

- (IBAction)openMegaTouchUpInside:(id)sender {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"mega://#loginrequired"] options:@{} completionHandler:nil];
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
        BrowserViewController *browserVC = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserViewControllerID"];
        browserVC.browserAction = BrowserActionDocumentProvider;
        browserVC.browserViewControllerDelegate = self;
        [self addChildViewController:browserVC];
        [self.view addSubview:browserVC.view];
        [browserVC didMoveToParentViewController:self];
        [browserVC.view autoPinEdgesToSuperviewEdges];
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

- (void)copyDatabasesFromMainApp {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
    }
    
    NSURL *groupSupportURL = [[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionGroupSupportFolder];
    if (![fileManager fileExistsAtPath:groupSupportURL.path]) {
        [fileManager createDirectoryAtURL:groupSupportURL withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSDate *incomingDate = [self newestMegaclientModificationDateForDirectoryAtUrl:groupSupportURL];
    NSDate *extensionDate = [self newestMegaclientModificationDateForDirectoryAtUrl:applicationSupportDirectoryURL];
    
    if ([incomingDate compare:extensionDate] == NSOrderedDescending) {
        [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:applicationSupportDirectoryURL.path forItemsContaining:@"megaclient"];
        
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
    NSString *documentFilePath = [destinationPath stringByAppendingPathComponent:[node.base64Handle stringByAppendingPathComponent:fileName]];
    
    BOOL shouldOpenLocalFile = NO;
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:documentFilePath];
    if (fileExists) {
        NSString *localFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:documentFilePath];
        if ([localFingerprint isEqualToString:node.fingerprint]) {
            shouldOpenLocalFile = YES;
        } else {
            NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:documentFilePath error:nil];
            if (fileAttributes) {
                NSDate *localDate = [fileAttributes objectForKey:NSFileModificationDate];
                NSDate *remoteDate = node.modificationTime;
                if ([localDate compare:remoteDate] != NSOrderedAscending) {
                    shouldOpenLocalFile = YES;
                }
            }
        }
    }
    
    if (shouldOpenLocalFile) {
        [self documentReadyAtPath:documentFilePath withBase64Handle:node.base64Handle];
    } else {
        [NSFileManager.defaultManager mnz_removeItemAtPath:documentFilePath];
        if ([Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
            NSString *destinationFolder = [[self appGroupContainerURL] stringByAppendingPathComponent:node.base64Handle];
            if (![NSFileManager.defaultManager fileExistsAtPath:destinationFolder]) {
                if (![NSFileManager.defaultManager createDirectoryAtPath:destinationFolder withIntermediateDirectories:YES attributes:nil error:nil]) {
                    MEGALogError(@"Error creating destination folder");
                }
            }
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"fileTooBigMessage_open", @"Error message shown when you try to open something bigger than the free space in your device")];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [api fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes:
            [self presentDocumentPicker];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue);
    if (percentage >= 0.01) {
        NSDate *now = [NSDate new];
        if (!UIAccessibilityIsVoiceOverRunning() || [now timeIntervalSinceDate:self.lastProgressChange] > 2) {
            self.lastProgressChange = now;
            NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage * 100];
            [SVProgressHUD showProgress:percentage status:percentageCompleted];
        }
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
    if ([NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
}

@end
