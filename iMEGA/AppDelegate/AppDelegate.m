#import "AppDelegate.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import <Intents/Intents.h>
#import <Photos/Photos.h>
#import <PushKit/PushKit.h>
#import <QuickLook/QuickLook.h>
#import <UserNotifications/UserNotifications.h>

#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "DevicePermissionsHelper.h"
#import "MEGAApplication.h"
#import "MEGALinkManager.h"
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
#import "AchievementsViewController.h"
#import "CheckEmailAndFollowTheLinkViewController.h"
#import "CloudDriveViewController.h"
#import "ContactsViewController.h"
#import "ContactRequestsViewController.h"
#import "LaunchViewController.h"
#import "MainTabBarController.h"
#import "OnboardingViewController.h"

#import "MEGAChatNotificationDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAProviderDelegate.h"
#import "MEGAShowPasswordReminderRequestDelegate.h"
#import "CameraUploadManager+Settings.h"
#import "TransferSessionManager.h"
#import <SDWebImage/SDWebImage.h>
#import "MEGASdkManager+CleanUp.h"
@import Firebase;
@import SDWebImageWebPCoder;

#import "MEGA-Swift.h"

@interface AppDelegate () <PKPushRegistryDelegate, UIApplicationDelegate, UNUserNotificationCenterDelegate, LTHPasscodeViewControllerDelegate, LaunchViewControllerDelegate, MEGAApplicationDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, MEGAGlobalDelegate, MEGAPurchasePricingDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
}

@property (nonatomic, strong) UIView *privacyView;

@property (nonatomic, strong) NSString *quickActionType;

@property (nonatomic, strong) UIAlertController *API_ESIDAlertController;

@property (nonatomic, weak) MainTabBarController *mainTBC;

@property (nonatomic) MEGANotificationType megatype; //1 share folder, 2 new message, 3 contact request

@property (strong, nonatomic) MEGAChatRoom *chatRoom;
@property (nonatomic, getter=isVideoCall) BOOL videoCall;

@property (strong, nonatomic) NSString *email;
@property (nonatomic) BOOL presentInviteContactVCLater;

@property (nonatomic, getter=isNewAccount) BOOL newAccount;
@property (nonatomic, getter=showChooseAccountTypeLater) BOOL chooseAccountTypeLater;

@property (nonatomic, strong) UIAlertController *sslKeyPinningController;

@property (nonatomic) NSMutableDictionary *backgroundTaskMutableDictionary;

@property (nonatomic, getter=isAccountExpiredPresented) BOOL accountExpiredPresented;
@property (nonatomic, getter=isOverDiskQuotaPresented) BOOL overDiskQuotaPresented;

@property (nonatomic, strong) MEGAProviderDelegate *megaProviderDelegate;

@property (nonatomic) MEGAChatInit chatLastKnownInitState;

@property (nonatomic) NSNumber *openChatLater;

@property (nonatomic, strong) QuickAccessWidgetManager *quickAccessWidgetManager API_AVAILABLE(ios(14.0));

