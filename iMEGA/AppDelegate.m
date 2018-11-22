#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <Intents/Intents.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <PushKit/PushKit.h>
#import <QuickLook/QuickLook.h>
#import <UserNotifications/UserNotifications.h>

#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "CameraUploads.h"
#import "Helper.h"
#import "DevicePermissionsHelper.h"
#import "MEGAApplication.h"
#import "MEGAIndexer.h"
#import "MEGALogger.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPurchase.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGATransfer+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
#import "CallViewController.h"
#import "CameraUploadsPopUpViewController.h"
#import "ChangePasswordViewController.h"
#import "ChatRoomsViewController.h"
#import "CheckEmailAndFollowTheLinkViewController.h"
#import "CloudDriveViewController.h"
#import "ConfirmAccountViewController.h"
#import "ContactRequestsViewController.h"
#import "ContactsViewController.h"
#import "CreateAccountViewController.h"
#import "CustomModalAlertViewController.h"
#import "DisplayMode.h"
#import "LaunchViewController.h"
#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "MasterKeyViewController.h"
#import "MEGAAssetsPickerController.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MessagesViewController.h"
#import "MyAccountHallViewController.h"
#import "SettingsTableViewController.h"
#import "SharedItemsViewController.h"
#import "TwoFactorAuthenticationViewController.h"
#import "UnavailableLinkView.h"
#import "UpgradeTableViewController.h"

#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGAChatNotificationDelegate.h"
#import "MEGALocalNotificationManager.h"
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAPasswordLinkRequestDelegate.h"
#import "MEGAShowPasswordReminderRequestDelegate.h"
#import "CameraUploadManager.h"
#import "TransferSessionManager.h"
#import "CameraUploadRecordManager.h"

#define kUserAgent @"MEGAiOS"
#define kAppKey @"EVtjzb7R"

#define kFirstRun @"FirstRun"

@interface AppDelegate () <PKPushRegistryDelegate, UIApplicationDelegate, UNUserNotificationCenterDelegate, LTHPasscodeViewControllerDelegate, MEGAApplicationDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, MEGAGlobalDelegate, MEGAPurchasePricingDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
    
    BOOL isOverquota;
    
    BOOL isFirstFetchNodesRequestUpdate;
    NSTimer *timerAPI_EAGAIN;
}

@property (nonatomic, strong) UIView *privacyView;

@property (nonatomic, strong) NSURL *link;
@property (nonatomic) URLType urlType;
@property (nonatomic, strong) NSString *emailOfNewSignUpLink;
@property (nonatomic, strong) NSString *quickActionType;
@property (nonatomic, strong) NSString *messageForSuspendedAccount;

@property (nonatomic, strong) UIAlertController *overquotaAlertView;

@property (nonatomic, strong) UIAlertController *API_ESIDAlertController;

@property (nonatomic, weak) MainTabBarController *mainTBC;

@property (strong, nonatomic) NSString *recoveryLink;

@property (nonatomic, getter=isSignalActivityRequired) BOOL signalActivityRequired;

@property (nonatomic) MEGAIndexer *indexer;
@property (nonatomic) NSString *nodeToPresentBase64Handle;

@property (nonatomic) NSUInteger megatype; //1 share folder, 2 new message, 3 contact request

@property (strong, nonatomic) MEGAChatRoom *chatRoom;
@property (nonatomic, getter=isVideoCall) BOOL videoCall;

@property (strong, nonatomic) NSString *email;
@property (nonatomic) BOOL presentInviteContactVCLater;

@property (nonatomic, getter=showChooseAccountTypeLater) BOOL chooseAccountTypeLater;

@property (nonatomic, strong) UIAlertController *sslKeyPinningController;

@property (nonatomic) NSMutableDictionary *backgroundTaskMutableDictionary;

