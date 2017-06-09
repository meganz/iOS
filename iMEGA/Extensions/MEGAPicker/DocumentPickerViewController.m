
#import "DocumentPickerViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "BrowserViewController.h"
#import "Helper.h"
#import "LaunchViewController.h"
#import "MEGANavigationController.h"

#define kAppKey @"EVtjzb7R"
#define kUserAgent @"MEGAiOS"

@interface DocumentPickerViewController ()

@property (nonatomic) BOOL sessionLoaded;
@property (nonatomic) BOOL pickerPresented;
@property (nonatomic) BOOL passcodePresented;

@end

@implementation DocumentPickerViewController


- (void)viewDidLoad {
    self.sessionLoaded = NO;
    self.pickerPresented = NO;
    self.passcodePresented = NO;
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    // Add a observer to get notified when the extension come back to the foreground:
    if ([[UIDevice currentDevice] systemVersionGreaterThanOrEqualVersion:@"8.2"]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground)
                                                     name:NSExtensionHostWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive)
                                                     name:NSExtensionHostWillResignActiveNotification
                                                   object:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.pickerPresented) {
        [self configureUI];
    }
}

- (void)configureUI {
    [SVProgressHUD setViewForExtension:self.view];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    self.session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    
    if(self.session) {
        self.sessionLoaded = YES;
        // Common scenario, present the browser after passcode.
        [[LTHPasscodeViewController sharedUser] setDelegate:self];
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
            }
            [self presentPasscode];
        } else {
            [self presentDocumentPicker];
        }
        
    } else {
        // The user either needs to login or logged in before the current version of the MEGA app, so there is
        // no session stored in the shared keychain. In both scenarios, a ViewController from MEGA app is to be pushed.
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        [self.openMega setTitle:AMLocalizedString(@"openButton", @"Open MEGA button from the Document Provider") forState:UIControlStateNormal];
        self.megaLogo.hidden = NO;
        self.loginText.hidden= NO;
        self.openMega.hidden = NO;
    }
}

- (void)willEnterForeground {
    if(!self.sessionLoaded) {
        self.megaLogo.hidden = YES;
        self.loginText.hidden= YES;
        self.openMega.hidden = YES;
        [self configureUI];
    } else {
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            [self presentPasscode];
        }
        if (self.privacyView) {
            [self.privacyView removeFromSuperview];
            self.privacyView = nil;
        }
    }
}

- (void)willResignActive {
    UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
    [privacyVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    self.privacyView = privacyVC.view;
    [self.view addSubview:self.privacyView];
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
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.mega.ios"];
    // URLByResolvingSymlinksInPath avoids the /private
    NSString *key = [[NSURL fileURLWithPath:path].URLByResolvingSymlinksInPath absoluteString];
    [mySharedDefaults setObject:base64Handle forKey:key];
    
    [self dismissGrantingAccessToURL:[NSURL fileURLWithPath:path]];
}

- (IBAction)goToMega:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mega://#loginrequired"]];
}

- (void)presentDocumentPicker {
    self.navigationItem.title = @"MEGA";
    if (!self.pickerPresented) {
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:self.session delegate:self];
        
        UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud"
                                                                  bundle:[NSBundle bundleForClass:BrowserViewController.class]];
        MEGANavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        
        browserVC.selectedNodesArray = @[];
        [browserVC setBrowserAction:BrowserActionDocumentProvider];
        
        [self addChildViewController:navigationController];
        [navigationController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:navigationController.view];
        browserVC.browserViewControllerDelegate = self;
        self.pickerPresented = YES;
    }
}

- (void)presentPasscode {
    if (!self.passcodePresented) {
        LTHPasscodeViewController *passcodeVC = [LTHPasscodeViewController sharedUser];
        [passcodeVC showLockScreenIntoSuperview:self.view.superview
                                  WithAnimation:YES
                                     withLogout:YES
                                 andLogoutTitle:AMLocalizedString(@"logoutLabel", nil)];
        
        [passcodeVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self presentViewController:passcodeVC animated:NO completion:nil];
        self.passcodePresented = YES;
    }
}

#pragma mark BrowserViewControllerDelegate

- (void)didSelectNode:(MEGANode *)node {
    NSString *destinationPath = [self appGroupContainerURL];
    NSString *fileName = [node name];
    NSString *documentFilePath = [destinationPath stringByAppendingPathComponent:fileName];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:documentFilePath];
    if (fileExists) {
        // Because MEGA does not support file versioning yet, if the fingerprints are not equal we keep the cloud
        // version of the file deleting the local copy. If the file exists locally and the fingerprints are
        // the same, the local version may be used safely.
        // With file versioning, we may add the local copy to the array of versions before deleting it.
        NSString *localFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:documentFilePath];
        if ([localFingerprint isEqualToString:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:node]]) {
            [self documentReadyAtPath:documentFilePath withBase64Handle:[node base64Handle]];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:documentFilePath error:nil];
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];
        }
    } else {
        if ([Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];;
        }
    }
}

#pragma mark MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [[MEGASdkManager sharedMEGASdk] fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD dismiss];
            break;
        }
            
        default: {
            break;
        }
    }

}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    float percentage = [[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue];
    NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage * 100];
    [SVProgressHUD showProgress:percentage status:percentageCompleted];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    [self documentReadyAtPath:transfer.path withBase64Handle:[MEGASdk base64HandleForHandle:transfer.nodeHandle]];
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    [self dismissViewControllerAnimated:YES completion:^{
        self.passcodePresented = NO;
        [self presentDocumentPicker];
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