@property (nonatomic, strong) RatingRequestMonitor *ratingRequestMonitor;
@property (nonatomic, strong) SpotlightIndexer *spotlightIndexer;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelFatal];
#endif
    
    [UncaughtExceptionHandler registerHandler];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSQLiteDiskFullNotification) name:MEGASQLiteDiskFullNotification object:nil];
    
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    
    NSError *error;
    [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3" error:&error];
    if (error.code == errSecInteractionNotAllowed) {
        exit(0);
    }
    
    [MEGASdk setLogToConsole:YES];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
        [MEGASdk setLogLevel:MEGALogLevelMax];
        [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
        [MEGASdkManager.sharedMEGASdk addLoggerDelegate:Logger.shared];
        [MEGAChatSdk setLogObject:Logger.shared];
    }

    MEGALogDebug(@"[App Lifecycle] Application will finish launching with options: %@", launchOptions);
    
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FIRApp configure];
    [self migrateLocalCachesLocation];
    [self registerCameraUploadBackgroundRefresh];

    if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        _megatype = (MEGANotificationType)[[[launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"] objectForKey:@"megatype"] integerValue];
    }
    
    SDImageWebPCoder *webPCoder = [SDImageWebPCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:webPCoder];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    [MEGAReachabilityManager sharedManager];
    
    [CameraUploadManager.shared setupCameraUploadWhenApplicationLaunches];
    
    [Helper restoreAPISetting];
    [ChatUploader.sharedInstance setup];
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatRequestDelegate:self];
        
    [[MEGASdkManager sharedMEGASdk] httpServerSetMaxBufferSize:[UIDevice currentDevice].maxBufferSize];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"presentPasscodeLater"];
    
    NSString *languageCode = NSBundle.mainBundle.preferredLocalizations.firstObject;
    [MEGASdkManager.sharedMEGASdk setLanguageCode:languageCode];
    [MEGASdkManager.sharedMEGASdkFolder setLanguageCode:languageCode];
    
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
                
        MEGAChatInit chatInit = [MEGASdkManager.sharedMEGAChatSdk initKarereWithSid:sessionV3];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
            [MEGASdkManager.sharedMEGASdk removeLoggerDelegate:Logger.shared];
        }
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere with session failed");
            NSString *message = [NSString stringWithFormat:@"Error (%ld) initializing the chat", (long)chatInit];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            [[MEGASdkManager sharedMEGAChatSdk] logout];
            [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        } else if (chatInit == MEGAChatInitOnlineSession || chatInit == MEGAChatInitOfflineSession) {
            [self importMessagesFromNSE];
        }
        
        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        [MEGASdkManager.sharedMEGASdk fastLoginWithSession:sessionV3 delegate:loginRequestDelegate];
        
        if ([MEGAReachabilityManager isReachable]) {
            [self showLaunchViewController];
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO
                                                                         withLogout:YES
                                                                     andLogoutTitle:NSLocalizedString(@"logoutLabel", nil)];
                [self.window setRootViewController:[LTHPasscodeViewController sharedUser]];
            } else {
                _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                [self.window setRootViewController:_mainTBC];
            }
        }
        
        if ([sharedUserDefaults boolForKey:@"useHttpsOnly"]) {
            [[MEGASdkManager sharedMEGASdk] useHttpsOnly:YES];
        }
        
        [CameraUploadManager enableAdvancedSettingsForUpgradingUserIfNeeded];
    } else {
        // Resume ephemeral account
        self.window.rootViewController = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault];
        NSString *sessionId = [SAMKeychain passwordForService:@"MEGA" account:@"sessionId"];
        if (sessionId && ![[[launchOptions objectForKey:@"UIApplicationLaunchOptionsURLKey"] absoluteString] containsString:@"confirm"]) {
            MEGACreateAccountRequestDelegate *createAccountRequestDelegate = [[MEGACreateAccountRequestDelegate alloc] initWithCompletion:^ (MEGAError *error) {
                CheckEmailAndFollowTheLinkViewController *checkEmailAndFollowTheLinkVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CheckEmailAndFollowTheLinkViewControllerID"];
                checkEmailAndFollowTheLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [UIApplication.mnz_presentingViewController presentViewController:checkEmailAndFollowTheLinkVC animated:YES completion:nil];
            }];
            createAccountRequestDelegate.resumeCreateAccount = YES;
            [[MEGASdkManager sharedMEGASdk] resumeCreateAccountWithSessionId:sessionId delegate:createAccountRequestDelegate];
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
    
    [MEGASdkManager.sharedMEGASdk isLoggedInWithCompletion:^(BOOL isLoggedIn) {
        if (isLoggedIn) {
            [self beginBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
        }
    }];
    
    [MEGASdkManager.sharedMEGASdk areTherePendingTransfersWithCompletion:^(BOOL pendingTransfers) {
        if (pendingTransfers) {
            [self beginBackgroundTaskWithName:@"PendingTasks"];
        }
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did enter background");
    
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:YES];
    [[MEGASdkManager sharedMEGAChatSdk] saveCurrentState];

    [LTHPasscodeViewController.sharedUser setDelegate:self];
    
    if (self.privacyView == nil) {
        UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
        privacyVC.view.backgroundColor = UIColor.mnz_background;
        self.privacyView = privacyVC.view;
    }
    [self.window addSubview:self.privacyView];
    
    [self application:application shouldHideWindows:YES];
    
    if (UIApplication.sharedApplication.windows.count > 0 && ![NSStringFromClass(UIApplication.sharedApplication.windows.firstObject.class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will enter foreground");
    [self checkChatInitState];
    [MEGAReachabilityManager.sharedManager retryOrReconnect];
    
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:NO];
    
    [MEGASdkManager.sharedMEGASdk isLoggedInWithCompletion:^(BOOL isLoggedIn) {
        if (isLoggedIn && self->isFetchNodesDone) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MEGAShowPasswordReminderRequestDelegate *showPasswordReminderDelegate = [[MEGAShowPasswordReminderRequestDelegate alloc] initToLogout:NO];
                [[MEGASdkManager sharedMEGASdk] shouldShowPasswordReminderDialogAtLogout:NO delegate:showPasswordReminderDelegate];
            });
        }
    }];
    
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
    
    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    [sharedUserDefaults setInteger:0 forKey:MEGAApplicationIconBadgeNumber];    
    application.applicationIconBadgeNumber = 0;
    
    if (MEGASdkManager.sharedMEGAChatSdk.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
    
    if (![NSStringFromClass([UIApplication sharedApplication].windows.firstObject.class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] enablePasscodeWhenApplicationEntersBackground];
    }
    
    [self endBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    [self endBackgroundTaskWithName:@"PendingTasks"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will terminate");
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[MEGAPurchase sharedInstance]];
    
    [MEGASdkManager localLogoutAndCleanUp];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    MEGALogDebug(@"[App Lifecycle] Application open URL %@", url);
    
    MEGALinkManager.linkURL = url;
    [self manageLink:url];
    
    return YES;
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

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    MEGALogDebug(@"[App Lifecycle] Application continue user activity %@", userActivity.activityType);
    
    if ([MEGAReachabilityManager isReachable]) {
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            MEGALinkManager.nodeToPresentBase64Handle = userActivity.userInfo[@"kCSSearchableItemActivityIdentifier"];
            if ([self.window.rootViewController isKindOfClass:[MainTabBarController class]] && ![LTHPasscodeViewController doesPasscodeExist]) {
                [MEGALinkManager presentNode];
            }
        } else if ([userActivity.activityType isEqualToString:@"INStartAudioCallIntent"] || [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
            INInteraction *interaction = userActivity.interaction;
            INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
            INPerson *contact = startAudioCallIntent.contacts.firstObject;
            INPersonHandle *personHandle = contact.personHandle;
            
            if (personHandle.type == INPersonHandleTypeEmailAddress) {
                self.email = personHandle.value;
                self.videoCall = [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"];
                MEGALogDebug(@"Email %@", self.email);
                uint64_t userHandle = [[MEGASdkManager sharedMEGAChatSdk] userHandleByEmail:self.email];
                
                if (userHandle == MEGAInvalidHandle) {
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
                            BOOL isSpeakerEnabled = [AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInSpeaker];
                            [self performCallWithPresenter:UIApplication.mnz_presentingViewController
                                                  chatRoom:self.chatRoom
                                          isSpeakerEnabled:isSpeakerEnabled];
                            self.chatRoom = nil;
                        } else {
                            MEGAChatConnection chatConnection = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:self.chatRoom.chatId];
                            MEGALogDebug(@"Chat %@ connection state: %ld", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], (long)chatConnection);
                            if (chatConnection == MEGAChatConnectionOnline) {
                                [DevicePermissionsHelper audioPermissionModal:YES forIncomingCall:YES withCompletionHandler:^(BOOL granted) {
                                    if (granted) {
                                        if (self.videoCall) {
                                            [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                                                if (granted) {
                                                    [self performCall];
                                                } else {
                                                    [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:nil];
                                                }
                                            }];
                                        } else {
                                            [self performCall];
                                        }
                                    } else {
                                        [DevicePermissionsHelper alertAudioPermissionForIncomingCall:YES];
                                    }
                                }];
                            }
                        }
                    } else {
                        MEGALogDebug(@"There is not a chat with %@, create the chat and inmediatelly perform the call", self.email);
                        [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUserHandle:userHandle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                            self.chatRoom = chatRoom;
                            MEGAChatConnection chatConnection = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:self.chatRoom.chatId];
                            MEGALogDebug(@"Chat %@ connection state: %ld", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], (long)chatConnection);
                            if (chatConnection == MEGAChatConnectionOnline) {
                                [self performCall];
                            }
                        }];
                    }
                }
            } if (personHandle.type == INPersonHandleTypeUnknown) {
                uint64_t handle = [MEGASdk handleForBase64UserHandle:personHandle.value];
                MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:handle];
                self.videoCall = [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"];

                if (call && call.status == MEGAChatCallStatusInProgress) {
                    self.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:call.chatId];
                    MEGALogDebug(@"call id %llu", call.callId);
                    MEGALogDebug(@"There is a call in progress for this chat %@", call);
                    BOOL isSpeakerEnabled = [AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInSpeaker];
                    [self performCallWithPresenter:UIApplication.mnz_presentingViewController chatRoom:self.chatRoom isSpeakerEnabled:isSpeakerEnabled];
                    self.chatRoom = nil;
                } else {
                    self.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:handle];
                    MEGAChatConnection chatConnection = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:self.chatRoom.chatId];
                    MEGALogDebug(@"Chat %@ connection state: %ld", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], (long)chatConnection);
                    if (chatConnection == MEGAChatConnectionOnline) {
                        [DevicePermissionsHelper audioPermissionModal:YES forIncomingCall:YES withCompletionHandler:^(BOOL granted) {
                            if (granted) {
                                if (self.videoCall) {
                                    [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                                        if (granted) {
                                            [self performCall];
                                        } else {
                                            [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:nil];
                                        }
                                    }];
                                } else {
                                    [self performCall];
                                }
                            } else {
                                [DevicePermissionsHelper alertAudioPermissionForIncomingCall:YES];
                            }
                        }];
                    }
                }
            }
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
    
    if (isFetchNodesDone) {
        completionHandler([self manageQuickActionType:shortcutItem.type]);
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    MEGALogWarning(@"[App Lifecycle] Application did receive memory warning");
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"[App Lifecycle] application handle events for background session: %@", identifier);
    [TransferSessionManager.shared saveSessionCompletion:completionHandler forIdentifier:identifier];
    [CameraUploadManager.shared startCameraUploadIfNeeded];
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
        _ratingRequestMonitor = [[RatingRequestMonitor alloc] initWithSdk:MEGASdkManager.sharedMEGASdk];
    }
    
    return _ratingRequestMonitor;
}