@property (nonatomic, getter=wasAppSuspended) BOOL appSuspended;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[App Lifecycle] Application will finish launching with options: %@", launchOptions);
//    NSArray<MOAssetUploadRecord *> *localRecords = [CameraUploadRecordManager.shared fetchAllAssetUploadRecords:nil];
//    localRecords = [localRecords sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES]]];
//    NSLog(@"local records count: %lu, list: %@", localRecords.count, localRecords);
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    [MEGASdk setLogToConsole:YES];
    
    [self migrateLocalCachesLocation];
    
    if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        _megatype = [[[launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"] objectForKey:@"megatype"] unsignedIntegerValue];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
        [[MEGALogger sharedLogger] startLogging];
    }
    
    _signalActivityRequired = NO;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    [MEGAReachabilityManager sharedManager];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pointToStaging"]) {
//        [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://api-sandbox3.developers.mega.co.nz/" disablepkp:NO];
//        [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://api-sandbox3.developers.mega.co.nz/" disablepkp:NO];
//    }
    
    [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://api-sandbox3.developers.mega.co.nz/" disablepkp:NO];
    [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://api-sandbox3.developers.mega.co.nz/" disablepkp:NO];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [[MEGASdkManager sharedMEGASdk] httpServerSetMaxBufferSize:[UIDevice currentDevice].maxBufferSize];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"presentPasscodeLater"];
    
    [self languageCompatibility];
    
    self.backgroundTaskMutableDictionary = [[NSMutableDictionary alloc] init];
    
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    // Delete username and password if exists - V1
    if ([SAMKeychain passwordForService:@"MEGA" account:@"username"] && [SAMKeychain passwordForService:@"MEGA" account:@"password"]) {
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"username"];
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"password"];
    }
    
    // Session from v2
    NSData *sessionV2 = [SAMKeychain passwordDataForService:@"MEGA" account:@"session"];
    NSString *sessionV3 = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    
    if (sessionV2) {
        // Save session for v3 and delete the previous one
        sessionV3 = [sessionV2 base64EncodedStringWithOptions:0];
        sessionV3 = [sessionV3 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
        sessionV3 = [sessionV3 stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        sessionV3 = [sessionV3 stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        [SAMKeychain setPassword:sessionV3 forService:@"MEGA" account:@"sessionV3"];
        
        [self removeOldStateCache];
        
        [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:kFirstRun];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Remove unused objects from NSUserDefaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"autologin"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"asked"];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"erase"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsEraseAllLocalDataEnabled];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Camera uploads settings
        [self cameraUploadsSettingsCompatibility];
        
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"session"];
    }

    // Rename attributes (thumbnails and previews)- handle to base64Handle
    NSString *v2ThumbsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:v2ThumbsPath]) {
        NSString *v3ThumbsPath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:v3ThumbsPath]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:v3ThumbsPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                MEGALogError(@"Create directory at path failed with error: %@", error);
            }
        }
        [self renameAttributesAtPath:v2ThumbsPath v3Path:v3ThumbsPath];
    }
    
    NSString *v2previewsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:v2previewsPath]) {
        NSString *v3PreviewsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:v3PreviewsPath]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:v3PreviewsPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                MEGALogError(@"Create directory at path failed with error: %@", error);
            }
        }
        [self renameAttributesAtPath:v2previewsPath v3Path:v3PreviewsPath];
    }
    
    //Clear keychain (session) and delete passcode on first run in case of reinstallation
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kFirstRun]) {
        sessionV3 = nil;
        [Helper clearEphemeralSession];
        [Helper clearSession];
        [Helper deletePasscode];
        [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:kFirstRun];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self setupAppearance];
    
    self.link = nil;
    isFetchNodesDone = NO;
    _presentInviteContactVCLater = NO;
    
    if (sessionV3) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TabsOrderInTabBar"];
        
        NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
        if (![sharedUserDefaults boolForKey:@"extensions"]) {
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
            [SAMKeychain setPassword:sessionV3 forService:@"MEGA" account:@"sessionV3"];
            [sharedUserDefaults setBool:YES forKey:@"extensions"];
        }
        if (![sharedUserDefaults boolForKey:@"extensions-passcode"]) {
            [[LTHPasscodeViewController sharedUser] resetPasscode];
            [sharedUserDefaults setBool:YES forKey:@"extensions-passcode"];
        }
        
        [self registerForVoIPNotifications];
        [self registerForNotifications];
        [self requestCameraAndMicPermissions];
        
        isAccountFirstLogin = NO;
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"IsChatEnabled"] == nil) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IsChatEnabled"];
            [sharedUserDefaults setBool:YES forKey:@"IsChatEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            BOOL isChatEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"];
            [sharedUserDefaults setBool:isChatEnabled forKey:@"IsChatEnabled"];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
                [MEGASdkManager createSharedMEGAChatSdk];
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
            }
            
            MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:sessionV3];
            if (chatInit == MEGAChatInitError) {
                MEGALogError(@"Init Karere with session failed");
                NSString *message = [NSString stringWithFormat:@"Error (%ld) initializing the chat", (long)chatInit];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [[MEGASdkManager sharedMEGAChatSdk] logout];
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
            }
        }
        
        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:sessionV3 delegate:loginRequestDelegate];
        
        if ([MEGAReachabilityManager isReachable]) {
            LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
            [UIView transitionWithView:self.window duration:0.5 options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent) animations:^{
                [self.window setRootViewController:launchVC];
            } completion:nil];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
                    [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                }
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                         withLogout:NO
                                                                     andLogoutTitle:nil];
                [self.window setRootViewController:[LTHPasscodeViewController sharedUser]];
            } else {
                _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                [self.window setRootViewController:_mainTBC];
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
            }
        }
        
        if ([sharedUserDefaults boolForKey:@"useHttpsOnly"]) {
            [[MEGASdkManager sharedMEGASdk] useHttpsOnly:YES];
        }
    } else {
        // Resume ephemeral account
        NSString *sessionId = [SAMKeychain passwordForService:@"MEGA" account:@"sessionId"];
        if (sessionId && ![[[launchOptions objectForKey:@"UIApplicationLaunchOptionsURLKey"] absoluteString] containsString:@"confirm"]) {
            MEGACreateAccountRequestDelegate *createAccountRequestDelegate = [[MEGACreateAccountRequestDelegate alloc] initWithCompletion:^ (MEGAError *error) {
                CheckEmailAndFollowTheLinkViewController *checkEmailAndFollowTheLinkVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CheckEmailAndFollowTheLinkViewControllerID"];
                [UIApplication.mnz_presentingViewController presentViewController:checkEmailAndFollowTheLinkVC animated:YES completion:nil];
            }];
            createAccountRequestDelegate.resumeCreateAccount = YES;
            [[MEGASdkManager sharedMEGASdk] resumeCreateAccountWithSessionId:sessionId delegate:createAccountRequestDelegate];
        }
    }
    
    if ([CameraUploads syncManager].isCameraUploadsEnabled) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusDenied) {
                MEGALogInfo(@"Disable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
            }
        }];
    }
    
    self.indexer = [[MEGAIndexer alloc] init];
    [Helper setIndexer:self.indexer];
    
    UIForceTouchCapability forceTouchCapability = self.window.rootViewController.view.traitCollection.forceTouchCapability;
    if (forceTouchCapability == UIForceTouchCapabilityAvailable) {
        UIApplicationShortcutItem *applicationShortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        if (applicationShortcutItem) {
            if (isFetchNodesDone) {
                [self manageQuickActionType:applicationShortcutItem.type];
            } else {
                self.quickActionType = applicationShortcutItem.type;
            }
        }
    }
    
    MEGALogDebug(@"[App Lifecycle] Application did finish launching with options %@", launchOptions);
    
    if (application.applicationState == UIApplicationStateActive) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllDeliveredNotifications];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did enter background");
    
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:YES];
    [[MEGASdkManager sharedMEGAChatSdk] saveCurrentState];

    BOOL pendingTasks = [[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] > 0 || [[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] > 0 || [[[CameraUploads syncManager] assetsOperationQueue] operationCount] > 0;
    if (pendingTasks) {
        [self beginBackgroundTaskWithName:@"PendingTasks"];
    }
    
    if (self.backgroundTaskMutableDictionary.count == 0) {
        self.appSuspended = YES;
        MEGALogDebug(@"App suspended property = YES.");
    }
    
    if (self.privacyView == nil) {
        UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
        self.privacyView = privacyVC.view;
    }
    [self.window addSubview:self.privacyView];
    
    [self application:application shouldHideWindows:YES];
    
    if (![NSStringFromClass([UIApplication sharedApplication].windows[0].class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will enter foreground");
    
    if (self.wasAppSuspended && [MEGASdkManager sharedMEGAChatSdk].numCalls == 0) {
        //If the app has been suspended, we assume that the sockets have been closed, so we have to reconnect.
        [[MEGAReachabilityManager sharedManager] reconnect];
    } else {
        [[MEGAReachabilityManager sharedManager] retryOrReconnect];
    }
    self.appSuspended = NO;
    MEGALogDebug(@"App suspended property = NO.");
    
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:NO];
    
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
            MEGALogInfo(@"Enable Camera Uploads");
            [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
        }
        
        if (isFetchNodesDone) {
            MEGAShowPasswordReminderRequestDelegate *showPasswordReminderDelegate = [[MEGAShowPasswordReminderRequestDelegate alloc] initToLogout:NO];
            [[MEGASdkManager sharedMEGASdk] shouldShowPasswordReminderDialogAtLogout:NO delegate:showPasswordReminderDelegate];
        }
    }
    
    [self.privacyView removeFromSuperview];
    self.privacyView = nil;
    
    [self application:application shouldHideWindows:NO];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllDeliveredNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did become active");
    
    if (self.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
    
    if (![NSStringFromClass([UIApplication sharedApplication].windows[0].class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] enablePasscodeWhenApplicationEntersBackground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will terminate");
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[MEGAPurchase sharedInstance]];
    
    if (![SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [Helper logout];
    }
    
    if ([[[[MEGASdkManager sharedMEGASdk] downloadTransfers] size] integerValue] == 0) {
        [NSFileManager.defaultManager mnz_removeFolderContentsRecursivelyAtPath:[Helper pathForOffline] forItemsExtension:@"mega"];
        [NSFileManager.defaultManager mnz_removeItemAtPath:[NSFileManager.defaultManager downloadsDirectory]];
    }
    if ([[[[MEGASdkManager sharedMEGASdk] uploadTransfers] size] integerValue] == 0) {
        [NSFileManager.defaultManager mnz_removeItemAtPath:[NSFileManager.defaultManager uploadsDirectory]];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    MEGALogDebug(@"[App Lifecycle] Application open URL %@, source application %@", url, sourceApplication);
    
    self.link = url;
    [self manageLink:url];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    MEGALogDebug(@"[App Lifecycle] Application did register user notification settings");
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if([deviceToken length] == 0) {
        MEGALogError(@"[App Lifecycle] Application did register for remote notifications with device token length 0");
        return;
    }
    
    const unsigned char *dataBuffer = (const unsigned char *)deviceToken.bytes;
    
    NSUInteger dataLength = deviceToken.length;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    NSString *deviceTokenString = [NSString stringWithString:hexString];
    MEGALogDebug(@"[App Lifecycle] Application did register for remote notifications with device token %@", deviceTokenString);
    [[MEGASdkManager sharedMEGASdk] registeriOSdeviceToken:deviceTokenString];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    MEGALogError(@"[App Lifecycle] Application did fail to register for remote notifications with error %@", error);
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    MEGALogDebug(@"[App Lifecycle] Application continue user activity %@", userActivity.activityType);
    
    if ([MEGAReachabilityManager isReachable]) {
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            self.nodeToPresentBase64Handle = userActivity.userInfo[@"kCSSearchableItemActivityIdentifier"];
            if ([self.window.rootViewController isKindOfClass:[MainTabBarController class]] && ![LTHPasscodeViewController doesPasscodeExist]) {
                [self presentNode];
            }
        } else if ([userActivity.activityType isEqualToString:@"INStartAudioCallIntent"] || [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
            INInteraction *interaction = userActivity.interaction;
            INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
            INPerson *contact = startAudioCallIntent.contacts[0];
            INPersonHandle *personHandle = contact.personHandle;
            self.email = personHandle.value;
            self.videoCall = [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"] ? YES : NO;
            MEGALogDebug(@"Email %@", self.email);
            uint64_t userHandle = [[MEGASdkManager sharedMEGAChatSdk] userHandleByEmail:self.email];
            
            // INVALID_HANDLE = ~(uint64_t)0
            if (userHandle == ~(uint64_t)0) {
                MEGALogDebug(@"Can't start a call because %@ is not your contact", self.email);
                if (isFetchNodesDone) {
                    [self presentInviteContactCustomAlertViewController];
                } else {
                    _presentInviteContactVCLater = YES;
                }
            } else {
                self.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:userHandle];
                if (self.chatRoom) {
                    MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
                    if (call.status == MEGAChatCallStatusInProgress) {
                        MEGALogDebug(@"There is a call in progress for this chat %@", call);
                        CallViewController *callViewController = (CallViewController *) [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
                        if (!callViewController.videoCall) {
                            [callViewController tapOnVideoCallkitWhenDeviceIsLocked];
                        }                        
                    } else {
                        MEGAChatConnection chatConnection = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:self.chatRoom.chatId];
                        MEGALogDebug(@"Chat %@ connection state: %ld", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], (long)chatConnection);
                        if (chatConnection == MEGAChatConnectionOnline) {
                            [DevicePermissionsHelper audioPermissionWithCompletionHandler:^(BOOL granted) {
                                if (granted) {
                                    if (self.videoCall) {
                                        [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                                            if (granted) {
                                                [self performCall];
                                            } else {
                                                [UIApplication.mnz_presentingViewController presentViewController:[DevicePermissionsHelper videoPermisionAlertController] animated:YES completion:nil];
                                            }
                                        }];
                                    } else {
                                        [self performCall];
                                    }
                                } else {
                                    [UIApplication.mnz_presentingViewController presentViewController:[DevicePermissionsHelper audioPermisionAlertController] animated:YES completion:nil];
                                }
                            }];
                        }
                    }
                } else {
                    MEGALogDebug(@"There is not a chat with %@, create the chat and inmediatelly perform the call", self.email);
                    MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
                    [peerList addPeerWithHandle:userHandle privilege:MEGAChatRoomPrivilegeStandard];
                    MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                        self.chatRoom = chatRoom;
                        MEGAChatConnection chatConnection = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:self.chatRoom.chatId];
                        MEGALogDebug(@"Chat %@ connection state: %ld", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], (long)chatConnection);
                        if (chatConnection == MEGAChatConnectionOnline) {
                            [self performCall];
                        }
                    }];
                    [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
                }
            }
        } else if ([userActivity.activityType isEqualToString:@"NSUserActivityTypeBrowsingWeb"]) {
            NSURL *universalLinkURL = userActivity.webpageURL;
            if (universalLinkURL) {
                self.link = universalLinkURL;
                
                [self manageLink:[NSURL URLWithString:[NSString stringWithFormat:@"mega://%@", [universalLinkURL mnz_afterSlashesString]]]];
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    MEGALogDebug(@"[App Lifecycle] Application perform action for shortcut item");
    
    if (isFetchNodesDone) {
        completionHandler([self manageQuickActionType:shortcutItem.type]);
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    MEGALogWarning(@"[App Lifecycle] Application did receive memory warning");
    
    [self.indexer stopIndexing];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    MEGALogDebug(@"[App Lifecycle] Application did receive remote notification");
    
    if (application.applicationState == UIApplicationStateInactive) {
        _megatype = [[userInfo objectForKey:@"megatype"] unsignedIntegerValue];
        [self openTabBasedOnNotificationMegatype];
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"[App Lifecycle] application handle events for background session: %@", identifier);
    if ([identifier isEqualToString:photoTransferSessionId]) {
        [TransferSessionManager shared].photoSessionCompletion = completionHandler;
        [[TransferSessionManager shared] restorePhotoSessionIfNeeded];
    } else if ([identifier isEqualToString:videoTransferSessionId]) {
        [TransferSessionManager shared].videoSessionCompletion = completionHandler;
        [[TransferSessionManager shared] restoreVideoSessionIfNeeded];
    }
}

#pragma mark - Private

- (void)setupAppearance {
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGANavigationController.class]].titleTextAttributes = @{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:UIColor.whiteColor};
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGANavigationController.class]].barStyle = UIBarStyleBlack;
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGANavigationController.class]].barTintColor = UIColor.mnz_redMain;
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGANavigationController.class]].tintColor = UIColor.whiteColor;
    [UINavigationBar appearance].translucent = NO;

    //QLPreviewDocument
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[QLPreviewController.class]].titleTextAttributes = @{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:UIColor.blackColor};
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[QLPreviewController.class]].barTintColor = UIColor.whiteColor;
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[QLPreviewController.class]].tintColor = UIColor.mnz_redMain;
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[QLPreviewController.class]].textColor = UIColor.mnz_redMain;
    [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[QLPreviewController.class]].tintColor = UIColor.mnz_redMain;
    
    //MEGAAssetsPickerController
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGAAssetsPickerController.class]].barStyle = UIBarStyleBlack;
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGAAssetsPickerController.class]].barTintColor = UIColor.mnz_redMain;
    [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[MEGAAssetsPickerController.class]].tintColor = UIColor.whiteColor;

    [UISearchBar appearance].translucent = NO;
    [UISearchBar appearance].backgroundColor = UIColor.mnz_grayFCFCFC;
    [UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]].backgroundColor = UIColor.mnz_grayEEEEEE;
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:13.0f]} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
    [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]].tintColor = UIColor.mnz_redMain;

    [UINavigationBar appearance].backIndicatorImage = [UIImage imageNamed:@"backArrow"];
    [UINavigationBar appearance].backIndicatorTransitionMaskImage = [UIImage imageNamed:@"backArrow"];
    
    [UITextField appearance].tintColor = UIColor.mnz_green00BFA5;
    
    [UITextView appearance].tintColor = UIColor.mnz_green00BFA5;
    
    [UIView appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]].tintColor = UIColor.mnz_redMain;
    
    [UIProgressView appearance].tintColor = UIColor.mnz_redMain;
    
    [SVProgressHUD setFont:[UIFont mnz_SFUIRegularWithSize:12.0f]];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setRingNoTextRadius:18.0];
    [SVProgressHUD setBackgroundColor:UIColor.mnz_grayF7F7F7];
    [SVProgressHUD setForegroundColor:UIColor.mnz_gray666666];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setHapticsEnabled:YES];
    
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hudSuccess"]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hudError"]];
}

