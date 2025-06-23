#import "AppDelegate.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import <Intents/Intents.h>
#import <Photos/Photos.h>
#import <QuickLook/QuickLook.h>
#import <UserNotifications/UserNotifications.h>

#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"

#import "MEGALinkManager.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPurchase.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGATransfer+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "AchievementsViewController.h"
#import "CheckEmailAndFollowTheLinkViewController.h"
#import "ContactsViewController.h"
#import "ContactRequestsViewController.h"
#import "LaunchViewController.h"
#import "MainTabBarController.h"
#import "OnboardingViewController.h"

#import "MEGAChatNotificationDelegate.h"
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAShowPasswordReminderRequestDelegate.h"
#import "CameraUploadManager+Settings.h"
#import "TransferSessionManager.h"
#import <SDWebImage/SDWebImage.h>

@import Firebase;
@import MEGAL10nObjc;
@import MEGAAppSDKRepo;
@import SDWebImageWebPCoder;
#import "MEGA-Swift.h"

@interface AppDelegate () <UIApplicationDelegate, UNUserNotificationCenterDelegate, LTHPasscodeViewControllerDelegate, LaunchViewControllerDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, MEGAGlobalDelegate, MEGAPurchasePricingDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
}

@property (nonatomic, strong) UIView *privacyView;

@property (nonatomic, strong) NSString *quickActionType;

@property (nonatomic, strong) UIAlertController *API_ESIDAlertController;

@property (nonatomic, weak) MainTabBarController *mainTBC;

@property (nonatomic) MEGANotificationType megatype; //1 share folder, 2 new message, 3 contact request
@property (nonatomic, nullable) NSDictionary *megaGenericRemoteNotif;

@property (strong, nonatomic) NSString *email;
@property (nonatomic) BOOL presentInviteContactVCLater;

@property (nonatomic, getter=isNewAccount) BOOL newAccount;
@property (nonatomic, getter=showChooseAccountTypeLater) BOOL chooseAccountTypeLater;

@property (nonatomic, strong) UIAlertController *sslKeyPinningController;

@property (nonatomic) NSMutableDictionary *backgroundTaskMutableDictionary;

@property (nonatomic, getter=isAccountExpiredPresented) BOOL accountExpiredPresented;

@property (nonatomic) MEGAChatInit chatLastKnownInitState;

@property (nonatomic, strong) QuickAccessWidgetManager *quickAccessWidgetManager API_AVAILABLE(ios(14.0));

@property (nonatomic, strong) RatingRequestMonitor *ratingRequestMonitor;
@property (nonatomic, strong) SpotlightIndexer *spotlightIndexer;

@property (nonatomic) MEGAError * _Nullable temporaryTransferErrorToDisplayLater;
@property (nonatomic) MEGATransfer * _Nullable temporaryTransferTypeToDisplayLater;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FIRApp configure];
    [AppEnvironmentConfigurator configAppEnvironment];
    