#pragma mark - Private

- (void)beginBackgroundTaskWithName:(NSString *)name {
    MEGALogDebug(@"Begin background task with name: %@", name);
    
    @try {
        UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:name expirationHandler:^{
            [self endBackgroundTaskWithName:name];
        }];
        
        if (name) {
            NSString *message = [NSString stringWithFormat:@"Can't begin background task with name %@.", name];
            [CrashlyticsLogger log:message];
            [self.backgroundTaskMutableDictionary setObject:name forKey:[NSNumber numberWithUnsignedInteger:backgroundTaskIdentifier]];
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
        }
    } else {
        [self showLink:url];
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
    } else {
        if (completion) completion();
    }
}

- (BOOL)manageQuickActionType:(NSString *)type {
    BOOL quickActionManaged = YES;
    if ([type isEqualToString:@"mega.ios.search"]) {
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
        
        
    } else if ([type isEqualToString:@"mega.ios.upload"]) {
        self.mainTBC.selectedIndex = TabTypeCloudDrive;
        MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:TabTypeCloudDrive];
        CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
        [cloudDriveVC presentUploadOptions];
    } else if ([type isEqualToString:@"mega.ios.offline"]) {
        [self.mainTBC showOfflineAndPresentFileWithHandle:nil];
    } else {
        quickActionManaged = NO;
    }
    
    self.quickActionType = nil;
    
    return quickActionManaged;
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
            
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"]) {
                    [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO
                                                                             withLogout:YES
                                                                         andLogoutTitle:NSLocalizedString(@"logoutLabel", nil)];
                }
            }
        }
        
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            if (isAccountFirstLogin) {
                isAccountFirstLogin = NO;
                if (self.isNewAccount) {
                    if (MEGAPurchase.sharedInstance.products.count > 0) {
                        [UpgradeAccountRouter.new presentChooseAccountType];
                    } else {
                        [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray addObject:self];
                        self.chooseAccountTypeLater = YES;
                    }
                    self.newAccount = NO;
                }
        
                [MEGALinkManager processSelectedOptionOnLink];
                [self showCookieDialogIfNeeded];
            } else {
                [self processActionsAfterSetRootVC];
            }
        }
    }
    
    [self openTabBasedOnNotificationMegatype];
    
    if (self.presentInviteContactVCLater) {
        [self presentInviteContactCustomAlertViewController];
    }
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
}