- (void)beginBackgroundTaskWithName:(NSString *)name {
    MEGALogDebug(@"Begin background task with name: %@", name);
    
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:name expirationHandler:^{
        NSArray *allKeysArray = [self.backgroundTaskMutableDictionary allKeysForObject:name];
        for (NSUInteger i = 0; i < allKeysArray.count; i++) {
            NSNumber *expiringBackgroundTaskIdentifierNumber = [allKeysArray objectAtIndex:i];
            [[UIApplication sharedApplication] endBackgroundTask:expiringBackgroundTaskIdentifierNumber.unsignedIntegerValue];
            
            [self.backgroundTaskMutableDictionary removeObjectForKey:expiringBackgroundTaskIdentifierNumber];
            if (self.backgroundTaskMutableDictionary.count == 0) {
                self.appSuspended = YES;
                MEGALogDebug(@"App suspended property = YES.");
            }
        }
        MEGALogDebug(@"Ended all background tasks with name: %@", name);
    }];
    
    [self.backgroundTaskMutableDictionary setObject:name forKey:[NSNumber numberWithUnsignedInteger:backgroundTaskIdentifier]];
}

- (void)showCameraUploadsPopUp {
    MEGANavigationController *cameraUploadsNavigationController =[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsPopUpNavigationControllerID"];
    
    [UIApplication.mnz_presentingViewController presentViewController:cameraUploadsNavigationController animated:YES completion:^{
        isAccountFirstLogin = NO;
        if (self.urlType == URLTypeConfirmationLink) {
            if ([MEGAPurchase sharedInstance].products.count > 0) {
                [self showChooseAccountType];
            } else {
                [[MEGAPurchase sharedInstance] setPricingsDelegate:self];
                self.chooseAccountTypeLater = YES;
            }
        }
     
        if ([Helper selectedOptionOnLink] != 0) {
            [self processSelectedOptionOnLink];
        }
    }];
}

- (void)showOffline {
    self.mainTBC.selectedIndex = MYACCOUNT;
    MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:MYACCOUNT];
    MyAccountHallViewController *myAccountHallVC = navigationController.viewControllers.firstObject;
    [myAccountHallVC openOffline];
}

- (void)processSelectedOptionOnLink {
    switch ([Helper selectedOptionOnLink]) {
        case 1: { //Import file from link
            MEGANode *node = [Helper linkNode];
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
            
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            browserVC.selectedNodesArray = [NSArray arrayWithObject:node];
            [browserVC setBrowserAction:BrowserActionImport];
            break;
        }
            
        case 2: { //Download file from link
            MEGANode *node = [Helper linkNode];
            if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                return;
            }
            [self showOffline];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
            [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:NO shouldOverwrite:NO];
            break;
        }
            
        case 3: { //Import folder or nodes from link
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
            browserVC.selectedNodesArray = [NSArray arrayWithArray:[Helper nodesFromLinkMutableArray]];
            [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
            break;
        }
            
        case 4: { //Download folder or nodes from link
            for (MEGANode *node in [Helper nodesFromLinkMutableArray]) {
                if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                    return;
                }
            }
            [self showOffline];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
            for (MEGANode *node in [Helper nodesFromLinkMutableArray]) {
                [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:YES shouldOverwrite:NO];
            }
            break;
        }
            
        default:
            break;
    }
    
    [Helper setLinkNode:nil];
    [[Helper nodesFromLinkMutableArray] removeAllObjects];
    [Helper setSelectedOptionOnLink:0];
}

- (void)manageLink:(NSURL *)url {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        if (![LTHPasscodeViewController doesPasscodeExist] && isFetchNodesDone) {
            [self processLink:url];
        }
    } else {
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            [self processLink:url];
        }
    }
}

- (void)processLink:(NSURL *)url {
    if (self.window.rootViewController.presentedViewController) {
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
            [self urlLinkType:url];
        }];
    } else {
        [self urlLinkType:url];
    }
}

- (void)urlLinkType:(NSURL *)url {
    self.urlType = [url mnz_type];
    switch (self.urlType) {
        case URLTypeDefault:
            [Helper presentSafariViewControllerWithURL:self.link];
            self.link = nil;
            
            break;
            
        case URLTypeOpenInLink:
            [self openIn];
            
            break;
            
        case URLTypeFileLink:
            [url mnz_showLinkView];
            self.link = nil;
            
            break;
            
        case URLTypeFolderLink:
            [url mnz_showLinkView];
            self.link = nil;

            break;
            
        case URLTypeEncryptedLink:
            [self showEncryptedLinkAlert:[url mnz_MEGAURL]];
            
            break;
            
        case URLTypeConfirmationLink: {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"alreadyLoggedInAlertTitle", @"Warning title shown when you try to confirm an account but you are logged in with another one") message:AMLocalizedString(@"alreadyLoggedInAlertMessage", @"Warning message shown when you try to confirm an account but you are logged in with another one") preferredStyle:UIAlertControllerStyleAlert];
                
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[MEGASdkManager sharedMEGASdk] logout];
                }]];
                
                [UIApplication.mnz_presentingViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
            } else {
                [[MEGASdkManager sharedMEGASdk] querySignupLink:[url mnz_MEGAURL]];
                self.link = nil;
            }
            break;
        }
            
        case URLTypeNewSignUpLink:
            [[MEGASdkManager sharedMEGASdk] querySignupLink:[url mnz_MEGAURL]];

            break;
            
        case URLTypeBackupLink:
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [self showBackupLinkView];
            } else {
                [self showPleaseLogInToYourAccountAlert];
            }
            
            break;
            
        case URLTypeIncomingPendingContactsLink:
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [self showContactRequestsView];
            } else {
                [self showPleaseLogInToYourAccountAlert];
            }
            
            break;
            
        case URLTypeChangeEmailLink:
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [[MEGASdkManager sharedMEGASdk] queryChangeEmailLink:[url mnz_MEGAURL]];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"needToBeLoggedInToCompleteYourEmailChange", @"Error message when a user attempts to change their email without an active login session.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
            }
            
            break;
            
        case URLTypeCancelAccountLink:
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [[MEGASdkManager sharedMEGASdk] queryCancelLink:[url mnz_MEGAURL]];
            } else {
                [self showPleaseLogInToYourAccountAlert];
            }
            
            break;
            
        case URLTypeRecoverLink:
            [[MEGASdkManager sharedMEGASdk] queryResetPasswordLink:[url mnz_MEGAURL]];

            break;
            
        case URLTypeContactLink:
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [url mnz_showLinkView];
            } else {
                [self showPleaseLogInToYourAccountAlert];
            }
            
            break;
            
        case URLTypeChatLink:
            self.mainTBC.selectedIndex = CHAT;

            break;
            
        case URLTypeLoginRequiredLink: {
            NSString *session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
            if (session) {
                [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
                [SAMKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
            }

            break;
        }
            
        case URLTypeHandleLink:
            self.nodeToPresentBase64Handle = [[url mnz_afterSlashesString] substringFromIndex:1];
            [self presentNode];
            
            break;
            
        case URLTypeAchievementsLink:
            [self openAchievements];
            break;
            
        default:
            break;
    }
}

- (void)dismissPresentedViews {
    if (self.window.rootViewController.presentedViewController != nil) {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showEncryptedLinkAlert:(NSString *)encryptedLinkURLString {
    MEGAPasswordLinkRequestDelegate *delegate = [[MEGAPasswordLinkRequestDelegate alloc] initForDecryptionWithCompletion:^(MEGARequest *request) {
        NSString *url = [NSString stringWithFormat:@"mega://%@", [[request.text componentsSeparatedByString:@"/"] lastObject]];
        [self processLink:[NSURL URLWithString:url]];
    } onError:^(MEGARequest *request) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyNotValid", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self showEncryptedLinkAlert:request.link];
        }]];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", nil) message:AMLocalizedString(@"decryptionKeyAlertMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = AMLocalizedString(@"decryptionKey", nil);
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[MEGASdkManager sharedMEGASdk] decryptPasswordProtectedLink:encryptedLinkURLString password:alertController.textFields.firstObject.text delegate:delegate];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    
    self.link = nil;
}