#if defined(DEBUG) || defined(QA_CONFIG)
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelFatal];
#endif
    
    [UncaughtExceptionHandler registerHandler];
    [self registerAppExitHandlers];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSQLiteDiskFullNotification) name:MEGASQLiteDiskFullNotification object:nil];
    
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    
    NSError *error;
    [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3" error:&error];
    if (error.code == errSecInteractionNotAllowed) {
        exit(0);
    }
    
    [MEGASdk setLogToConsole:YES];
    
    [self enableLogsIfNeeded];
    
    [self initialiseModules];
    
    [self enableRequestStatusMonitor];

    MEGALogDebug(@"[App Lifecycle] Application will finish launching with options: %@", launchOptions);
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:[NSString stringWithFormat: @"Application will finish launching with options: %@", launchOptions]
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self migrateLocalCachesLocation];
    [self registerCameraUploadBackgroundRefresh];

    if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        NSDictionary *remoteNotificationData = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
        _megatype = (MEGANotificationType)[[remoteNotificationData objectForKey:@"megatype"] integerValue];
        
        if (_megatype == MEGANotificationTypeGeneric) {
            _megaGenericRemoteNotif = remoteNotificationData;
        }
    }
    
    SDImageWebPCoder *webPCoder = [SDImageWebPCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:webPCoder];
    
    [AudioSessionUseCaseOCWrapper.alloc.init configureDefaultAudioSession];
    
    [MEGAReachabilityManager sharedManager];
    
    [CameraUploadManager.shared setupCameraUploadWhenApplicationLaunches];
    
    [Helper restoreAPISetting];
    [self chatUploaderSetup];
    [MEGASdk.shared addMEGARequestDelegate:self];
    [MEGASdk.shared addMEGATransferDelegate:self];
    [MEGASdk.sharedFolderLink addMEGATransferDelegate:self];
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    
    [MEGAChatSdk.shared addChatDelegate:self];
    [MEGAChatSdk.shared addChatRequestDelegate:self];
        
    [MEGASdk.shared httpServerSetMaxBufferSize:[UIDevice currentDevice].maxBufferSize];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"presentPasscodeLater"];

    NSString *languageCode = NSBundle.mainBundle.preferredLocalizations.firstObject;
    [MEGASdk.shared setLanguageCode:languageCode];
    [MEGASdk.sharedFolderLink setLanguageCode:languageCode];
    
    [self injectSDKRepoDependencies];
    [self injectAuthenticationDependencies];
    [self injectInfrastructureDependencies];

    self.backgroundTaskMutableDictionary = [[NSMutableDictionary alloc] init];
    
    [[AppFirstLaunchSecurityChecker newChecker] performSecurityCheck];
    
    [AppearanceManager setupAppearance:self.window.traitCollection];
    
    [MEGALinkManager resetLinkAndURLType];
    isFetchNodesDone = NO;
    _presentInviteContactVCLater = NO;

    NSString *sessionV3 = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (sessionV3) {
        NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
        if (![sharedUserDefaults boolForKey:@"extensions"]) {
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
            [SAMKeychain setPassword:sessionV3 forService:@"MEGA" account:@"sessionV3"];
            [sharedUserDefaults setBool:YES forKey:@"extensions"];
        }
        if (![sharedUserDefaults boolForKey:@"extensions-passcode"]) {
            [[LTHPasscodeViewController sharedUser] resetPasscode];
            [sharedUserDefaults setBool:YES forKey:@"extensions-passcode"];
        }
        
        isAccountFirstLogin = NO;

        [self initProviderDelegate];
                
        MEGAChatInit chatInit = [MEGAChatSdk.shared initKarereWithSid:sessionV3];
        [self removeSDKLoggerWhenInitChatIfNeeded];
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere with session failed");
            NSString *message = [NSString stringWithFormat:@"Error (%ld) initializing the chat", (long)chatInit];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"error", @"nil") message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
            [MEGAChatSdk.shared logout];
            [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        } else if (chatInit == MEGAChatInitOnlineSession || chatInit == MEGAChatInitOfflineSession) {
            [self importMessagesFromNSE];
        }
        
        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        [MEGASdk.shared fastLoginWithSession:sessionV3 delegate:loginRequestDelegate];
        
        if ([MEGAReachabilityManager isReachable]) {
            [self showLaunchViewController];
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO
                                                                         withLogout:YES
                                                                     andLogoutTitle:LocalizedString(@"logoutLabel", @"")];
                [self.window setRootViewController:[LTHPasscodeViewController sharedUser]];
            } else {
                _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                UIViewController *mainController = [self adsMainTabBarController:_mainTBC
                                                             onViewFirstAppeared:nil];
                [self.window setRootViewController:mainController];
            }
        }
        
        if ([sharedUserDefaults boolForKey:@"useHttpsOnly"]) {
            [MEGASdk.shared useHttpsOnly:YES];
        }
        
        [CameraUploadManager enableAdvancedSettingsForUpgradingUserIfNeeded];
    } else {
        // Resume ephemeral account
        self.window.rootViewController = [self makeOnboardingViewController];
        NSString *sessionId = [SAMKeychain passwordForService:@"MEGA" account:@"sessionId"];
        if (sessionId && ![[[launchOptions objectForKey:@"UIApplicationLaunchOptionsURLKey"] absoluteString] containsString:@"confirm"]) {
            __weak typeof(self) weakSelf = self;
            MEGACreateAccountRequestDelegate *createAccountRequestDelegate = [[MEGACreateAccountRequestDelegate alloc] initWithCompletion:^ (MEGAError *error) {
                [weakSelf showConfirmEmailView];
            }];
            createAccountRequestDelegate.resumeCreateAccount = YES;
            [MEGASdk.shared resumeCreateAccountWithSessionId:sessionId delegate:createAccountRequestDelegate];
        } else {
            [self listenToStorePaymentTransactions];
        }
    }
    
    UIApplicationShortcutItem *applicationShortcutItem = launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
    if (applicationShortcutItem != nil) {
        if (isFetchNodesDone) {
            [self manageQuickActionType:applicationShortcutItem.type];
        } else {
            self.quickActionType = applicationShortcutItem.type;
        }
    }
    
    MEGALogDebug(@"[App Lifecycle] Application did finish launching with options %@", launchOptions);
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:[NSString stringWithFormat: @"Application did finish launching with options: %@", launchOptions]
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    [self.window makeKeyAndVisible];
    if (application.applicationState != UIApplicationStateBackground) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllPendingNotificationRequests];
        [center removeAllDeliveredNotifications];
    }
    
    [self.ratingRequestMonitor startMonitoring];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will resign active");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application will resign active"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    if (MEGASdk.isLoggedIn) {
        [self beginBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    }
    
    [MEGASdk.shared areTherePendingTransfersWithCompletion:^(BOOL pendingTransfers) {
        if (pendingTransfers) {
            [self beginBackgroundTaskWithName:@"PendingTasks"];
        }
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did enter background");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application did enter background"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    [MEGAChatSdk.shared setBackgroundStatus:YES];
    [MEGAChatSdk.shared saveCurrentState];

    [LTHPasscodeViewController.sharedUser setDelegate:self];
    
    if (self.privacyView == nil) {
        UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
        privacyVC.view.backgroundColor = UIColor.systemBackgroundColor;
        self.privacyView = privacyVC.view;
    }
    [self.window addSubview:self.privacyView];
    
    [self application:application shouldHideWindows:YES];
    
    if (![NSStringFromClass([UIApplication mnz_keyWindow].class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will enter foreground");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application will enter foreground"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    [self checkChatInitState];
    [MEGAReachabilityManager.sharedManager retryOrReconnect];
    
    [MEGAChatSdk.shared setBackgroundStatus:NO];
    
    if (MEGASdk.isLoggedIn && self->isFetchNodesDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MEGAShowPasswordReminderRequestDelegate *showPasswordReminderDelegate = [[MEGAShowPasswordReminderRequestDelegate alloc] initToLogout:NO];
            [MEGASdk.shared shouldShowPasswordReminderDialogAtLogout:NO delegate:showPasswordReminderDelegate];
        });
    }
    
    [self.privacyView removeFromSuperview];
    self.privacyView = nil;
    
    [self application:application shouldHideWindows:NO];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllPendingNotificationRequests];
    [center removeAllDeliveredNotifications];
    
    [self showTurnOnNotificationsIfNeeded];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did become active");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application did become active"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    [sharedUserDefaults setInteger:0 forKey:MEGAApplicationIconBadgeNumber];    
    application.applicationIconBadgeNumber = 0;
    
    [MEGAChatSdk.shared signalPresenceActivity];
    
    if (![NSStringFromClass([UIApplication mnz_keyWindow].class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] enablePasscodeWhenApplicationEntersBackground];
    }
    
    [self endBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    [self endBackgroundTaskWithName:@"PendingTasks"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will terminate");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application will terminate"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[MEGAPurchase sharedInstance]];

    [AudioPlayerManager.shared playbackStoppedForCurrentItem];
    [MEGASdkCleanUp localLogoutAndCleanUp];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    MEGALogDebug(@"[App Lifecycle] Application open URL %@", url);
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:[NSString stringWithFormat:@"Application open URL %@", url]
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    MEGALinkManager.linkURL = url;
    [self manageLink:url];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    MEGALogDebug(@"[App Lifecycle] Application continue user activity %@", userActivity.activityType);
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:[NSString stringWithFormat:@"Application continue user activity %@", userActivity.activityType]
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    if ([MEGAReachabilityManager isReachable]) {
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            MEGALinkManager.nodeToPresentBase64Handle = userActivity.userInfo[@"kCSSearchableItemActivityIdentifier"];
            [self openAppFromSpotlight];
            if ([self isAdsMainTabBarRootView] && ![LTHPasscodeViewController doesPasscodeExist]) {
                [MEGALinkManager presentNode];
            }
        } else if ([userActivity.activityType isEqualToString:@"INStartCallIntent"]) {
            INInteraction *interaction = userActivity.interaction;
            INStartCallIntent *startCallIntent = (INStartCallIntent *)interaction.intent;
            [self startCallFromIntent:startCallIntent];
        } else if ([userActivity.activityType isEqualToString:@"NSUserActivityTypeBrowsingWeb"]) {
            NSURL *universalLinkURL = userActivity.webpageURL;
            if (universalLinkURL) {
                MEGALinkManager.linkURL = universalLinkURL;
                [self manageLink:universalLinkURL];
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    MEGALogDebug(@"[App Lifecycle] Application perform action for shortcut item");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application perform action for shortcut item"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    if (isFetchNodesDone) {
        completionHandler([self manageQuickActionType:shortcutItem.type]);
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    MEGALogWarning(@"[App Lifecycle] Application did receive memory warning");
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:@"Application did receive memory warning"
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"[App Lifecycle] application handle events for background session: %@", identifier);
    
    [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                   msg:[NSString stringWithFormat:@"Application handle events for background session: %@", identifier]
                                  file:@(__FILENAME__)
                              function:@(__FUNCTION__)];
    
    [TransferSessionManager.shared saveSessionCompletion:completionHandler forIdentifier:identifier];
    [CameraUploadManager.shared startCameraUploadIfNeeded];
}

#pragma mark - Remote Notification

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
    [MEGASdk.shared registeriOSdeviceToken:deviceTokenString];
    
    [self registerCustomActionsForStartScheduledMeetingNotification];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    MEGALogError(@"[App Lifecycle] Application did fail to register for remote notifications with error %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    MEGALogDebug(@"[App Lifecycle] Application did receive a remote notifications in app state %ld", (long)application.applicationState);
    
    [self handleReceivedRemoteNotificationWithUserInfo:userInfo];
    
    completionHandler(UIBackgroundFetchResultNoData);
}

#pragma mark - Properties

- (QuickAccessWidgetManager *)quickAccessWidgetManager {
    if (_quickAccessWidgetManager == nil) {
        _quickAccessWidgetManager = [[QuickAccessWidgetManager alloc] init];
    }
    
    return _quickAccessWidgetManager;
}

- (RatingRequestMonitor *)ratingRequestMonitor {
    if (_ratingRequestMonitor == nil) {
        _ratingRequestMonitor = [[RatingRequestMonitor alloc] initWithSdk:MEGASdk.shared];
    }
    
    return _ratingRequestMonitor;
}

#pragma mark - Public

- (void)setAccountFirstLogin:(BOOL)isFirstLogin {
    if (isFirstLogin) {
        isAccountFirstLogin = YES;
        if (!self.isNewAccount) {
            self.newAccount = (MEGALinkManager.urlType == URLTypeConfirmationLink);
        }
        if (MEGALinkManager.selectedOption != LinkOptionJoinChatLink) {
            [MEGALinkManager resetLinkAndURLType];
        }
        [NSUserDefaults.standardUserDefaults setObject:[NSDate date] forKey:MEGAFirstLoginDate];
    } else {
        isAccountFirstLogin = NO;
        isFetchNodesDone = NO;
    }
}

#pragma mark - Private

- (void)beginBackgroundTaskWithName:(NSString *)name {
    MEGALogDebug(@"Begin background task with name: %@", name);
    
    @try {
        UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:name expirationHandler:^{
            [self endBackgroundTaskWithName:name];
        }];
        
        if (name && backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            NSNumber *backgroundTaskIdentifierNumber = [NSNumber numberWithUnsignedInteger:backgroundTaskIdentifier];
            NSString *message = [NSString stringWithFormat:@"Begin background task with name %@, bg identifier %@.", name, backgroundTaskIdentifierNumber];
            [CrashlyticsLogger log:message];
            [self.backgroundTaskMutableDictionary setObject:name forKey:backgroundTaskIdentifierNumber];
        }
    } @catch (NSException *exception) {
        MEGALogDebug(@"Can't begin background task with name %@ and with exception %@", name, exception);
    }
}

- (void)endBackgroundTaskWithName:(NSString *)name {
    NSArray *allKeysArray = [self.backgroundTaskMutableDictionary allKeysForObject:name];
    for (NSUInteger i = 0; i < allKeysArray.count; i++) {
        NSNumber *expiringBackgroundTaskIdentifierNumber = [allKeysArray objectAtIndex:i];
        [[UIApplication sharedApplication] endBackgroundTask:expiringBackgroundTaskIdentifierNumber.unsignedIntegerValue];
        MEGALogDebug(@"Ended background task %lu with name: %@", (unsigned long)expiringBackgroundTaskIdentifierNumber.unsignedIntegerValue, name);
        
        [self.backgroundTaskMutableDictionary removeObjectForKey:expiringBackgroundTaskIdentifierNumber];
    }
}

- (void)manageLink:(NSURL *)url {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            if ([UIApplication.mnz_visibleViewController isKindOfClass:VerifyEmailViewController.class] && [url.absoluteString containsString:@"emailverify"]) {
                [self showLink:url];
            } else if (isFetchNodesDone) {
                [self showLink:url];
            }
        } else {
            // Passcode exists and not immediately shows
            if (!LTHPasscodeViewController.didPasscodeTimerEnd) {
                [self showLink:url];
            }
        }
    } else {
        switch ([url mnz_type]) {
            case URLTypeFileLink:
            case URLTypeFolderLink:
                [self showSharedLinkForNoLoggedInUser:url];
                break;
                
            default:
                [self showLink:url];
        }
    }
}

- (void)showLink:(NSURL *)url {
    if (!MEGALinkManager.linkURL) return;
    
    if ([UIApplication.mnz_visibleViewController isKindOfClass:VerifyEmailViewController.class] && [url.absoluteString containsString:@"emailverify"]) {
        [MEGALinkManager processLinkURL:url];
    } else {
        [self dismissPresentedViewsAndDo:^{
            [MEGALinkManager processLinkURL:url];
        }];
    }
}

- (void)dismissPresentedViewsAndDo:(void (^)(void))completion {
    if (self.window.rootViewController.presentedViewController) {
        if ([self.window.rootViewController.presentedViewController isKindOfClass:CheckEmailAndFollowTheLinkViewController.class]) {
            CheckEmailAndFollowTheLinkViewController *checkEmailAndFollowTheLinkVC = (CheckEmailAndFollowTheLinkViewController *)self.window.rootViewController.presentedViewController;
            if (checkEmailAndFollowTheLinkVC.presentedViewController) {
                [checkEmailAndFollowTheLinkVC.presentedViewController dismissViewControllerAnimated:YES completion:^{
                    if (completion) completion();
                }];
            } else {
                if (completion) completion();
            }
        } else {
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
                if (completion) completion();
            }];
        }
    } else if (completion) {
        completion();
    }
}