- (void)showOnboardingWithCompletion:(void (^)(void))completion {
    if ([self.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
        return;
    }
    
    OnboardingViewController *onboardingVC = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault];
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
    
    [MEGASdkManager.sharedMEGAChatSdk removeChatCallDelegate:self.mainTBC];
    [MEGASdkManager.sharedMEGAChatSdk removeChatDelegate:self.mainTBC];
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

- (void)registerForVoIPNotifications {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)registerForNotifications {
    if (!DevicePermissionsHelper.shouldAskForNotificationsPermissions) {
        [DevicePermissionsHelper notificationsPermissionWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }];
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
    MEGALogDebug(@"Copy databases for extensions");
    [MEGASdkManager.sharedMEGAChatSdk saveCurrentState];
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
        if ([filename containsString:@"megaclient"] || [filename containsString:@"karere"]) {
            NSString *destinationPath = [groupSupportPath stringByAppendingPathComponent:filename];
            [NSFileManager.defaultManager mnz_removeItemAtPath:destinationPath];
            if ([fileManager copyItemAtPath:[applicationSupportDirectoryString stringByAppendingPathComponent:filename] toPath:destinationPath error:&error]) {
                MEGALogDebug(@"Copy file %@", filename);
            } else {
                MEGALogError(@"Copy item at path failed with error: %@", error);
            }
        }
    }
}

- (void)performCall {
    MEGAChatStartCallRequestDelegate *requestDelegate = [MEGAChatStartCallRequestDelegate.alloc initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAErrorTypeApiOk) {
            [self performCallWithPresenter:self.mainTBC
                                  chatRoom:self.chatRoom
                          isSpeakerEnabled:self.chatRoom.isMeeting || self.videoCall];
        }
        self.chatRoom = nil;
    }];
    
    [[AVAudioSession sharedInstance] mnz_configureAVSessionForCall];
    [[AVAudioSession sharedInstance] mnz_activate];
    [[AVAudioSession sharedInstance] mnz_setSpeakerEnabled:self.chatRoom.isMeeting];
    [[CallActionManager shared] startCallWithChatId:self.chatRoom.chatId
                                        enableVideo:self.videoCall
                                        enableAudio:!self.chatRoom.isMeeting
                                           delegate:requestDelegate];
}