- (void)showBackupLinkView {
    MasterKeyViewController *masterKeyVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"MasterKeyViewControllerID"];
    masterKeyVC.navigationItem.rightBarButtonItem = [self cancelBarButtonItem];
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:masterKeyVC];
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)showContactRequestsView {
    ContactRequestsViewController *contactsRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:contactsRequestsVC];
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)openAchievements {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        MainTabBarController *mainTBC = (MainTabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        mainTBC.selectedIndex = MYACCOUNT;
        MEGANavigationController *navigationController = [mainTBC.childViewControllers objectAtIndex:MYACCOUNT];
        MyAccountHallViewController *myAccountHallVC = navigationController.viewControllers.firstObject;
        if ([[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
            [myAccountHallVC openAchievements];
        }
    } else {
        [self showPleaseLogInToYourAccountAlert];
    }
}

- (void)openIn {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        MEGANavigationController *browserNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = browserNavigationController.viewControllers.firstObject;
        [browserVC setLocalpath:[self.link path]]; // "file://" = 7 characters
        [browserVC setBrowserAction:BrowserActionOpenIn];
        
        [UIApplication.mnz_presentingViewController presentViewController:browserNavigationController animated:YES completion:nil];
        
        self.link = nil;
    }
}

- (BOOL)manageQuickActionType:(NSString *)type {
    BOOL quickActionManaged = YES;
    if ([type isEqualToString:@"mega.ios.search"]) {
        self.mainTBC.selectedIndex = CLOUD;
        MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:CLOUD];
        CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
        if (self.quickActionType) { //Coming from didFinishLaunchingWithOptions
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [cloudDriveVC activateSearch]; // Cloud Drive already presented, so activate search bar
            } else {
                cloudDriveVC.homeQuickActionSearch = YES; //Search will become active after the Cloud Drive did appear
            }
        } else {
            [cloudDriveVC activateSearch];
        }
    } else if ([type isEqualToString:@"mega.ios.upload"]) {
        self.mainTBC.selectedIndex = CLOUD;
        MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:CLOUD];
        CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
        [cloudDriveVC presentUploadAlertController];
    } else if ([type isEqualToString:@"mega.ios.offline"]) {
        [self showOffline];
    } else {
        quickActionManaged = NO;
    }
    
    self.quickActionType = nil;
    
    return quickActionManaged;
}

- (void)startTimerAPI_EAGAIN {
    timerAPI_EAGAIN = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showServersTooBusy) userInfo:nil repeats:NO];
}

- (void)invalidateTimerAPI_EAGAIN {
    [timerAPI_EAGAIN invalidate];
    
    if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
        LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
        launchVC.label.text = @"";
    }
}

- (void)showServersTooBusy {
    if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
        LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
        NSString *message;
        switch ([[MEGASdkManager sharedMEGASdk] waiting]) {
            case RetryNone:
                break;

            case RetryConnectivity:
                message = AMLocalizedString(@"unableToReachMega", @"Message shown when the app is waiting for the server to complete a request due to connectivity issue.");
                break;
                
            case RetryServersBusy:
                message = AMLocalizedString(@"serversAreTooBusy", @"Message shown when the app is waiting for the server to complete a request due to a HTTP error 500.");
                break;
                
            case RetryApiLock:
                message = AMLocalizedString(@"takingLongerThanExpected", @"Message shown when the app is waiting for the server to complete a request due to an API lock (error -3).");
                break;
                
            case RetryRateLimit:
                message = AMLocalizedString(@"tooManyRequest", @"Message shown when the app is waiting for the server to complete a request due to a rate limit (error -4).");
                break;
                
            case RetryLocalLock:
                break;
                
            case RetryUnknown:
                break;
                
            default:
                break;
        }
        launchVC.label.text = message;
        
        MEGALogDebug(@"The SDK is waiting to complete a request, reason: %lu", (unsigned long)[[MEGASdkManager sharedMEGASdk] waiting]);
    }
}

- (void)showOverquotaAlert {
    [self disableCameraUploads];
    
    if (!UIApplication.mnz_presentingViewController.presentedViewController || UIApplication.mnz_presentingViewController.presentedViewController != self.overquotaAlertView) {
        isOverquota = YES;
        [[MEGASdkManager sharedMEGASdk] getAccountDetails];
    }
}

- (void)disableCameraUploads {
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        MEGALogInfo(@"Disable Camera Uploads");
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
    }
}

- (void)showLinkNotValid {
    [self showEmptyStateViewWithImageNamed:@"invalidFileLink" title:AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid") text:@""];
    self.link = nil;
    self.urlType = URLTypeDefault;
}

- (void)showEmptyStateViewWithImageNamed:(NSString *)imageName title:(NSString *)title text:(NSString *)text {
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:imageName]];
    [unavailableLinkView.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [unavailableLinkView.titleLabel setText:title];
    unavailableLinkView.textLabel.text = text;
    [unavailableLinkView setFrame:self.window.frame];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    [viewController.view addSubview:unavailableLinkView];
    [viewController.navigationItem setTitle:title];
    [viewController.navigationItem setRightBarButtonItem:[self cancelBarButtonItem]];
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:viewController];
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (UIBarButtonItem *)cancelBarButtonItem {
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:nil action:@selector(dismissPresentedViews)];
    return cancelBarButtonItem;
}

- (void)showPleaseLogInToYourAccountAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"pleaseLogInToYourAccount", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)presentConfirmViewControllerType:(ConfirmType)confirmType link:(NSString *)link email:(NSString *)email {
    MEGANavigationController *confirmAccountNavigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ConfirmAccountNavigationControllerID"];
    
    ConfirmAccountViewController *confirmAccountVC = confirmAccountNavigationController.viewControllers.firstObject;
    confirmAccountVC.confirmType = confirmType;
    confirmAccountVC.confirmationLinkString = link;
    confirmAccountVC.emailString = email;
    
    [UIApplication.mnz_presentingViewController presentViewController:confirmAccountNavigationController animated:YES completion:nil];
}

- (void)presentChangeViewType:(ChangeType)changeType email:(NSString *)email masterKey:(NSString *)masterKey link:(NSString *)link {
    ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
    changePasswordVC.changeType = changeType;
    changePasswordVC.email = email;
    changePasswordVC.masterKey = masterKey;
    changePasswordVC.link = link;
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:changePasswordVC];
    [navigationController addCancelButton];
    
    UIViewController *visibleViewController = UIApplication.mnz_presentingViewController;
    if ([visibleViewController isKindOfClass:UIAlertController.class]) {
        [visibleViewController dismissViewControllerAnimated:NO completion:^{
            [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
        }];
    } else {
        [visibleViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)requestUserName {
    if (![[MEGAStore shareInstance] fetchUserWithUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]]) {
        [[MEGASdkManager sharedMEGASdk] getUserAttributeType:MEGAUserAttributeFirstname];
        [[MEGASdkManager sharedMEGASdk] getUserAttributeType:MEGAUserAttributeLastname];
    }
}

- (void)requestContactsFullname {
    MEGAUserList *userList = [[MEGASdkManager sharedMEGASdk] contacts];
    for (NSInteger i = 0; i < userList.size.integerValue; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        if (![[MEGAStore shareInstance] fetchUserWithUserHandle:user.handle] && user.visibility == MEGAUserVisibilityVisible) {
            [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
            [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname];
        }
    }
}

- (void)showMainTabBar {
    if (![self.window.rootViewController isKindOfClass:[LTHPasscodeViewController class]]) {
        
        if (![self.window.rootViewController isKindOfClass:[MainTabBarController class]]) {
            _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            [self.window setRootViewController:_mainTBC];
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
                    [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                }
                
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"]) {
                    [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                             withLogout:NO
                                                                         andLogoutTitle:nil];
                }
            }
        }
        
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            if (self.nodeToPresentBase64Handle) {
                [self presentNode];
            }
            
            if (isAccountFirstLogin) {
                [self showCameraUploadsPopUp];
            }
            
            if (self.link != nil) {
                [self processLink:self.link];
            }
            
            [self manageQuickActionType:self.quickActionType];
        }
    }
    
    [[CameraUploads syncManager] setTabBarController:_mainTBC];
    if (isAccountFirstLogin) {
        [self registerForVoIPNotifications];
        [self registerForNotifications];
        [self requestCameraAndMicPermissions];
    }
    
    [self openTabBasedOnNotificationMegatype];
    
    if (self.presentInviteContactVCLater) {
        [self presentInviteContactCustomAlertViewController];
    }
}

- (void)openTabBasedOnNotificationMegatype {
    NSUInteger tabTag = 0;
    switch (self.megatype) {
        case 1:
            tabTag = SHARES;
            break;
            
        case 2:
            tabTag = CHAT;
            break;
            
        case 3:
            tabTag = MYACCOUNT;
            break;
            
        default:
            return;
    }
    
    self.mainTBC.selectedIndex = tabTag;
    if (self.megatype == 3) {
        MEGANavigationController *navigationController = [[self.mainTBC viewControllers] objectAtIndex:tabTag];
        ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
        [navigationController pushViewController:contactsVC animated:NO];
    }
}

- (void)registerForVoIPNotifications {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)registerForNotifications {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error) {
                                      MEGALogInfo(@"Request notifications authorization succeeded");
                                  }
                                  if (granted) {
                                      [self notificationsSettings];
                                  }
                              }];
    } else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings
                                                                             settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge |
                                                                             UIUserNotificationTypeSound categories:nil]];
    }
}

- (void)requestCameraAndMicPermissions {
    [DevicePermissionsHelper audioPermissionWithCompletionHandler:nil];
    [DevicePermissionsHelper videoPermissionWithCompletionHandler:nil];
}

- (void)notificationsSettings {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        MEGALogInfo(@"Notifications settings %@", settings);
        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];
}

- (void)presentNode {
    uint64_t handle = [MEGASdk handleForBase64Handle:self.nodeToPresentBase64Handle];
    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:handle];
    if (node) {
        UINavigationController *navigationController;
        if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) { // node from inshare
            self.mainTBC.selectedIndex = SHARES;
            SharedItemsViewController *sharedItemsVC = self.mainTBC.childViewControllers[SHARES].childViewControllers[0];
            [sharedItemsVC selectSegment:0]; // Incoming
        } else {
            self.mainTBC.selectedIndex = CLOUD;
        }
        navigationController = [self.mainTBC.childViewControllers objectAtIndex:self.mainTBC.selectedIndex];
        
        [self presentNode:node inNavigationController:navigationController];
    } else {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            UIAlertController *theContentIsNotAvailableAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"theContentIsNotAvailableForThisAccount", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [theContentIsNotAvailableAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            [theContentIsNotAvailableAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSError *error;
                NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] error:&error];
                if (error) {
                    MEGALogError(@"Contents of directory at path failed with error: %@", error);
                }
                
                BOOL isInboxDirectory = NO;
                for (NSString *directoryElement in directoryContent) {
                    if ([directoryElement isEqualToString:@"Inbox"]) {
                        NSString *inboxPath = [[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"];
                        [[NSFileManager defaultManager] fileExistsAtPath:inboxPath isDirectory:&isInboxDirectory];
                        break;
                    }
                }
                
                if (directoryContent.count > 0) {
                    if (directoryContent.count == 1 && isInboxDirectory) {
                        [[MEGASdkManager sharedMEGASdk] logout];
                        return;
                    }
                    
                    UIAlertController *warningAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"warning", nil) message:AMLocalizedString(@"allFilesSavedForOfflineWillBeDeletedFromYourDevice", @"Alert message shown when the user perform logout and has files in the Offline directory") preferredStyle:UIAlertControllerStyleAlert];
                    [warningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
                    [warningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [[MEGASdkManager sharedMEGASdk] logout];
                    }]];
                    
                    [UIApplication.mnz_presentingViewController presentViewController:warningAlertController animated:YES completion:nil];
                } else {
                    [[MEGASdkManager sharedMEGASdk] logout];
                }
            }]];
            
            [UIApplication.mnz_presentingViewController presentViewController:theContentIsNotAvailableAlertController animated:YES completion:nil];
        }
    }
    self.nodeToPresentBase64Handle = nil;
}