- (BOOL)manageQuickActionType:(NSString *)type {
    BOOL quickActionManaged = YES;
    if ([AppDelegate matchQuickAction:type with:@"search"]) {
        self.mainTBC.selectedIndex = TabTypeHome;
        MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:TabTypeHome];
        HomeViewController *homeVC = navigationController.viewControllers.firstObject;
        if (self.quickActionType) { //Coming from didFinishLaunchingWithOptions
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [homeVC activateSearch]; // Home already presented, so activate search bar
            } else {
                homeVC.homeQuickActionSearch = YES; // Search will become active after the Home did appear
            }
        } else {
            [homeVC activateSearch];
        }
        
        
    } else if ([AppDelegate matchQuickAction:type with: @"upload"]) {
        [self handleQuickUploadAction];
    } else if ([AppDelegate matchQuickAction:type with: @"offline"]) {
        [self.mainTBC showOfflineAndPresentFileWithHandle:nil];
    } else {
        quickActionManaged = NO;
    }
    
    self.quickActionType = nil;
    
    return quickActionManaged;
}

- (void)showMainTabBar {
    if (![self.window.rootViewController isKindOfClass:[LTHPasscodeViewController class]]) {
        
        void (^mainOnAppear)(void) = ^() {
            if (![LTHPasscodeViewController doesPasscodeExist]) {
                if (self->isAccountFirstLogin) {
                    self->isAccountFirstLogin = NO;
                    if (self.isNewAccount && !self.isLoginRegisterAndOnboardingRevampFeatureEnabled) {
                        if (MEGAPurchase.sharedInstance.products.count > 0) {
                            [self showChooseAccountPlanTypeView];
                        } else {
                            [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray addObject:self];
                            self.chooseAccountTypeLater = YES;
                        }
                    }

                    self.newAccount = NO;

                    [MEGALinkManager processSelectedOptionOnLink];
                    [self showCookieDialogIfNeeded];

                    [self processGenericAppPushNotificationTapIfNeeded];
                } else {
                    [self processActionsAfterSetRootVC];
                }
            }
        };
        
        if (![self isAdsMainTabBarRootView]) {
            _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            
            UIViewController *mainController = [self adsMainTabBarController:_mainTBC
                                                         onViewFirstAppeared:mainOnAppear];
            [self.window setRootViewController:mainController];
            
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"]) {
                    [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO
                                                                             withLogout:YES
                                                                         andLogoutTitle:LocalizedString(@"logoutLabel", @"")];
                }
            }
        }
    }
    
    [self openTabBasedOnNotificationMegatype];
    
    if (self.presentInviteContactVCLater) {
        [self presentInviteContactCustomAlertViewController];
    }
    
    [self initializeCameraUploadsNode];
}