- (void)presentInviteContactCustomAlertViewController {
    BOOL isInOutgoingContactRequest = NO;
    MEGAContactRequestList *outgoingContactRequestList = [[MEGASdkManager sharedMEGASdk] outgoingContactRequests];
    for (NSInteger i = 0; i < [[outgoingContactRequestList size] integerValue]; i++) {
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
    for (UIWindow *window in application.windows) {
        if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] || [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"]) {
            window.hidden = shouldHide;
        }
    }
}

- (void)initProviderDelegate {
    if (self.megaProviderDelegate == nil) {
        self.megaCallManager = MEGACallManager.new;
        self.megaProviderDelegate = [MEGAProviderDelegate.alloc initWithMEGACallManager:self.megaCallManager];
    }
}

- (void)presentOverDiskQuotaViewControllerIfNeededWithInformation:(id<OverDiskQuotaInfomationProtocol> _Nonnull)overDiskQuotaInformation {
    if (self.isOverDiskQuotaPresented || [UIApplication.mnz_visibleViewController isKindOfClass:OverDiskQuotaViewController.class]) {
        return;
    }

    OverDiskQuotaViewController *overDiskQuotaViewController = OverDiskQuotaViewController.new;
    [overDiskQuotaViewController setupWith:overDiskQuotaInformation];

    __weak typeof(self) weakSelf = self;
    __weak typeof(OverDiskQuotaViewController) *weakOverDiskQuotaViewController = overDiskQuotaViewController;
    overDiskQuotaViewController.dismissAction = ^{
        [weakOverDiskQuotaViewController dismissViewControllerAnimated:YES completion:^{
            weakSelf.overDiskQuotaPresented = NO;
        }];
    };

    UINavigationController *navigationController = [UINavigationController.alloc initWithRootViewController:overDiskQuotaViewController];
    navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:^{
        weakSelf.overDiskQuotaPresented = YES;
    }];
}

- (void)handleTransferQuotaError:(MEGAError *)error transfer:(MEGATransfer *)transfer {
    switch (transfer.type) {
        case MEGATransferTypeDownload:
            [self handleDownloadQuotaError:error];
            break;
        case MEGATransferTypeUpload:
            [self handleStorageQuotaError:error];
            break;
        default:
            break;
    }
}

- (void)handleDownloadQuotaError:(MEGAError *)error {
    if (error.type == MEGAErrorTypeApiEOverQuota) {
        [SVProgressHUD dismiss];
        if (error.value != 0) {
            [[CustomModalAlertRouter.alloc init:CustomModalAlertModeStorageDownloadQuotaError presenter:UIApplication.mnz_presentingViewController] start];
            [NSNotificationCenter.defaultCenter postNotificationName:MEGATransferOverQuotaNotification object:self];
        }
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
    MEGAChatInit initState = [MEGASdkManager.sharedMEGAChatSdk initState];
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
                [MEGASdkManager.sharedMEGAChatSdk importMessagesFromPath:nseCacheFileURL.path];
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
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"dismiss", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
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
    
    if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusGracePeriod) {
        if (MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
            [[CustomModalAlertRouter.alloc init:CustomModalAlertModeBusinessGracePeriod presenter:UIApplication.mnz_presentingViewController] start];
        }
    }
    
    if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusExpired &&
        ![UIApplication.mnz_visibleViewController isKindOfClass:AccountExpiredViewController.class]) {
        AccountExpiredViewController *accountStatusVC = AccountExpiredViewController.alloc.init;
        accountStatusVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [UIApplication.mnz_presentingViewController presentViewController:accountStatusVC animated:YES completion:nil];
    }
}

- (void)presentLogoutFromOtherClientAlert {
    self.API_ESIDAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"loggedOut_alertTitle", nil) message:NSLocalizedString(@"loggedOutFromAnotherLocation", nil) preferredStyle:UIAlertControllerStyleAlert];
    [self.API_ESIDAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:self.API_ESIDAlertController animated:YES completion:nil];
}

- (void)indexFavourites {
    self.spotlightIndexer = [[SpotlightIndexer alloc] initWithSdk:MEGASdkManager.sharedMEGASdk passcodeEnabled:LTHPasscodeViewController.doesPasscodeExist];
    [self.spotlightIndexer indexFavourites];
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    if (![MEGAReachabilityManager isReachable] || [self.window.rootViewController isKindOfClass:[LTHPasscodeViewController class]]) {
        _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [self.window setRootViewController:_mainTBC];
    } else {
        [self showLink:MEGALinkManager.linkURL];

        [self processActionsAfterSetRootVC];
    }
}

- (void)maxNumberOfFailedAttemptsReached {
    [[MEGASdkManager sharedMEGASdk] logout];
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
}

- (void)passcodeWasEnabled {
    [self.spotlightIndexer deindexAllSearchableItems];
}