- (void)presentNode:(MEGANode *)node inNavigationController:(UINavigationController *)navigationController {
    [navigationController popToRootViewControllerAnimated:NO];
    
    NSArray *parentTreeArray = node.mnz_parentTreeArray;
    for (MEGANode *node in parentTreeArray) {
        CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        cloudDriveVC.parentNode = node;
        [navigationController pushViewController:cloudDriveVC animated:NO];
    }
    
    switch (node.type) {
        case MEGANodeTypeFolder:
        case MEGANodeTypeRubbish: {
            CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = node;
            [navigationController pushViewController:cloudDriveVC animated:NO];
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.parentHandle];
                MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:parentNode];
                NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaNodesMutableArrayFromNodeList];
                
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeCloudDrive presentingNode:node preferredIndex:0];
                
                [navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
            } else {
                [node mnz_openNodeInNavigationController:navigationController folderLink:NO];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)migrateLocalCachesLocation {
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSError *error;
    NSURL *applicationSupportDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
    }
    NSString *applicationSupportDirectoryString = applicationSupportDirectoryURL.path;
    NSArray *applicationSupportContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationSupportDirectoryString error:&error];
    if (applicationSupportContent) {
        for (NSString *filename in applicationSupportContent) {
            if ([filename containsString:@"megaclient"]) {
                return;
            }
        }
        
        NSArray *cacheContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachesPath error:&error];
        if (cacheContents) {
            for (NSString *filename in cacheContents) {
                if ([filename containsString:@"karere"] || [filename containsString:@"megaclient"]) {
                    if (![[NSFileManager defaultManager] moveItemAtPath:[cachesPath stringByAppendingPathComponent:filename] toPath:[applicationSupportDirectoryString stringByAppendingPathComponent:filename] error:&error]) {
                        MEGALogError(@"Move item at path failed with error: %@", error);
                    }
                }
            }
        } else {
            MEGALogError(@"Contents of directory at path failed with error: %@", error);
        }
    } else {
        MEGALogError(@"Contents of directory at path failed with error: %@", error);
    }
}

- (void)copyDatabasesForExtensions {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
    }
    
    NSString *groupSupportPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"GroupSupport"] path];
    if (![fileManager fileExistsAtPath:groupSupportPath]) {
        [fileManager createDirectoryAtPath:groupSupportPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *applicationSupportDirectoryString = applicationSupportDirectoryURL.path;
    NSArray *applicationSupportContent = [fileManager contentsOfDirectoryAtPath:applicationSupportDirectoryString error:&error];
    for (NSString *filename in applicationSupportContent) {
        if ([filename containsString:@"megaclient"] || [filename containsString:@"karere"]) {
            NSString *destinationPath = [groupSupportPath stringByAppendingPathComponent:filename];
            [NSFileManager.defaultManager mnz_removeItemAtPath:destinationPath];
            if (![fileManager copyItemAtPath:[applicationSupportDirectoryString stringByAppendingPathComponent:filename] toPath:destinationPath error:&error]) {
                MEGALogError(@"Copy item at path failed with error: %@", error);
            }
        }
    }
}

void uncaughtExceptionHandler(NSException *exception) {
    MEGALogError(@"Exception name: %@\nreason: %@\nuser info: %@\n", exception.name, exception.reason, exception.userInfo);
    MEGALogError(@"Stack trace: %@", [exception callStackSymbols]);
}


- (void)performCall {
    CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
    callVC.chatRoom = self.chatRoom;
    callVC.videoCall = self.videoCall;
    callVC.callType = CallTypeOutgoing;
    if (@available(iOS 10.0, *)) {
        callVC.megaCallManager = [self.mainTBC megaCallManager];
    }
    [self.mainTBC presentViewController:callVC animated:YES completion:nil];
    self.chatRoom = nil;
}

- (void)presentInviteContactCustomAlertViewController {
    CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
    customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    BOOL isInOutgoingContactRequest = NO;
    MEGAContactRequestList *outgoingContactRequestList = [[MEGASdkManager sharedMEGASdk] outgoingContactRequests];
    for (NSInteger i = 0; i < [[outgoingContactRequestList size] integerValue]; i++) {
        MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
        if ([self.email isEqualToString:contactRequest.targetEmail]) {
            isInOutgoingContactRequest = YES;
            break;
        }
    }
    
    customModalAlertVC.boldInDetail = self.email;
    
    if (isInOutgoingContactRequest) {
        customModalAlertVC.image = [UIImage imageNamed:@"inviteSent"];
        customModalAlertVC.viewTitle = AMLocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
        NSString *detailText = AMLocalizedString(@"theUserHasBeenInvited", @"Success message shown when a contact has been invited");
        detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:self.email];
        customModalAlertVC.detail = detailText;
        customModalAlertVC.action = AMLocalizedString(@"close", nil);
        customModalAlertVC.dismiss = nil;
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
    } else {
        customModalAlertVC.image = [UIImage imageNamed:@"groupChat"];
        customModalAlertVC.viewTitle = AMLocalizedString(@"inviteContact", @"Title shown when the user tries to make a call and the destination is not in the contact list");
        customModalAlertVC.detail = [NSString stringWithFormat:@"Your contact %@ is not on MEGA. In order to call through MEGA's encrypted chat you need to invite your contact", self.email];
        customModalAlertVC.action = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
        customModalAlertVC.dismiss = AMLocalizedString(@"later", @"Button title to allow the user postpone an action");
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
            [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:self.email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
    }
    
    [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    
    self.presentInviteContactVCLater = NO;
}

- (void)openChatRoomWithChatNumber:(NSNumber *)chatNumber {
    if (chatNumber) {
        self.mainTBC.selectedIndex = CHAT;
        MEGANavigationController *navigationController = [[self.mainTBC viewControllers] objectAtIndex:CHAT];
        ChatRoomsViewController *chatRoomsVC = navigationController.viewControllers.firstObject;
        
        if ([MEGASdkManager sharedMEGAChatSdk].numCalls == 0) {
            if (self.window.rootViewController.presentedViewController) {
                [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
                    [chatRoomsVC openChatRoomWithID:chatNumber.unsignedLongLongValue];
                }];
            } else {
                [chatRoomsVC openChatRoomWithID:chatNumber.unsignedLongLongValue];
            }
        }
    }
}

- (void)application:(UIApplication *)application shouldHideWindows:(BOOL)shouldHide {
    for (UIWindow *window in application.windows) {
        if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] || [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"]) {
            window.hidden = shouldHide;
        }
    }
}

- (void)showChooseAccountType {
    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
    upgradeTVC.chooseAccountType = YES;
    
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    self.urlType = URLTypeDefault;
}

- (void)alertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if (alertController) {
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

#pragma mark - Battery changed

- (void)batteryChanged:(NSNotification *)notification {
    if ([[CameraUploads syncManager] isOnlyWhenChargingEnabled]) {
        if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnplugged) {
            [[CameraUploads syncManager] resetOperationQueue];
        } else {
            [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
        }
    }
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    if (![MEGAReachabilityManager isReachable] || [self.window.rootViewController isKindOfClass:[LTHPasscodeViewController class]]) {
        _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [self.window setRootViewController:_mainTBC];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    } else {
        if (self.link != nil) {
            [self processLink:self.link];
        }
        
        if (self.nodeToPresentBase64Handle) {
            [self presentNode];
        }
        
        [self manageQuickActionType:self.quickActionType];
    }
}

- (void)maxNumberOfFailedAttemptsReached {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
}

#pragma mark - Compatibility with v2

// Rename thumbnails and previous to base64
- (void)renameAttributesAtPath:(NSString *)v2Path v3Path:(NSString *)v3Path {
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:v2Path error:nil];
    
    for (NSInteger count = 0; count < [directoryContent count]; count++) {
        NSString *attributeFilename = [directoryContent objectAtIndex:count];
        NSString *base64Filename = [MEGASdk base64HandleForHandle:[attributeFilename longLongValue]];
        
        NSString *attributePath = [v2Path stringByAppendingPathComponent:attributeFilename];
        
        if ([base64Filename isEqualToString:@"AAAAAAAA"]) {
            if (attributePath.mnz_isImagePathExtension) {
                [NSFileManager.defaultManager mnz_removeItemAtPath:attributePath];
            } else {
                NSString *newAttributePath = [v3Path stringByAppendingPathComponent:attributeFilename];
                [[NSFileManager defaultManager] moveItemAtPath:attributePath toPath:newAttributePath error:nil];
            }
            continue;
        }
        
        NSString *newAttributePath = [v3Path stringByAppendingPathComponent:base64Filename];
        [[NSFileManager defaultManager] moveItemAtPath:attributePath toPath:newAttributePath error:nil];
    }
    
    directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:v2Path error:nil];
    
    if ([directoryContent count] == 0) {
        [NSFileManager.defaultManager mnz_removeItemAtPath:v2Path];
    }
}