- (void)processActionsAfterSetRootVC {
    [self showLink:MEGALinkManager.linkURL];
    
    if (MEGALinkManager.nodeToPresentBase64Handle) {
        [MEGALinkManager presentNode];
    }
    
    [self manageQuickActionType:self.quickActionType];
    
    [self showCookieDialogIfNeeded];
    
    [self showEnableTwoFactorAuthenticationIfNeeded];
    
    [self showLaunchTabDialogIfNeeded];
    
    [self processGenericAppPushNotificationTapIfNeeded];
    
    [self showTemporaryTransferErrorDialogIfNeeded];
}

- (void)showTemporaryTransferErrorDialogIfNeeded {
    if (self.temporaryTransferErrorToDisplayLater && self.temporaryTransferTypeToDisplayLater) {
        [self handleTransferQuotaError:self.temporaryTransferErrorToDisplayLater
                              transfer:self.temporaryTransferTypeToDisplayLater];
        self.temporaryTransferErrorToDisplayLater = nil;
        self.temporaryTransferTypeToDisplayLater = nil;
    }
}

- (void)processGenericAppPushNotificationTapIfNeeded {
    if (self.megatype == MEGANotificationTypeGeneric && self.megaGenericRemoteNotif != nil) {
        [self handleGenericAppPushNotificationTapWithUserInfo:self.megaGenericRemoteNotif];
        self.megaGenericRemoteNotif = nil;
    }
}

- (void)showOnboardingWithCompletion:(void (^)(void))completion {
    if ([self isOnboardingViewControllerAlreadyShown]) {
        return;
    }
    
    UIViewController *onboardingVC = [self makeOnboardingViewController];
    UIView *overlayView = [UIScreen.mainScreen snapshotViewAfterScreenUpdates:NO];
    [onboardingVC.view addSubview:overlayView];
    self.window.rootViewController = onboardingVC;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        overlayView.alpha = 0;
    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
        [SVProgressHUD dismiss];
        
        if (completion) completion();
    }];
    
    [MEGAChatSdk.shared removeChatDelegate:self.mainTBC];
    self.mainTBC = nil;
}

- (void)openTabBasedOnNotificationMegatype {
    NSUInteger tabTag = 0;
    switch (self.megatype) {
        case MEGANotificationTypeShareFolder:
            tabTag = TabTypeSharedItems;
            break;
            
        case MEGANotificationTypeChatMessage:
            tabTag = TabTypeChat;
            break;
            
        case MEGANotificationTypeContactRequest:
            tabTag = TabTypeHome;
            break;
            
        default:
            return;
    }
    
    void (^manageNotificationBlock)(void) = ^{
        if ([UIApplication.mnz_visibleViewController isKindOfClass: [ChatViewController class]]) {
            MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:TabTypeChat];
            [navigationController popToRootViewControllerAnimated:NO];
        }
        
        self.mainTBC.selectedIndex = tabTag;
        if (self.megatype == MEGANotificationTypeContactRequest) {
            if ([UIApplication.mnz_visibleViewController isKindOfClass: [ContactRequestsViewController class]]) {
                return;
            }
            MEGANavigationController *navigationController = [[self.mainTBC viewControllers] objectAtIndex:tabTag];
            ContactRequestsViewController *contactRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
            [navigationController pushViewController:contactRequestsVC animated:NO];
        }
    };
    
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    if (rootViewController.presentedViewController) {
        [rootViewController dismissViewControllerAnimated:YES completion:^{
            manageNotificationBlock();
        }];
    } else {
        manageNotificationBlock();
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
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^(void) {
        MEGALogDebug(@"Copy databases for extensions");
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        if (error) {
            MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
        }
        
        NSString *groupSupportPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionGroupSupportFolder] path];
        if (![fileManager fileExistsAtPath:groupSupportPath]) {
            [fileManager createDirectoryAtPath:groupSupportPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        NSString *applicationSupportDirectoryString = applicationSupportDirectoryURL.path;
        NSArray *applicationSupportContent = [fileManager contentsOfDirectoryAtPath:applicationSupportDirectoryString error:&error];
        for (NSString *filename in applicationSupportContent) {
            if ([filename containsString:@"megaclient_statecache"] || [filename containsString:@"karere"]) {
                NSString *destinationPath = [groupSupportPath stringByAppendingPathComponent:filename];
                [NSFileManager.defaultManager mnz_removeItemAtPath:destinationPath];
                if ([fileManager copyItemAtPath:[applicationSupportDirectoryString stringByAppendingPathComponent:filename] toPath:destinationPath error:&error]) {
                    MEGALogDebug(@"Copy file %@", filename);
                } else {
                    MEGALogError(@"Copy item at path failed with error: %@", error);
                }
            }
        }
    });
}