- (void)passcodeViewControllerWillClose {
    [NSNotificationCenter.defaultCenter postNotificationName:MEGAPasscodeViewControllerWillCloseNotification object:nil];
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

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    MEGALogDebug(@"Did receive incoming push with payload: %@ and type: %@", [payload dictionaryPayload], type);
    
    // Call
    if ([payload.dictionaryPayload[@"megatype"] integerValue] == 4) {
        [self initProviderDelegate];
        NSString *chatIdB64 = payload.dictionaryPayload[@"megadata"][@"chatid"];
        NSString *callIdB64 = payload.dictionaryPayload[@"megadata"][@"callid"];
        uint64_t chatId = [MEGASdk handleForBase64UserHandle:chatIdB64];
        uint64_t callId = [MEGASdk handleForBase64UserHandle:callIdB64];
        
        [self.megaProviderDelegate reportIncomingCallWithCallId:callId chatId:chatId completion:^{
            completion();
        }];
    }
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"userNotificationCenter didReceiveNotificationResponse %@", response);
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[response.notification.request.identifier]];
    self.megatype = (MEGANotificationType)[response.notification.request.content.userInfo[@"megatype"] integerValue];
    
    if (self.megatype) {
        [self openTabBasedOnNotificationMegatype];
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
    uint64_t chatId = [notification.request.content.userInfo[@"chatId"] unsignedLongLongValue];
    uint64_t msgId =  [notification.request.content.userInfo[@"msgId"] unsignedLongLongValue];
    MEGALogDebug(@"[Notification] chatId: %@ messageId: %@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:msgId]);
    if ([notification.request.trigger isKindOfClass:UNPushNotificationTrigger.class]) {
        MOMessage *moMessage = [MEGAStore.shareInstance fetchMessageWithChatId:chatId messageId:msgId];
        if (moMessage) {
            [MEGAStore.shareInstance deleteMessage:moMessage];
            completionHandler(UNNotificationPresentationOptionNone);
        } else {
            completionHandler(UNNotificationPresentationOptionAlert);
        }
    } else {
        completionHandler(UNNotificationPresentationOptionAlert);
    }    
}

#pragma mark - LaunchViewControllerDelegate

- (void)setupFinished {
    if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusGracePeriod &&             [UIApplication.mnz_presentingViewController isKindOfClass:CustomModalAlertViewController.class]) {
        return;
    }
    [self showMainTabBar];
}