- (void)cameraUploadsSettingsCompatibility {
    // PhotoSync old location of completed uploads
    NSString *oldCompleted = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"PhotoSync/completed.plist"];
    [NSFileManager.defaultManager mnz_removeItemAtPath:oldCompleted];
    
    // PhotoSync v2 location of completed uploads
    NSString *v2Completed = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"PhotoSync/com.plist"];
    [NSFileManager.defaultManager mnz_removeItemAtPath:v2Completed];
    
    // PhotoSync settings
    NSString *oldPspPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"PhotoSync/psp.plist"];
    NSString *v2PspPath  = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"PhotoSync/psp.plist"];
    
    // check for file in previous location
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldPspPath]) {
        [[NSFileManager defaultManager] moveItemAtPath:oldPspPath toPath:v2PspPath error:nil];
    }
    
    NSDictionary *cameraUploadsSettings = [[NSDictionary alloc] initWithContentsOfFile:v2PspPath];
    
    if ([cameraUploadsSettings objectForKey:@"syncEnabled"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kIsCameraUploadsEnabled];
        
        if ([cameraUploadsSettings objectForKey:@"cellEnabled"]) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kIsUseCellularConnectionEnabled];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:kIsUseCellularConnectionEnabled];
        }
        if ([cameraUploadsSettings objectForKey:@"videoEnabled"]) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kIsUploadVideosEnabled];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:kIsUploadVideosEnabled];
        }
        
        [NSFileManager.defaultManager mnz_removeItemAtPath:v2PspPath];
    }
}

- (void)removeOldStateCache {
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [NSFileManager.defaultManager mnz_removeFolderContentsRecursivelyAtPath:libraryDirectory forItemsExtension:@"db"];
}

- (void)languageCompatibility {
    
    NSString *currentLanguageID = [[LocalizationSystem sharedLocalSystem] getLanguage];
    
    if ([Helper isLanguageSupported:currentLanguageID]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:currentLanguageID];
    } else {
        [self setLanguage:currentLanguageID];
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

#pragma mark - PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    if([credentials.token length] == 0) {
        MEGALogError(@"VoIP token length is 0");
        return;
    }
    const unsigned char *dataBuffer = (const unsigned char *)credentials.token.bytes;
    
    NSUInteger dataLength = credentials.token.length;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    NSString *deviceTokenString = [NSString stringWithString:hexString];
    MEGALogDebug(@"Device token %@", deviceTokenString);
    [[MEGASdkManager sharedMEGASdk] registeriOSVoIPdeviceToken:deviceTokenString];
    
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    MEGALogDebug(@"Did receive incoming push with payload: %@", [payload dictionaryPayload]);
    
    // Call
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground && [[[payload dictionaryPayload] objectForKey:@"megatype"] integerValue] == 4) {
        [self beginBackgroundTaskWithName:@"VoIP"];
    }
    
    // Message
    if ([[[payload dictionaryPayload] objectForKey:@"megatype"] integerValue] == 2) {
        NSString *chatIdB64 = [[[payload dictionaryPayload] objectForKey:@"megadata"] objectForKey:@"chatid"];
        NSString *msgIdB64 = [[[payload dictionaryPayload] objectForKey:@"megadata"] objectForKey:@"msgid"];
        NSString *silent = [[[payload dictionaryPayload] objectForKey:@"megadata"] objectForKey:@"silent"];
        if (chatIdB64 && msgIdB64) {
            uint64_t chatId = [MEGASdk handleForBase64UserHandle:chatIdB64];
            uint64_t msgId = [MEGASdk handleForBase64UserHandle:msgIdB64];
            MEGAChatMessage *message = [[MEGASdkManager sharedMEGAChatSdk] messageForChat:chatId messageId:msgId];
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatId];
            
            [[MEGASdkManager sharedMEGAChatSdk] pushReceivedWithBeep:YES chatId:chatId];
                                    
            if (chatRoom && message && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                MEGALocalNotificationManager *localNotificationManager = [[MEGALocalNotificationManager alloc] initWithChatRoom:chatRoom message:message silent:NO];
                [localNotificationManager proccessNotification];
            } else {
                [[MEGAStore shareInstance] insertMessage:msgId chatId:chatId];
            }
        } else if (silent) {
            [[MEGASdkManager sharedMEGAChatSdk] pushReceivedWithBeep:NO chatId:~(uint64_t)0];
        }
    }
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"userNotificationCenter didReceiveNotificationResponse %@", response);
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[response.notification.request.identifier]];
    
    [self openChatRoomWithChatNumber:response.notification.request.content.userInfo[@"chatId"]];
    
    completionHandler();
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (@available(iOS 10, *)) {} else {
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
            [self openChatRoomWithChatNumber:notification.userInfo[@"chatId"]];
        }
    }
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    if (self.showChooseAccountTypeLater) {
        [self showChooseAccountType];
        
        self.chooseAccountTypeLater = NO;
        [[MEGAPurchase sharedInstance] setPricingsDelegate:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    NSInteger userListCount = userList.size.integerValue;
    for (NSInteger i = 0 ; i < userListCount; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        
        if (user.changes) {
            if ([user hasChangedType:MEGAUserChangeTypeEmail]) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:user.handle];
                if (moUser) {
                    [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle email:user.email];
                } else {
                    [[MEGAStore shareInstance] insertUserWithUserHandle:user.handle firstname:nil lastname:nil email:user.email];
                }
            }
            
            if (user.isOwnChange == 0) { //If the change is external
                if (user.handle == [MEGASdkManager sharedMEGASdk].myUser.handle) {
                    if ([user hasChangedType:MEGAUserChangeTypeAvatar]) { //If you have changed your avatar, remove the old and request the new one
                        NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
                        NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:userBase64Handle];
                        [NSFileManager.defaultManager mnz_removeItemAtPath:avatarFilePath];
                        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath];
                    }
                    
                    if ([user hasChangedType:MEGAUserChangeTypeFirstname]) {
                        [[MEGASdkManager sharedMEGASdk] getUserAttributeType:MEGAUserAttributeFirstname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeLastname]) {
                        [[MEGASdkManager sharedMEGASdk] getUserAttributeType:MEGAUserAttributeLastname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeRichPreviews]) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"richLinks"];
                        MEGAGetAttrUserRequestDelegate *delegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                            [NSUserDefaults.standardUserDefaults setBool:request.flag forKey:@"richLinks"];
                        }];
                        [[MEGASdkManager sharedMEGASdk] isRichPreviewsEnabledWithDelegate:delegate];
                    }
                } else {
                    if ([user hasChangedType:MEGAUserChangeTypeAvatar]) {
                        NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
                        NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:userBase64Handle];
                        [NSFileManager.defaultManager mnz_removeItemAtPath:avatarFilePath];
                        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeFirstname]) {
                        [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeLastname]) {
                        [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname];
                    }
                }
            }
            
        } else if (user.visibility == MEGAUserVisibilityVisible) {
            [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
            [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname];
        }
    }
}

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (!nodeList) {
        MEGATransferList *transferList = [api uploadTransfers];
        if (transferList.size.integerValue == 0) {
            [[CameraUploadManager shared] startUploading];
            if ([CameraUploads syncManager].isCameraUploadsEnabled) {
                MEGALogInfo(@"Enable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
            }
        } else {
            for (NSInteger i = 0; i < transferList.size.integerValue; i++) {
                MEGATransfer *transfer = [transferList transferAtIndex:i];
                [transfer mnz_cancelPendingCUTransfer];
                
                if ([transfer.appData containsString:@"CU"] && [CameraUploads syncManager].isCameraUploadsEnabled && ([MEGAReachabilityManager isReachableViaWiFi] || [CameraUploads syncManager].isUseCellularConnectionEnabled)) {
                    MEGALogInfo(@"Camera Upload should be delayed");
                    [CameraUploads syncManager].shouldCameraUploadsBeDelayed = YES;
                }
            }
        }
            
        [Helper startPendingUploadTransferIfNeeded];

    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSArray<MEGANode *> *nodesToIndex = [nodeList mnz_nodesArrayFromNodeList];
            MEGALogDebug(@"Spotlight indexing %lu nodes updated", nodesToIndex.count);
            for (MEGANode *node in nodesToIndex) {
                [self.indexer index:node];
            }
        });
    }
}

- (void)onAccountUpdate:(MEGASdk *)api {
    [api getAccountDetails];
}