- (void)presentInviteContactCustomAlertViewController {
    BOOL isInOutgoingContactRequest = NO;
    MEGAContactRequestList *outgoingContactRequestList = [MEGASdk.shared outgoingContactRequests];
    for (NSInteger i = 0; i < outgoingContactRequestList.size; i++) {
        MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
        if ([self.email isEqualToString:contactRequest.targetEmail]) {
            isInOutgoingContactRequest = YES;
            break;
        }
    }
    
    if (isInOutgoingContactRequest) {
        [[CustomModalAlertContactsRouter.alloc init:CustomModalAlertModeOutgoingContactRequest email:self.email presenter:UIApplication.mnz_presentingViewController] start];
    } else {
        [[CustomModalAlertContactsRouter.alloc init:CustomModalAlertModeContactNotInMEGA email:self.email presenter:UIApplication.mnz_presentingViewController] start];
    }
    
    self.presentInviteContactVCLater = NO;
}

- (void)application:(UIApplication *)application shouldHideWindows:(BOOL)shouldHide {
    NSSet<UIScene *> *connectedScenes = application.connectedScenes;

    for (UIScene *scene in connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            
            for (UIWindow *window in windowScene.windows) {
                if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] || [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"]) {
                    window.hidden = shouldHide;
                }
            }
        }
    }
}

- (void)handleTransferQuotaError:(MEGAError *)error transfer:(MEGATransfer *)transfer {
    switch (transfer.type) {
        case MEGATransferTypeDownload:
            [self handleDownloadQuotaError:error transfer:transfer];
            break;
        case MEGATransferTypeUpload:
            [self handleStorageQuotaError:error];
            break;
        default:
            break;
    }
}

- (void)handleStorageQuotaError:(MEGAError *)error {
    if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
        [SVProgressHUD dismiss];
        if (error.value == 0) {
            [[CustomModalAlertRouter.alloc init:CustomModalAlertModeStorageUploadQuotaError presenter:UIApplication.mnz_presentingViewController] start];
            [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
        }
    }
}

- (void)checkChatInitState {
    MEGAChatInit initState = [MEGAChatSdk.shared initState];
    MEGALogDebug(@"%@", [MEGAChatSdk stringForMEGAChatInitState:initState]);
    if (initState == MEGAChatInitOfflineSession || initState == MEGAChatInitOnlineSession) {
        [self importMessagesFromNSE];
    }
}

- (void)importMessagesFromNSE {
    NSURL *containerURL = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier];
    NSURL *nseCacheURL = [containerURL URLByAppendingPathComponent:MEGANotificationServiceExtensionCacheFolder isDirectory:YES];
    NSString *session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (session.length > MEGADropFirstCharactersFromSession) {
        NSString *sessionSubString = [session substringFromIndex:MEGADropFirstCharactersFromSession];
        NSString *filename = [NSString stringWithFormat:@"karere-%@.db", sessionSubString];
        NSURL *nseCacheFileURL = [nseCacheURL URLByAppendingPathComponent:filename];
        
        if ([NSFileManager.defaultManager fileExistsAtPath:nseCacheFileURL.path]) {
            if (MEGAStore.shareInstance.areTherePendingMessages) {
                MEGALogDebug(@"Import messages from %@", nseCacheFileURL.path);
                [MEGAChatSdk.shared importMessagesFromPath:nseCacheFileURL.path];
            } else {
                MEGALogDebug(@"No messages to import from NSE.");
            }
        } else {
            MEGALogWarning(@"NSE cache file %@ doesn't exist", nseCacheFileURL.path);
        }
    }
}

- (void)presentAccountExpiredAlertIfNeeded {
    if (!self.isAccountExpiredPresented && ![UIApplication.mnz_visibleViewController isKindOfClass:AccountExpiredViewController.class]) {
        NSString *alertTitle = [self expiredAccountTitle];
        NSString *alertMessage = [self expiredAccountMessage];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"dismiss", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.accountExpiredPresented = NO;
        }]];
        
        self.accountExpiredPresented = YES;
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)presentAccountExpiredViewIfNeeded {
    if ([UIApplication.mnz_visibleViewController isKindOfClass:InitialLaunchViewController.class] || [UIApplication.mnz_visibleViewController isKindOfClass:LaunchViewController.class]) {
        return;
    }
    
    if (MEGASdk.shared.businessStatus == BusinessStatusGracePeriod) {
        if (MEGASdk.shared.isMasterBusinessAccount) {
            [[CustomModalAlertRouter.alloc init:CustomModalAlertModeBusinessGracePeriod presenter:UIApplication.mnz_presentingViewController] start];
        }
    }
    
    if (MEGASdk.shared.businessStatus == BusinessStatusExpired &&
        ![UIApplication.mnz_visibleViewController isKindOfClass:AccountExpiredViewController.class]) {
        AccountExpiredViewController *accountStatusVC = AccountExpiredViewController.alloc.init;
        accountStatusVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [UIApplication.mnz_presentingViewController presentViewController:accountStatusVC animated:YES completion:nil];
    }
}

- (void)presentLogoutFromOtherClientAlert {
    self.API_ESIDAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"loggedOut_alertTitle", @"") message:LocalizedString(@"loggedOutFromAnotherLocation", @"") preferredStyle:UIAlertControllerStyleAlert];
    [self.API_ESIDAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:self.API_ESIDAlertController animated:YES completion:nil];
}

- (void)indexFavourites {
    self.spotlightIndexer = [[SpotlightIndexer alloc] initWithSdk:MEGASdk.shared passcodeEnabled:LTHPasscodeViewController.doesPasscodeExist];
    [self.spotlightIndexer indexFavouritesWithCompletionHandler:^{ }];
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    if (![MEGAReachabilityManager isReachable] || [self.window.rootViewController isKindOfClass:[LTHPasscodeViewController class]]) {
        _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        UIViewController *mainController = [self adsMainTabBarController:_mainTBC
                                                     onViewFirstAppeared:nil];
        [self.window setRootViewController:mainController];
    } else {
        [self showLink:MEGALinkManager.linkURL];

        [self processActionsAfterSetRootVC];
    }
}

- (void)maxNumberOfFailedAttemptsReached {
    [MEGASdk.shared logout];
}

- (void)logoutButtonWasPressed {
    [MEGASdk.shared logout];
}

- (void)passcodeWasEnabled {
    [self.spotlightIndexer deindexAllSearchableItemsWithCompletionHandler:^{ }];
}