- (void)readyToShowRecommendations {
    [self presentAccountExpiredViewIfNeeded];
    [self showCookieDialogIfNeeded];
    [self showAddPhoneNumberIfNeeded];
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    if (self.showChooseAccountTypeLater) {
        [UpgradeAccountRouter.new presentChooseAccountType];
        
        self.chooseAccountTypeLater = NO;
        [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray removeObject:self];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)sdk userList:(MEGAUserList *)userList {
    NSInteger userListCount = userList.size.integerValue;
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
            }
            
            if (user.isOwnChange == 0) { //If the change is external
                if (user.handle == sdk.myUser.handle) {
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
        if (@available(iOS 14.0, *)) {
            [self.quickAccessWidgetManager createQuickAccessWidgetItemsDataIfNeededFor:nodeList];
        }
        
        [self postNodeUpdatesNotificationsFor:nodeList];
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
                __weak typeof(self) weakSelf = self;
                NSNumber *cloudStroageUsed = MEGASdkManager.sharedMEGASdk.mnz_accountDetails.storageUsed;
                OverDiskQuotaCommand *presentOverDiskQuotaScreenCommand = [OverDiskQuotaCommand.alloc initWithStorageUsed:cloudStroageUsed completionAction:^(id<OverDiskQuotaInfomationProtocol> _Nullable infor) {
                    if (infor != nil) {
                        [weakSelf presentOverDiskQuotaViewControllerIfNeededWithInformation:infor];
                    }
                }];
                [OverDiskQuotaService.sharedService send:presentOverDiskQuotaScreenCommand];
            } else {
                static BOOL alreadyPresented = NO;
                if (!alreadyPresented && (event.number == StorageStateRed || event.number == StorageStateOrange)) {
                    alreadyPresented = YES;
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
            
        case EventMiscFlagsReady:
            [self showAddPhoneNumberIfNeeded];
            break;
            
        case EventStorageSumChanged:
            [MEGASdkManager.sharedMEGASdk mnz_setShouldRequestAccountDetails:YES];
            break;
            
        case EventReloading: {
            isFetchNodesDone = NO;
            [self showLaunchViewController];
            break;
        }
        default:
            break;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
            
        case MEGARequestTypeLogout: {
            if (MEGALinkManager.urlType == URLTypeCancelAccountLink || MEGASdkManager.sharedMEGASdk.isGuestAccount) {
                return;
            }
            
            if (request.paramType != MEGAErrorTypeApiESSL && request.flag) {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudLogOut"] status:NSLocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
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
                            UIAlertController *accountCanceledSuccessfullyAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"accountCanceledSuccessfully", @"During account cancellation (deletion)") message:nil preferredStyle:UIAlertControllerStyleAlert];
                            [accountCanceledSuccessfullyAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleCancel handler:nil]];
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
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"dialog.shareOwnerStorageQuota.message", nil) preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
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
                    _sslKeyPinningController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"sslUnverified_alertTitle", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ignore", @"Button title to allow the user ignore something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        [api setPublicKeyPinning:NO];
                        [api reconnect];
                    }]];
                    
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"retry", @"Button which allows to retry send message in chat conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        self.sslKeyPinningController = nil;
                        [api retryPendingConnections];
                    }]];
                    
                    [self.sslKeyPinningController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"openBrowser", @"Button title to allow the user open the default browser") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
                __weak typeof(self) weakSelf = self;
                NSNumber *cloudStroageUsed = MEGASdkManager.sharedMEGASdk.mnz_accountDetails.storageUsed;
                OverDiskQuotaCommand *presentOverDiskQuotaScreenCommand =
                    [[OverDiskQuotaCommand alloc] initWithStorageUsed:cloudStroageUsed completionAction:^(id<OverDiskQuotaInfomationProtocol> _Nullable infor) {
                        if (infor != nil) {
                            [weakSelf presentOverDiskQuotaViewControllerIfNeededWithInformation:infor];
                        }
                    }];
                [OverDiskQuotaService.sharedService send:presentOverDiskQuotaScreenCommand];
                break;
            }
            default:
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                isAccountFirstLogin = NO;
                isFetchNodesDone = NO;
            } else {
                isAccountFirstLogin = YES;
                self.newAccount = (MEGALinkManager.urlType == URLTypeConfirmationLink);
                if (MEGALinkManager.selectedOption != LinkOptionJoinChatLink) {
                    [MEGALinkManager resetLinkAndURLType];
                }
                [NSUserDefaults.standardUserDefaults setObject:[NSDate date] forKey:MEGAFirstLoginDate];
            }
                        
            [self initProviderDelegate];
            [self registerForVoIPNotifications];
            [self registerForNotifications];
            [[MEGASdkManager sharedMEGASdk] fetchNodes];
            if (@available(iOS 14.0, *)) {
                [QuickAccessWidgetManager reloadAllWidgetsContent];
            }
            
            [api setAccountAuth:api.accountAuth];
            break;
        }
            
        case MEGARequestTypeCreateAccount: {
            [self initProviderDelegate];
        }
            
        case MEGARequestTypeFetchNodes: {
            
            [[SKPaymentQueue defaultQueue] addTransactionObserver:[MEGAPurchase sharedInstance]];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [[MEGASdkManager sharedMEGASdk] pauseTransfers:YES];
                [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"TransfersPaused"];
            }
            isFetchNodesDone = YES;
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            
            [self requestUserName];
            [self requestContactsFullname];
            [self updateContactsNickname];
            
            MEGAChatNotificationDelegate *chatNotificationDelegate = MEGAChatNotificationDelegate.new;
            [[MEGASdkManager sharedMEGAChatSdk] addChatNotificationDelegate:chatNotificationDelegate];
            
            if ([MEGASdkManager sharedMEGASdk].isGuestAccount) {
                return;
            }
            
            if (!isAccountFirstLogin) {
                [self showMainTabBar];
                if (self.openChatLater) {
                    [self.mainTBC openChatRoomNumber:self.openChatLater];
                }
            }
            
            [[MEGASdkManager sharedMEGASdk] getAccountDetails];

            if (![ContactsOnMegaManager.shared areContactsOnMegaRequestedWithinDays:7]) {
                [ContactsOnMegaManager.shared configureContactsOnMegaWithCompletion:nil];
            } else {
                [ContactsOnMegaManager.shared loadContactsOnMegaFromLocal];
            }

            if (@available(iOS 14.0, *)) {
                [self.quickAccessWidgetManager createWidgetItemData];
            }
            
            [self presentAccountExpiredViewIfNeeded];
            
            [self configAppWithNewCookieSettings];
            break;
        }
            
        case MEGARequestTypeLogout: {
            // if logout (not if localLogout) or session killed in other client
            BOOL sessionInvalidateInOtherClient = request.paramType == MEGAErrorTypeApiESid;
            if (request.flag || sessionInvalidateInOtherClient) {
                [Helper logout];
                [self showOnboardingWithCompletion:nil];
                
                [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:nil];
                
                if (@available(iOS 14.0, *)) {
                    [QuickAccessWidgetManager reloadAllWidgetsContent];
                }
                if (sessionInvalidateInOtherClient && !self.API_ESIDAlertController) {
                    [self presentLogoutFromOtherClientAlert];
                }
                
                [api setAccountAuth:nil];
            }
            break;
        }
            
        case MEGARequestTypeAccountDetails:
            [MEGASdkManager.sharedMEGASdk mnz_setShouldRequestAccountDetails:NO];
            [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:[request megaAccountDetails]];
            [OverDiskQuotaService.sharedService updateUserStorageUsed:MEGASdkManager.sharedMEGASdk.mnz_accountDetails.storageUsed];
            break;
            
        case MEGARequestTypeGetAttrUser: {
            MEGAUser *user;
            MEGAUser *me = MEGASdkManager.sharedMEGASdk.myUser;
            
            if (me.handle == request.nodeHandle) {
                user = me;
            } else if (request.email.length > 0) {
                user = [api contactForEmail:request.email];
            } else if (request.email == nil) {
                user = me;
            }
                        
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
                        [MEGAStore.shareInstance insertUserWithUserHandle:user.handle firstname:request.text lastname:nil nickname:nil email:user.email];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname) {
                        [MEGAStore.shareInstance insertUserWithUserHandle:user.handle firstname:nil lastname:request.text nickname:nil email:user.email];
                    }
                }
            } else if (request.email.length > 0) {
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
                        [MEGAStore.shareInstance insertUserWithUserHandle:[MEGASdk handleForBase64UserHandle:request.email] firstname:request.text lastname:nil nickname:nil email:request.email];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname) {
                        [MEGAStore.shareInstance insertUserWithUserHandle:[MEGASdk handleForBase64UserHandle:request.email] firstname:nil lastname:request.text nickname:nil email:request.email];
                    }
                }
            } else if (request.paramType == MEGAUserAttributeAlias) {
                [MEGAStore.shareInstance updateUserWithUserHandle:user.handle nickname:request.name];
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
        [self.megaProviderDelegate invalidateProvider];
        self.megaProviderDelegate = nil;
        self.megaCallManager = nil;
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
        [[MEGASdkManager sharedMEGAChatSdk] logout];
    }
    if (newState == MEGAChatInitOnlineSession) {
        [self copyDatabasesForExtensions];
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (self.chatRoom.chatId == chatId && newState == MEGAChatConnectionOnline) {
        [self performCall];
    }
}

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    if (item.changes == 0 && self.chatLastKnownInitState == MEGAChatStatusOnline) {
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

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [transfer mnz_createThumbnailAndPreview];
        });
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.state == MEGATransferStatePaused) {
        [Helper startPendingUploadTransferIfNeeded];
    }
}