- (void)onEvent:(MEGASdk *)api event:(MEGAEvent *)event {
    switch (event.type) {
        case EventChangeToHttps:
            [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] setBool:YES forKey:@"useHttpsOnly"];
            break;
            
        case EventAccountBlocked:
            _messageForSuspendedAccount = event.text;
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
            
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
                isFirstFetchNodesRequestUpdate = YES;
                LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
                [launchVC.activityIndicatorView setHidden:NO];
                [launchVC.activityIndicatorView startAnimating];
            }
            break;
        }
            
        case MEGARequestTypeLogout: {
            if (self.urlType == URLTypeCancelAccountLink) {
                return;
            }
            
            if (request.paramType != MEGAErrorTypeApiESSL) {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudLogOut"] status:AMLocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
    if ([request type] == MEGARequestTypeFetchNodes){
        if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
            [self invalidateTimerAPI_EAGAIN];
            
            LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
            float progress = [[request transferredBytes] floatValue] / [[request totalBytes] floatValue];
            
            if (isFirstFetchNodesRequestUpdate) {
                [launchVC.activityIndicatorView stopAnimating];
                [launchVC.activityIndicatorView setHidden:YES];
                isFirstFetchNodesRequestUpdate = NO;
                
                [launchVC.logoImageView.layer addSublayer:launchVC.circularShapeLayer];
                launchVC.circularShapeLayer.strokeStart = 0.0f;
            }
            
            if (progress > 0 && progress <= 1.0) {
                launchVC.circularShapeLayer.strokeEnd = progress;
            }
        }
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs: {
                if ([request type] == MEGARequestTypeLogin) {
                    [Helper logout];
                } else if ([request type] == MEGARequestTypeQuerySignUpLink) {
                    [self showLinkNotValid];
                }
                break;
            }
                
            case MEGAErrorTypeApiEExpired: {
                if (request.type == MEGARequestTypeQueryRecoveryLink || request.type == MEGARequestTypeConfirmRecoveryLink) {
                    NSString *alertTitle;
                    if (self.urlType == URLTypeCancelAccountLink) {
                        alertTitle = AMLocalizedString(@"cancellationLinkHasExpired", @"During account cancellation (deletion)");
                    } else if (self.urlType == URLTypeRecoverLink) {
                        alertTitle = AMLocalizedString(@"recoveryLinkHasExpired", @"Message shown during forgot your password process if the link to reset password has expired");
                    }
                    UIAlertController *linkHasExpiredAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [linkHasExpiredAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                    [UIApplication.mnz_presentingViewController presentViewController:linkHasExpiredAlertController animated:YES completion:nil];
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                if ([request type] == MEGARequestTypeQuerySignUpLink) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used") message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
                } else if ([request type] == MEGARequestTypeQueryRecoveryLink) {
                    [self showLinkNotValid];
                }
                break;
            }
                
            case MEGAErrorTypeApiESid: {                                
                if (self.urlType == URLTypeCancelAccountLink) {
                    [Helper logout];
                    
                    UIAlertController *accountCanceledSuccessfullyAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"accountCanceledSuccessfully", @"During account cancellation (deletion)") message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [accountCanceledSuccessfullyAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleCancel handler:nil]];
                    [UIApplication.mnz_visibleViewController presentViewController:accountCanceledSuccessfullyAlertController animated:YES completion:^{
                        self.urlType = URLTypeDefault;
                    }];
                    return;
                }
                
                if ([request type] == MEGARequestTypeLogin || [request type] == MEGARequestTypeLogout) {
                    if (!self.API_ESIDAlertController || UIApplication.mnz_presentingViewController.presentedViewController != self.API_ESIDAlertController) {
                        self.API_ESIDAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"loggedOut_alertTitle", nil) message:AMLocalizedString(@"loggedOutFromAnotherLocation", nil) preferredStyle:UIAlertControllerStyleAlert];
                        [self.API_ESIDAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                        [UIApplication.mnz_presentingViewController presentViewController:self.API_ESIDAlertController animated:YES completion:nil];
                        [Helper logout];
                    }
                }
                break;
            }
                
            case MEGAErrorTypeApiEgoingOverquota:
            case MEGAErrorTypeApiEOverQuota: {
                [self showOverquotaAlert];
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                if ([request type] == MEGARequestTypeSetAttrFile) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                    [NSFileManager.defaultManager mnz_removeItemAtPath:thumbnailFilePath];
                }
                
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                if (request.type == MEGARequestTypeQuerySignUpLink) {
                    [self showLinkNotValid];
                } else if (request.type == MEGARequestTypeLogout && request.paramType == MEGAErrorTypeApiESSL && !self.sslKeyPinningController) {
                    [SVProgressHUD dismiss];
                    _sslKeyPinningController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"sslUnverified_alertTitle", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ignore", @"Button title to allow the user ignore something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        [api setPublicKeyPinning:NO];
                        [api reconnect];
                    }]];
                    
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"retry", @"Button which allows to retry send message in chat conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        [api retryPendingConnections];
                    }]];
                    
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"openBrowser", @"Button title to allow the user open the default browser") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        NSURL *url = [NSURL URLWithString:@"https://www.mega.nz"];
                        
                        if (@available(iOS 10.0, *)) {
                            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
                        } else {
                            [[UIApplication sharedApplication] openURL:url];
                        }
                    }]];
                    
                    [UIApplication.mnz_presentingViewController presentViewController:self.sslKeyPinningController animated:YES completion:nil];
                }
                break;
            }
                
            case MEGAErrorTypeApiEBlocked: {
                if ([request type] == MEGARequestTypeLogin || [request type] == MEGARequestTypeFetchNodes) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:AMLocalizedString(@"accountBlocked", @"Error message when trying to login and the account is blocked") preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
                    [api logout];
                }
                
                break;
            }
                
            default:
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [self invalidateTimerAPI_EAGAIN];
            
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                isAccountFirstLogin = NO;
                isFetchNodesDone = NO;
            } else {
                isAccountFirstLogin = YES;
                self.link = nil;
            }
            [[MEGASdkManager sharedMEGASdk] fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:[MEGAPurchase sharedInstance]];
            [[MEGASdkManager sharedMEGASdk] enableTransferResumption];
            [CameraUploads syncManager].shouldCameraUploadsBeDelayed = NO;
            [self invalidateTimerAPI_EAGAIN];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [[MEGASdkManager sharedMEGASdk] pauseTransfers:YES];
                [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"TransfersPaused"];
            }
            isFetchNodesDone = YES;
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD dismiss];
            
            [self requestUserName];
            [self requestContactsFullname];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"] || isAccountFirstLogin) {
                [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self.mainTBC];
                                
                MEGAChatNotificationDelegate *chatNotificationDelegate = [MEGAChatNotificationDelegate new];
                [[MEGASdkManager sharedMEGAChatSdk] addChatNotificationDelegate:chatNotificationDelegate];
                
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                    [[MEGASdkManager sharedMEGAChatSdk] connectInBackground];
                } else {
                    [[MEGASdkManager sharedMEGAChatSdk] connect];
                }
                if (isAccountFirstLogin) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IsChatEnabled"];
                    [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] setBool:YES forKey:@"IsChatEnabled"];
                }
            }
            [self showMainTabBar];

            NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                if (![sharedUserDefaults boolForKey:@"treeCompleted"]) {
                    [self.indexer generateAndSaveTree];
                }
                @try {
                    [self.indexer indexTree];
                } @catch (NSException *exception) {
                    MEGALogError(@"Exception during spotlight indexing: %@", exception);
                }
            });
            
            isOverquota = NO;
            [[MEGASdkManager sharedMEGASdk] getAccountDetails];
            [self copyDatabasesForExtensions];
            
            break;
        }
            
        case MEGARequestTypeQuerySignUpLink: {
            if (self.urlType == URLTypeConfirmationLink) {
                if (request.flag) {
                    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionId"]) {
                        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                        loginRequestDelegate.confirmAccountInOtherClient = YES;
                        NSString *base64pwkey = [SAMKeychain passwordForService:@"MEGA" account:@"base64pwkey"];
                        NSString *stringHash = [api hashForBase64pwkey:base64pwkey email:request.email];
                        [api fastLoginWithEmail:request.email stringHash:stringHash base64pwKey:base64pwkey delegate:loginRequestDelegate];
                    } else {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used") message:nil preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                            MEGANavigationController *navigationController = (MEGANavigationController *)self.window.rootViewController;
                            if ([navigationController.topViewController isKindOfClass:[LoginViewController class]]) {
                                LoginViewController *loginVC = (LoginViewController *)navigationController.topViewController;
                                loginVC.emailString = request.email;
                                [loginVC viewWillAppear:NO];
                            }
                        }]];
                        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
                    }
                } else {
                    [self presentConfirmViewControllerType:ConfirmTypeAccount link:request.link email:request.email];
                }
            } else if (self.urlType == URLTypeNewSignUpLink) {

                if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
                    _emailOfNewSignUpLink = [request email];
                    UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"alreadyLoggedInAlertTitle", nil) message:AMLocalizedString(@"alreadyLoggedInAlertMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
                    [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        _emailOfNewSignUpLink = nil;
                    }]];
                    [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [[MEGASdkManager sharedMEGASdk] logout];
                    }]];
                    [UIApplication.mnz_presentingViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
                } else {
                    if ([self.window.rootViewController isKindOfClass:[MEGANavigationController class]]) {
                        MEGANavigationController *navigationController = (MEGANavigationController *)self.window.rootViewController;
                        
                        if ([navigationController.topViewController isKindOfClass:[LoginViewController class]]) {
                            LoginViewController *loginVC = (LoginViewController *)navigationController.topViewController;
                            [loginVC performSegueWithIdentifier:@"CreateAccountStoryboardSegueID" sender:[request email]];
                            _emailOfNewSignUpLink = nil;
                        } else if ([navigationController.topViewController isKindOfClass:[CreateAccountViewController class]]) {
                            CreateAccountViewController *createAccountVC = (CreateAccountViewController *)navigationController.topViewController;
                            [createAccountVC setEmailString:[request email]];
                            [createAccountVC viewDidLoad];
                        }
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeQueryRecoveryLink: {
            if (self.urlType == URLTypeChangeEmailLink) {
                [self presentConfirmViewControllerType:ConfirmTypeEmail link:request.link email:request.email];
            } else if (self.urlType == URLTypeCancelAccountLink) {
                [self presentConfirmViewControllerType:ConfirmTypeCancelAccount link:request.link email:request.email];
            } else if (self.urlType == URLTypeRecoverLink) {
                if ([UIApplication.sharedApplication.keyWindow.rootViewController isKindOfClass:MEGANavigationController.class]) {
                    MEGANavigationController *navigationController = (MEGANavigationController *)UIApplication.sharedApplication.keyWindow.rootViewController;
                    if ([navigationController.topViewController isKindOfClass:TwoFactorAuthenticationViewController.class]) {
                        [navigationController popViewControllerAnimated:NO];
                        
                        if ([navigationController.topViewController isKindOfClass:LoginViewController.class]) {
                            LoginViewController *loginVC = (LoginViewController *)navigationController.topViewController;
                            [loginVC cleanPasswordTextField];
                        }
                    }
                }
                
                if (request.flag) {
                    UIAlertController *masterKeyLoggedInAlertController;
                    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                        masterKeyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:AMLocalizedString(@"youRecoveryKeyIsGoingTo", @"Text of the alert after opening the recovery link to reset pass being logged.") preferredStyle:UIAlertControllerStyleAlert];
                    } else {
                        masterKeyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:AMLocalizedString(@"pleaseEnterYourRecoveryKey", @"A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.") preferredStyle:UIAlertControllerStyleAlert];
                        [masterKeyLoggedInAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                            textField.placeholder = AMLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
                            [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                            textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                                return !textField.text.mnz_isEmpty;
                            };
                        }];
                    }
                    
                    [masterKeyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                    [masterKeyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        NSString *masterKey = masterKeyLoggedInAlertController.textFields.count ? masterKeyLoggedInAlertController.textFields[0].text : [[MEGASdkManager sharedMEGASdk] masterKey];
                        [self presentChangeViewType:ChangeTypeResetPassword email:self.emailOfNewSignUpLink masterKey:masterKey link:self.recoveryLink];
                        self.emailOfNewSignUpLink = nil;
                        self.recoveryLink = nil;
                    }]];
                    
                    self.emailOfNewSignUpLink = request.email;
                    self.recoveryLink = request.link;
                    
                    [UIApplication.mnz_presentingViewController presentViewController:masterKeyLoggedInAlertController animated:YES completion:nil];
                } else {
                    [self presentChangeViewType:ChangeTypeParkAccount email:request.email masterKey:nil link:request.link];
                }
            }
            break;
        }
            
        case MEGARequestTypeLogout: {            
            [Helper logout];
            [SVProgressHUD dismiss];
            [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:nil];
            
            if (self.messageForSuspendedAccount) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:self.messageForSuspendedAccount preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
            }
            
            if ((self.urlType == URLTypeConfirmationLink) && self.link) {
                [[MEGASdkManager sharedMEGASdk] querySignupLink:self.link.mnz_MEGAURL];
                self.link = nil;
            }
            
            if ((self.urlType == URLTypeNewSignUpLink) && (_emailOfNewSignUpLink != nil)) {
                if ([self.window.rootViewController isKindOfClass:[MEGANavigationController class]]) {
                    MEGANavigationController *navigationController = (MEGANavigationController *)self.window.rootViewController;
                    
                    if ([navigationController.topViewController isKindOfClass:[LoginViewController class]]) {
                        LoginViewController *loginVC = (LoginViewController *)navigationController.topViewController;
                        [loginVC performSegueWithIdentifier:@"CreateAccountStoryboardSegueID" sender:_emailOfNewSignUpLink];
                        _emailOfNewSignUpLink = nil;
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeAccountDetails: {
            
            [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:[request megaAccountDetails]];
            
            if (isOverquota) {
                NSString *overquotaMessage = [[request megaAccountDetails] type] > MEGAAccountTypeFree ? AMLocalizedString(@"quotaExceeded", nil) : AMLocalizedString(@"overquotaAlert_message", nil);
                self.overquotaAlertView = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"overquotaAlert_title", nil) message:overquotaMessage preferredStyle:UIAlertControllerStyleAlert];
                [self.overquotaAlertView addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self.overquotaAlertView addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
                    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
                    
                    if (self.window.rootViewController.presentedViewController) {
                        [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
                            [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
                        }];
                    } else {
                        [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
                    }
                }]];
                [UIApplication.mnz_presentingViewController presentViewController:self.overquotaAlertView animated:YES completion:nil];
                isOverquota = NO;
            }
            
            break;
        }
            
        case MEGARequestTypeGetAttrUser: {
            MEGAUser *user = (request.email == nil) ? [[MEGASdkManager sharedMEGASdk] myUser] : [api contactForEmail:request.email];
            if (user) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:user.handle];
                if (moUser) {
                    if (request.paramType == MEGAUserAttributeFirstname && ![request.text isEqualToString:moUser.firstname]) {
                        [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle firstname:request.text];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname && ![request.text isEqualToString:moUser.lastname]) {
                        [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle lastname:request.text];
                    }
                } else {
                    if (request.paramType == MEGAUserAttributeFirstname) {
                        [[MEGAStore shareInstance] insertUserWithUserHandle:user.handle firstname:request.text lastname:nil email:user.email];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname) {
                        [[MEGAStore shareInstance] insertUserWithUserHandle:user.handle firstname:nil lastname:request.text email:user.email];
                    }
                }
            } else {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithEmail:request.email];
                if (moUser) {
                    if (request.paramType == MEGAUserAttributeFirstname && ![request.text isEqualToString:moUser.firstname]) {
                        [[MEGAStore shareInstance] updateUserWithEmail:request.email firstname:request.text];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname && ![request.text isEqualToString:moUser.lastname]) {
                        [[MEGAStore shareInstance] updateUserWithEmail:request.email lastname:request.text];
                    }
                } else {
                    if (request.paramType == MEGAUserAttributeFirstname) {
                        [[MEGAStore shareInstance] insertUserWithUserHandle:~(uint64_t)0 firstname:request.text lastname:nil email:request.email];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname) {
                        [[MEGAStore shareInstance] insertUserWithUserHandle:~(uint64_t)0 firstname:nil lastname:request.text email:request.email];
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeSetAttrUser: {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] myUser];
            if (user) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:user.handle];
                if (moUser) {
                    if (request.paramType == MEGAUserAttributeFirstname && ![request.text isEqualToString:moUser.firstname]) {
                        [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle firstname:request.text];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname && ![request.text isEqualToString:moUser.lastname]) {
                        [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle lastname:request.text];
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeGetUserEmail: {
            MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:request.nodeHandle];
            if (moUser) {
                [[MEGAStore shareInstance] updateUserWithUserHandle:request.nodeHandle email:request.email];
            } else {
                [[MEGAStore shareInstance] insertUserWithUserHandle:request.nodeHandle firstname:nil lastname:nil email:request.email];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if (!timerAPI_EAGAIN.isValid) {
                [self startTimerAPI_EAGAIN];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestStart:(MEGAChatSdk *)api request:(MEGAChatRequest *)request {
    if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]] && request.type == MEGAChatRequestTypeConnect) {
        LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
        [launchVC.activityIndicatorView setHidden:NO];
        [launchVC.activityIndicatorView startAnimating];
    }
}

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    if ([error type] != MEGAChatErrorTypeOk) {
        MEGALogError(@"onChatRequestFinish error type: %td request type: %td", error.type, request.type);
        return;
    }
    
    if (request.type == MEGAChatRequestTypeLogout) {
        [MEGASdkManager destroySharedMEGAChatSdk];
        
        [self.mainTBC setBadgeValueForChats];
    }
    
    MEGALogInfo(@"onChatRequestFinish request type: %td", request.type);
}