- (void)passcodeViewControllerWillClose {
    [NSNotificationCenter.defaultCenter postNotificationName:MEGAPasscodeViewControllerWillCloseNotification object:nil];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"userNotificationCenter didReceiveNotificationResponse %@", response);
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[response.notification.request.identifier]];
    self.megatype = (MEGANotificationType)[response.notification.request.content.userInfo[@"megatype"] integerValue];
    
    if ([self isScheduleMeetingNotification:response.notification]) {
        NSString *chatIdBase64 = response.notification.request.content.userInfo[@"chatId"];
        uint64_t chatId = [MEGASdk handleForBase64UserHandle:chatIdBase64];
        
        if ([self hasTappedOnJoinActionWithResponse:response]) {
            [self joinScheduleMeetingForChatId:chatId];
        } else {
            [self openScheduleMeetingForChatId:chatId retry:YES];
        }
        
    } else if (self.megatype) {
        if (self.megatype == MEGANotificationTypeGeneric) {
            if ([self isAdsMainTabBarRootView] && !LTHPasscodeViewController.sharedUser.isLockscreenPresent) {
                [self handleGenericAppPushNotificationTapWithUserInfo:response.notification.request.content.userInfo];
            } else {
                self.megaGenericRemoteNotif = response.notification.request.content.userInfo;
            }
        } else {
            [self openTabBasedOnNotificationMegatype];
        }
    } else {
        if (self.mainTBC) {
            [self.mainTBC openChatRoomNumber:response.notification.request.content.userInfo[@"chatId"]];
        } else {
            self.openChatLater = response.notification.request.content.userInfo[@"chatId"];
        }
    }
    
    completionHandler();
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    MEGALogDebug(@"[Notification] will present notification %@", notification);
    
    if ([self isScheduleMeetingNotification:notification]) {
        completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner);
        return;
    }
    
    uint64_t chatId = [notification.request.content.userInfo[@"chatId"] unsignedLongLongValue];
    uint64_t msgId =  [notification.request.content.userInfo[@"msgId"] unsignedLongLongValue];
    MEGALogDebug(@"[Notification] chatId: %@ messageId: %@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:msgId]);
    if ([notification.request.trigger isKindOfClass:UNPushNotificationTrigger.class]) {
        MOMessage *moMessage = [MEGAStore.shareInstance fetchMessageWithChatId:chatId messageId:msgId];
        if (moMessage) {
            [MEGAStore.shareInstance deleteMessage:moMessage];
            completionHandler(UNNotificationPresentationOptionNone);
        } else {
            completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner);
        }
    } else {
        completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner);
    }    
}

#pragma mark - LaunchViewControllerDelegate

- (void)setupFinished {
    if (MEGASdk.shared.businessStatus == BusinessStatusGracePeriod &&             [UIApplication.mnz_presentingViewController isKindOfClass:CustomModalAlertViewController.class]) {
        return;
    }
    [self showMainTabBar];
    [[MEGAPurchase sharedInstance] processAnyPendingPromotedPlanPayment];
}

- (void)readyToShowRecommendations {
    [self presentAccountExpiredViewIfNeeded];
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    if (self.loadProductsAndShowAccountUpgradeScreen) {
        self.loadProductsAndShowAccountUpgradeScreen = NO;
        [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray removeObject:self];
        [self showUpgradeAccount];
    } else if (self.showChooseAccountTypeLater) {
        [self showChooseAccountPlanTypeView];

        self.chooseAccountTypeLater = NO;
        [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray removeObject:self];
    }

}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)sdk userList:(MEGAUserList *)userList {
    NSInteger userListCount = userList.size;
    for (NSInteger i = 0 ; i < userListCount; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        
        if (user.changes) {
            if ([user hasChangedType:MEGAUserChangeTypeEmail]) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:user.handle];
                if (moUser) {
                    [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle email:user.email];
                } else {
                    [MEGAStore.shareInstance insertUserWithUserHandle:user.handle firstname:nil lastname:nil nickname:nil email:user.email];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MEGAEmailHasChangedNotification object:nil userInfo:@{@"user" : user}];
            }
            
            if (user.isOwnChange == 0) { //If the change is external
                if (user.handle == MEGASdk.currentUserHandle.unsignedLongLongValue) {
                    [user resetAvatarIfNeededInSdk:sdk];
                    
                    if ([user hasChangedType:MEGAUserChangeTypeFirstname]) {
                        [sdk getUserAttributeType:MEGAUserAttributeFirstname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeLastname]) {
                        [sdk getUserAttributeType:MEGAUserAttributeLastname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeUserAlias]) {
                        [self updateContactsNickname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeRichPreviews]) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"richLinks"];
                        MEGAGetAttrUserRequestDelegate *delegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                            [NSUserDefaults.standardUserDefaults setBool:request.flag forKey:@"richLinks"];
                        }];
                        [sdk isRichPreviewsEnabledWithDelegate:delegate];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeCameraUploadsFolder]) {
                        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadTargetFolderChangedInRemoteNotification object:nil];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeBackupFolder]) {
                        [NSNotificationCenter.defaultCenter postNotificationName:MEGABackupRootFolderUpdatedInRemoteNotification object:nil];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeMyChatFilesFolder]) {
                        [NSNotificationCenter.defaultCenter postNotificationName:MEGAMyChatFilesFolderUpdatedInRemoteNotification object:nil];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeCookieSetting]) {
                        [self configAppWithNewCookieSettings];
                    }
                } else {
                    [user resetAvatarIfNeededInSdk:sdk];
                    
                    if ([user hasChangedType:MEGAUserChangeTypeFirstname]) {
                        [sdk getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
                    }
                    if ([user hasChangedType:MEGAUserChangeTypeLastname]) {
                        [sdk getUserAttributeForUser:user type:MEGAUserAttributeLastname];
                    }
                }
            }
            
        } else if (user.visibility == MEGAUserVisibilityVisible) {
            [sdk getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
            [sdk getUserAttributeForUser:user type:MEGAUserAttributeLastname];
        }
        
        if (user.visibility == MEGAUserVisibilityHidden) {
            [MEGAStore.shareInstance updateUserWithHandle:user.handle interactedWith:NO];
        }
    }
}

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (nodeList) {
        [self.quickAccessWidgetManager updateWidgetContentWith:nodeList];
        [self postNodeUpdatesNotificationsFor:nodeList];
        [self removeCachedFilesIfNeededFor:nodeList];
    } else {
        [Helper startPendingUploadTransferIfNeeded];
    }
}

- (void)onAccountUpdate:(MEGASdk *)api {
    [api getAccountDetails];
}