- (void)onTransferTemporaryError:(MEGASdk *)sdk transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    MEGALogDebug(@"onTransferTemporaryError %td", error.type)
    if (!transfer.isForeignOverquota) {
        [self handleTransferQuotaError:error transfer:transfer];
    }
}

- (void)onTransferFinish:(MEGASdk *)sdk transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.type != MEGATransferTypeUpload && transfer.isStreamingTransfer) {
        return;
    }
    
    //Delete transfer from dictionary file even if we get an error
    MEGANode *node = nil;
    if ([transfer type] == MEGATransferTypeDownload) {
        node = [sdk nodeForHandle:transfer.nodeHandle];
        if (!node) {
            node = [transfer publicNode];
        }
    }
    
    if (transfer.type == MEGATransferTypeUpload) {
        [transfer mnz_renameOrRemoveThumbnailAndPreview];
        
        if ([transfer.appData containsString:@"attachToChatID"] || [transfer.appData containsString:@"attachVoiceClipToChatID"]) {
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogInfo(@"Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
        }
                
        if ([transfer.appData containsString:@">localIdentifier"]) {
            NSString *localIdentifier = [transfer.appData mnz_stringBetweenString:@">localIdentifier=" andString:@""];
            [[Helper uploadingNodes] removeObject:localIdentifier];
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
                    NSString *transferFailed = NSLocalizedString(@"Transfer failed:", @"Notification message shown when a transfer failed. Keep colon.");
                    NSString *errorString = [MEGAError errorStringWithErrorCode:error.type context:(transfer.type == MEGATransferTypeUpload) ? MEGAErrorContextUpload : MEGAErrorContextDownload];
                    MEGALogError(@"%@\n%@ %@", transfer.fileName, transferFailed, NSLocalizedString(errorString, nil));
                }
                break;
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {        
        [SaveNodeUseCaseOCWrapper.alloc.init saveNodeIfNeededFrom:transfer];
        
        if (@available(iOS 14.0, *)) {
            [QuickAccessWidgetManager reloadWidgetContentOfKindWithKind:MEGAOfflineQuickAccessWidget];
        }
        
        if (transfer.fileName.mnz_isVideoPathExtension && !node.hasThumbnail) {
            NSURL *videoURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path]];
            [node mnz_generateThumbnailForVideoAtPath:videoURL];
        }
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:MEGATransferFinishedNotification object:nil userInfo:@{MEGATransferUserInfoKey : transfer}];
}

#pragma mark - MEGAApplicationDelegate

- (void)application:(MEGAApplication *)application willSendTouchEvent:(UIEvent *)event {
    if (MEGASdkManager.sharedMEGAChatSdk.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
}

@end