#pragma mark - MEGAChatDelegate

- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState {
    MEGALogInfo(@"onChatInitStateUpdate new state: %td", newState);
    if (newState == MEGAChatInitError) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:@"Chat disabled (Init error). Enable chat in More -> Settings -> Chat" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        [[MEGASdkManager sharedMEGAChatSdk] logout];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)onChatPresenceConfigUpdate:(MEGAChatSdk *)api presenceConfig:(MEGAChatPresenceConfig *)presenceConfig {
    if (!presenceConfig.isPending) {
        self.signalActivityRequired = presenceConfig.isSignalActivityRequired;
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    MEGALogInfo(@"onChatConnectionStateUpdate: %@, new state: %d", [MEGASdk base64HandleForUserHandle:chatId], newState);
    if (self.chatRoom.chatId == chatId && newState == MEGAChatConnectionOnline) {
        [self performCall];
    }
    // INVALID_HANDLE = ~(uint64_t)0
    if (chatId == ~(uint64_t)0 && newState == MEGAChatConnectionOnline) {
        [MEGAReachabilityManager sharedManager].chatRoomListState = MEGAChatRoomListStateOnline;
    } else if (newState >= MEGAChatConnectionLogging) {
        [MEGAReachabilityManager sharedManager].chatRoomListState = MEGAChatRoomListStateInProgress;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload  && !transfer.isStreamingTransfer) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        [[Helper downloadingNodes] setObject:[NSNumber numberWithInteger:transfer.tag] forKey:base64Handle];
    }
    
    if (transfer.type == MEGATransferTypeUpload) {
        [transfer mnz_createThumbnailAndPreview];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        [transfer mnz_cancelPendingCUTransfer];
    }
    
    if (transfer.state == MEGATransferStatePaused) {
        [Helper startPendingUploadTransferIfNeeded];
    }

}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type == MEGAErrorTypeApiEOverQuota && error.value) {
        [SVProgressHUD dismiss];
        
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        customModalAlertVC.image = [UIImage imageNamed:@"transfer-quota-empty"];
        customModalAlertVC.viewTitle = AMLocalizedString(@"depletedTransferQuota_title", @"Title shown when you almost had used your available transfer quota.");
        customModalAlertVC.detail = AMLocalizedString(@"depletedTransferQuota_message", @"Description shown when you almost had used your available transfer quota.");
        customModalAlertVC.action = AMLocalizedString(@"seePlans", @"Button title to see the available pro plans in MEGA");
        customModalAlertVC.dismiss = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        if ([[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
            customModalAlertVC.bonus = AMLocalizedString(@"getBonus", @"Button title to see the available bonus");
        }
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:^{
                if ([MEGAPurchase sharedInstance].products.count > 0) {
                    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
                    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
                    
                    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
                } else {
                    // Redirect to my account if the products are not available
                    [self.mainTBC setSelectedIndex:4];
                }
            }];
        };
        
        [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    //Delete transfer from dictionary file even if we get an error
    MEGANode *node = nil;
    if ([transfer type] == MEGATransferTypeDownload) {
        node = [api nodeForHandle:transfer.nodeHandle];
        if (!node) {
            node = [transfer publicNode];
        }
        if (node) {
            [[Helper downloadingNodes] removeObjectForKey:node.base64Handle];
        }
    }
    
    if (transfer.type == MEGATransferTypeUpload) {
        [transfer mnz_renameOrRemoveThumbnailAndPreview];
        
        if ([CameraUploads syncManager].shouldCameraUploadsBeDelayed) {
            [CameraUploads syncManager].shouldCameraUploadsBeDelayed = NO;
            if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
                MEGALogInfo(@"Enable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
            }
        }
        
        if ([transfer.appData containsString:@"attachToChatID"]) {
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogInfo(@"Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
        }
        
        [transfer mnz_parseAppData];
        
        [Helper startPendingUploadTransferIfNeeded];
    }
    
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEgoingOverquota:
            case MEGAErrorTypeApiEOverQuota: {
                [self showOverquotaAlert];
                break;
            }
                
            default:{
                if (error.type != MEGAErrorTypeApiESid && error.type != MEGAErrorTypeApiESSL && error.type != MEGAErrorTypeApiEExist && error.type != MEGAErrorTypeApiEIncomplete) {
                    NSString *transferFailed = AMLocalizedString(@"Transfer failed:", @"Notification message shown when a transfer failed. Keep colon.");
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@\n%@ %@", transfer.fileName, transferFailed, AMLocalizedString(error.name, nil)]];
                }
                break;
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        // Don't add to the database files saved in others applications
        if ([transfer.appData containsString:@"SaveInPhotosApp"]) {
            [transfer mnz_saveInPhotosApp];
            return;
        }
        
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node];
        if (!offlineNodeExist) {
            NSRange replaceRange = [transfer.path rangeOfString:@"Documents/"];
            if (replaceRange.location != NSNotFound) {
                MEGALogDebug(@"Transfer finish: insert node to DB: base64 handle: %@ - local path: %@", node.base64Handle, transfer.path);
                NSString *result = [transfer.path stringByReplacingCharactersInRange:replaceRange withString:@""];
                [[MEGAStore shareInstance] insertOfflineNode:node api:api path:[result decomposedStringWithCanonicalMapping]];
            }
        }
        
        if (transfer.fileName.mnz_isVideoPathExtension && !node.hasThumbnail) {
            NSURL *videoURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path]];
            [node mnz_generateThumbnailForVideoAtPath:videoURL];
        }
        
        [transfer mnz_setNodeCoordinates];
    }
}

#pragma mark - MEGAApplicationDelegate

- (void)application:(MEGAApplication *)application willSendTouchEvent:(UIEvent *)event {
    if (self.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
}

@end