- (void)onEvent:(MEGASdk *)api event:(MEGAEvent *)event {
    MEGALogDebug(@"on event type %lu, number %lu", event.type, event.number);
    switch (event.type) {
        case EventChangeToHttps:
            [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] setBool:YES forKey:@"useHttpsOnly"];
            break;
            
        case EventAccountBlocked:
            [self handleAccountBlockedEvent:event];
            break;
            
        case EventNodesCurrent:
            [NSNotificationCenter.defaultCenter postNotificationName:MEGANodesCurrentNotification object:self];
            [self indexFavourites];
            break;
            
        case EventMediaInfoReady:
            [NSNotificationCenter.defaultCenter postNotificationName:MEGAMediaInfoReadyNotification object:self];
            break;
            
        case EventStorage: {
            [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageEventDidChangeNotification object:self userInfo:@{MEGAStorageEventStateUserInfoKey : @(event.number)}];
            
            if (event.number == StorageStateChange) {
                [api getAccountDetails];
            } else if (event.number == StorageStatePaywall) {
                [self presentOverDiskQuota];
            } else {
                if (event.number == StorageStateRed || event.number == StorageStateOrange) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[CustomModalAlertStorageRouter.alloc init:CustomModalAlertModeStorageEvent event:event presenter:UIApplication.mnz_presentingViewController] start];
                    });
                }
            }
            break;
        }
            
        case EventBusinessStatus:
            if (event.number == BusinessStatusActive) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGABusinessAccountActivatedNotification object:self];
            } else if (event.number == BusinessStatusExpired) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGABusinessAccountExpiredNotification object:self];
            }
            
            [self presentAccountExpiredViewIfNeeded];
            break;
            
        case EventStorageSumChanged:
            [MEGASdk.shared mnz_setShouldRequestAccountDetails:YES];
            [self postSetShouldRequestAccountDetailsNotification:YES];
            break;
            
        case EventReloading: {
            isFetchNodesDone = NO;
            [self showLaunchViewController];
            break;
        }
        
        case EventUpgradeSecurity:
            [self showUpgradeSecurityAlert];
            break;
            
        case EventAccountConfirmation:
            self.newAccount = YES;
            break;
            
        case EventFatalError:
            [self handleFatalErrorWithEvent:event];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
            
        case MEGARequestTypeLogout: {
            if (MEGALinkManager.urlType == URLTypeCancelAccountLink || MEGASdk.isGuest) {
                return;
            }
            
            if (request.paramType != MEGAErrorTypeApiESSL && request.flag) {
                [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudLogOut"] status:LocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs: {
                if ([request type] == MEGARequestTypeLogin) {
                    [Helper logout];
                    [self showOnboardingWithCompletion:nil];
                }
                break;
            }
                
            case MEGAErrorTypeApiESid: {                                
                if (MEGALinkManager.urlType == URLTypeCancelAccountLink) {
                    [Helper logout];
                    
                    [self showOnboardingWithCompletion:^{
                        if (MEGALinkManager.urlType == URLTypeCancelAccountLink) {
                            UIAlertController *accountCanceledSuccessfullyAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"accountCanceledSuccessfully", @"During account cancellation (deletion)") message:nil preferredStyle:UIAlertControllerStyleAlert];
                            [accountCanceledSuccessfullyAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleCancel handler:nil]];
                            [UIApplication.mnz_presentingViewController presentViewController:accountCanceledSuccessfullyAlertController animated:YES completion:^{
                                [MEGALinkManager resetLinkAndURLType];
                            }];
                        }
                    }];
                    return;
                }
                
                if ([request type] == MEGARequestTypeLogin || [request type] == MEGARequestTypeLogout) {
                    if (!self.API_ESIDAlertController || UIApplication.mnz_presentingViewController.presentedViewController != self.API_ESIDAlertController) {
                        [Helper logout];
                        [self showOnboardingWithCompletion:nil];
                        [self presentLogoutFromOtherClientAlert];
                    }
                }
                break;
            }
                
            case MEGAErrorTypeApiEgoingOverquota:
            case MEGAErrorTypeApiEOverQuota: {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
                
                if ([api isForeignNode:request.parentHandle]) {
                    if (![UIApplication.mnz_presentingViewController isKindOfClass:UIAlertController.class]) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:LocalizedString(@"dialog.shareOwnerStorageQuota.message", @"") preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:nil]];
                        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
                    }
                } else {
                    [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
                    [[CustomModalAlertRouter.alloc init:CustomModalAlertModeStorageQuotaError presenter:UIApplication.mnz_presentingViewController] start];
                }
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
                if (request.type == MEGARequestTypeLogout && request.paramType == MEGAErrorTypeApiESSL && !self.sslKeyPinningController) {
                    [SVProgressHUD dismiss];
                    _sslKeyPinningController = [UIAlertController alertControllerWithTitle:LocalizedString(@"sslUnverified_alertTitle", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ignore", @"Button title to allow the user ignore something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        [api setPublicKeyPinning:NO];
                        [api reconnect];
                    }]];
                    
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"retry", @"Button which allows to retry send message in chat conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        [api retryPendingConnections];
                    }]];
                    
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"openBrowser", @"Button title to allow the user open the default browser") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        NSURL *url = [NSURL URLWithString:@"https://mega.nz"];
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
                    }]];
                    
                    [UIApplication.mnz_presentingViewController presentViewController:self.sslKeyPinningController animated:YES completion:nil];
                }
                break;
            }
                
            case MEGAErrorTypeApiEBusinessPastDue:
                [self presentAccountExpiredAlertIfNeeded];
                break;
            case MEGAErrorTypeApiEPaywall: {
                [self presentOverDiskQuota];
                break;
            }
            default:
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCreateAccount: {
            [self initProviderDelegate];
        }
            
        case MEGARequestTypeFetchNodes: {
            [self postDidFinishFetchNodesNotification];
            [self listenToStorePaymentTransactions];
            [[SKPaymentQueue defaultQueue] addTransactionObserver:[MEGAPurchase sharedInstance]];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [MEGASdk.shared pauseTransfers:YES];
                [MEGASdk.sharedFolderLink pauseTransfers:YES];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"TransfersPaused"];
            }
            isFetchNodesDone = YES;
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            
            [self updateContactsNickname];
            
            MEGAChatNotificationDelegate *chatNotificationDelegate = MEGAChatNotificationDelegate.new;
            [MEGAChatSdk.shared addChatNotificationDelegate:chatNotificationDelegate];
            
            if (MEGASdk.isGuest) {
                return;
            }
            
            BOOL _isAccountFirstLogin = isAccountFirstLogin;
            
            __weak typeof(self) weakSelf = self;
            
            if (!_isAccountFirstLogin) {
                [weakSelf showMainTabBar];
                if (weakSelf.openChatLater) {
                    [weakSelf.mainTBC openChatRoomNumber:weakSelf.openChatLater];
                }
            }
            
            [MEGASdk.shared getAccountDetails];
            [weakSelf refreshAccountDetails];
            
            [weakSelf.quickAccessWidgetManager startWidgetManagerWithCompletionHandler:^{
                [weakSelf.quickAccessWidgetManager reloadWidgetItemData];
            }];
            
            [weakSelf presentAccountExpiredViewIfNeeded];
            
            [weakSelf configAppWithNewCookieSettings];
            break;
        }
            
        case MEGARequestTypeLogout: {
            // if logout (not if localLogout) or session killed in other client
            BOOL sessionInvalidateInOtherClient = request.paramType == MEGAErrorTypeApiESid;
            [MEGAPurchase.sharedInstance removeAllProducts];
            [self.quickAccessWidgetManager stopWidgetManager];
            if (request.flag || sessionInvalidateInOtherClient) {
                [Helper logout];
                [self showOnboardingWithCompletion:nil];
                
                [MEGASdk.shared mnz_setAccountDetails:nil];
                
                [QuickAccessWidgetManager reloadAllWidgetsContent];
                if (sessionInvalidateInOtherClient && !self.API_ESIDAlertController) {
                    [self presentLogoutFromOtherClientAlert];
                }
                
                [api setAccountAuth:nil];
            }
            [[MEGASdk.shared completedTransfers] removeAllObjects];
            break;
        }
            
        case MEGARequestTypeAccountDetails:
            [MEGASdk.shared mnz_setShouldRequestAccountDetails:NO];
            [MEGASdk.shared mnz_setAccountDetails:[request megaAccountDetails]];
            
            [self postDidFinishFetchAccountDetailsNotificationWithAccountDetails:[request megaAccountDetails]];
            [self postSetShouldRequestAccountDetailsNotification:NO];
            
            NSInteger storageUsed = MEGASdk.shared.mnz_accountDetails.storageUsed;
            [OverDiskQuotaService.sharedService updateUserStorageUsed:storageUsed];

            if (self.showAccountUpgradeScreen && [MEGASdk.shared mnz_accountDetails]) {
                self.showAccountUpgradeScreen = NO;
                [self showUpgradeAccount];
            }

            break;
            
        case MEGARequestTypeGetAttrUser: {
            [self updateUserAttributesWithRequest:request];
            break;
        }
            
        case MEGARequestTypeSetAttrUser: {
            uint64_t handle = MEGASdk.currentUserHandle.unsignedLongLongValue;
            if (handle) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:handle];
                if (moUser) {
                    if (request.paramType == MEGAUserAttributeFirstname && ![request.text isEqualToString:moUser.firstname]) {
                        [[MEGAStore shareInstance] updateUserWithUserHandle:handle firstname:request.text];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname && ![request.text isEqualToString:moUser.lastname]) {
                        [[MEGAStore shareInstance] updateUserWithUserHandle:handle lastname:request.text];
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
                [MEGAStore.shareInstance insertUserWithUserHandle:request.nodeHandle firstname:nil lastname:nil nickname:nil email:request.email];
            }
            break;
        }
            
        case MEGARequestTypeShare: {
            if (request.access != MEGANodeAccessLevelAccessUnknown) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAShareCreatedNotification object:nil];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    if (request.type == MEGAChatRequestTypeSetBackgroundStatus && request.flag) {
        [self endBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    }
    if ([error type] != MEGAChatErrorTypeOk) {
        MEGALogError(@"onChatRequestFinish error type: %td request type: %td", error.type, request.type);
        return;
    }
    
    if (request.type == MEGAChatRequestTypeLogout) {
        [self.mainTBC setBadgeValueForChats];
    }
    
    if (request.type == MEGAChatRequestTypeImportMessages) {
        MEGALogDebug(@"Imported messages %lld", request.number);
        NSManagedObjectContext *childQueueContext = [MEGAStore.shareInstance.stack newBackgroundContext];
        if (childQueueContext) {
            [childQueueContext performBlock:^{
                [MEGAStore.shareInstance deleteAllMessagesWithContext:childQueueContext];
            }];
        }
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState {
    self.chatLastKnownInitState = newState;
    if (newState == MEGAChatInitError) {
        [MEGAChatSdk.shared logout];
    }
    if (newState == MEGAChatInitOnlineSession) {
        [self copyDatabasesForExtensions];
    }
}

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    if (item.changes == 0 && self.chatLastKnownInitState == MEGAChatInitOnlineSession) {
        MEGALogDebug(@"New chat room %@", [MEGASdk base64HandleForUserHandle:item.chatId]);
        [self copyDatabasesForExtensions];
        MEGALogDebug(@"Invalidate NSE cache");
        NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
        [sharedUserDefaults setBool:YES forKey:MEGAInvalidateNSECache];
    }
}

- (void)onDbError:(MEGAChatSdk *)api error:(MEGAChatDBError)error message:(NSString *)message {
    [self handleChatDBErrorWithError:error message:message];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.state == MEGATransferStatePaused) {
        [Helper startPendingUploadTransferIfNeeded];
    }
}

- (void)onTransferTemporaryError:(MEGASdk *)sdk transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    MEGALogDebug(@"onTransferTemporaryError %td", error.type)
    if (!transfer.isForeignOverquota) {
        if (![LTHPasscodeViewController doesPasscodeExist] &&
            ![[LTHPasscodeViewController sharedUser] isLockscreenPresent]) {
            [self handleTransferQuotaError:error transfer:transfer];
        } else {
            // These are stored to be used when showing the dialog after successul passcode entry
            self.temporaryTransferTypeToDisplayLater = transfer;
            self.temporaryTransferErrorToDisplayLater = error;
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)sdk transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.type != MEGATransferTypeUpload && transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeUpload) {
        
        if ([transfer.appData containsString:@"attachToChatID"] || [transfer.appData containsString:@"attachVoiceClipToChatID"]) {
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogInfo(@"Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
        }
                
        if ([transfer.appData containsString:@">localIdentifier"]) {
            NSString *localIdentifier = [transfer.appData mnz_stringBetweenString:@">localIdentifier=" andString:@">"];
            [[Helper uploadingNodes] removeObject:localIdentifier];
        }
        
        if ([transfer.appData containsString:@">setCoordinates="]) {
            NSString *coordinates = [transfer.appData mnz_stringBetweenString:@">setCoordinates=" andString:@">"];
            [transfer mnz_setCoordinates:coordinates];
        }
        
        [Helper startPendingUploadTransferIfNeeded];
    }
    
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEgoingOverquota:
            case MEGAErrorTypeApiEOverQuota:
                if (!transfer.isForeignOverquota) {
                    [self handleTransferQuotaError:error transfer:transfer];
                }
                break;
            case MEGAErrorTypeApiEBusinessPastDue:
                [self presentAccountExpiredAlertIfNeeded];
                break;
            default: {
                if (error.type != MEGAErrorTypeApiESid && error.type != MEGAErrorTypeApiESSL && error.type != MEGAErrorTypeApiEExist && error.type != MEGAErrorTypeApiEIncomplete) {
                    NSString *transferFailed = LocalizedString(@"Transfer failed:", @"Notification message shown when a transfer failed. Keep colon.");
                    NSString *errorString = [MEGAError errorStringWithErrorCode:error.type context:(transfer.type == MEGATransferTypeUpload) ? MEGAErrorContextUpload : MEGAErrorContextDownload];
                    MEGALogError(@"%@\n%@ %@", transfer.fileName, transferFailed, LocalizedString(errorString, @""));
                }
                break;
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        [[[SaveNodeUseCaseOCWrapper alloc] initWithSaveMediaToPhotoFailureHandler:self] saveNodeIfNeededFrom:transfer];
        
        [QuickAccessWidgetManager reloadWidgetContentOfKindWithKind:MEGAOfflineQuickAccessWidget];
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:MEGATransferFinishedNotification object:nil userInfo:@{MEGATransferUserInfoKey : transfer}];
}

@end
