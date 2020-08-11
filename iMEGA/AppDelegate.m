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
#import "MEGAIndexer.h"
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
#import "CallViewController.h"
#import "ChatRoomsViewController.h"
#import "CheckEmailAndFollowTheLinkViewController.h"
#import "CloudDriveViewController.h"
#import "ContactsViewController.h"
#import "CustomModalAlertViewController.h"
#import "GroupCallViewController.h"
#import "LaunchViewController.h"
#import "MainTabBarController.h"
#import "OnboardingViewController.h"
#import "ProductDetailViewController.h"
#import "UpgradeTableViewController.h"

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
#import "BackgroundRefreshPerformer.h"

#import "MEGA-Swift.h"

@interface AppDelegate () <PKPushRegistryDelegate, UIApplicationDelegate, UNUserNotificationCenterDelegate, LTHPasscodeViewControllerDelegate, LaunchViewControllerDelegate, MEGAApplicationDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, MEGAGlobalDelegate, MEGAPurchasePricingDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
}

@property (nonatomic, strong) UIView *privacyView;

@property (nonatomic, strong) NSString *quickActionType;

@property (nonatomic, strong) UIAlertController *API_ESIDAlertController;

@property (nonatomic, weak) MainTabBarController *mainTBC;

@property (nonatomic) NSUInteger megatype; //1 share folder, 2 new message, 3 contact request

@property (strong, nonatomic) MEGAChatRoom *chatRoom;
@property (nonatomic, getter=isVideoCall) BOOL videoCall;

@property (strong, nonatomic) NSString *email;
@property (nonatomic) BOOL presentInviteContactVCLater;

@property (nonatomic, getter=isNewAccount) BOOL newAccount;
@property (nonatomic, getter=showChooseAccountTypeLater) BOOL chooseAccountTypeLater;

@property (nonatomic, strong) UIAlertController *sslKeyPinningController;

@property (nonatomic) NSMutableDictionary *backgroundTaskMutableDictionary;

@property (nonatomic, getter=wasAppSuspended) BOOL appSuspended;
@property (nonatomic, getter=isUpgradeVCPresented) BOOL upgradeVCPresented;
@property (nonatomic, getter=isAccountExpiredPresented) BOOL accountExpiredPresented;
@property (nonatomic, getter=isOverDiskQuotaPresented) BOOL overDiskQuotaPresented;

@property (strong, nonatomic) BackgroundRefreshPerformer *backgroundRefreshPerformer;
@property (nonatomic, strong) MEGAProviderDelegate *megaProviderDelegate;

@property (nonatomic) MEGAChatInit chatLastKnownInitState;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    
    NSError *error;
    [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3" error:&error];
    if (error.code == errSecInteractionNotAllowed) {
        exit(0);
    }

#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    [MEGASdk setLogToConsole:YES];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
        [[MEGALogger sharedLogger] startLogging];
    }

    MEGALogDebug(@"[App Lifecycle] Application will finish launching with options: %@", launchOptions);
    
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self migrateLocalCachesLocation];
    
    if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        _megatype = [[[launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"] objectForKey:@"megatype"] unsignedIntegerValue];
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    [MEGAReachabilityManager sharedManager];
    
    [CameraUploadManager.shared setupCameraUploadWhenApplicationLaunches];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pointToStaging"]) {
        [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
        [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
    }
    
    [ChatUploader.sharedInstance setup];
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [[MEGASdkManager sharedMEGASdk] httpServerSetMaxBufferSize:[UIDevice currentDevice].maxBufferSize];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"presentPasscodeLater"];
    
    [self languageCompatibility];
    
    self.backgroundTaskMutableDictionary = [[NSMutableDictionary alloc] init];
    
    NSString *sessionV3 = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    
    //Clear keychain (session) and delete passcode on first run in case of reinstallation
    if (![NSUserDefaults.standardUserDefaults objectForKey:MEGAFirstRun]) {
        sessionV3 = nil;
        [Helper clearEphemeralSession];
        [Helper clearSession];
        [Helper deletePasscode];
        [NSUserDefaults.standardUserDefaults setValue:MEGAFirstRunValue forKey:MEGAFirstRun];
        if (@available(iOS 12.0, *)) {} else {
            [NSUserDefaults.standardUserDefaults synchronize];
        }
    }
    
    [AppearanceManager setupAppearance:self.window.traitCollection];
    
    [MEGALinkManager resetLinkAndURLType];
    isFetchNodesDone = NO;
    _presentInviteContactVCLater = NO;
    
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
        
        if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
            [MEGASdkManager createSharedMEGAChatSdk];
        } else {
            [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
        }
        
        [self initProviderDelegate];
        
        MEGAChatInit chatInit = [MEGASdkManager.sharedMEGAChatSdk initKarereWithSid:sessionV3];
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere with session failed");
            NSString *message = [NSString stringWithFormat:@"Error (%ld) initializing the chat", (long)chatInit];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            [[MEGASdkManager sharedMEGAChatSdk] logout];
            [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        } else if (chatInit == MEGAChatInitOnlineSession || chatInit == MEGAChatInitOfflineSession) {
            [self importMessagesFromNSE];
        }
        
        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        [MEGASdkManager.sharedMEGASdk fastLoginWithSession:sessionV3 delegate:loginRequestDelegate];
        
        if ([MEGAReachabilityManager isReachable]) {
            LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
            [UIView transitionWithView:self.window duration:0.5 options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent) animations:^{
                [self.window setRootViewController:launchVC];
            } completion:nil];
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                if ([NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps]) {
                    [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                }
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                         withLogout:NO
                                                                     andLogoutTitle:nil];
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
                if (@available(iOS 13.0, *)) {
                    checkEmailAndFollowTheLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
                }
                [UIApplication.mnz_presentingViewController presentViewController:checkEmailAndFollowTheLinkVC animated:YES completion:nil];
            }];
            createAccountRequestDelegate.resumeCreateAccount = YES;
            [[MEGASdkManager sharedMEGASdk] resumeCreateAccountWithSessionId:sessionId delegate:createAccountRequestDelegate];
        }
    }
    
    [Helper setIndexer:MEGAIndexer.sharedIndexer];
    
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
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did enter background");
    
    if (MEGASdkManager.sharedMEGASdk.isLoggedIn > 1) {
        [self beginBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    }
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:YES];
    [[MEGASdkManager sharedMEGAChatSdk] saveCurrentState];

    [LTHPasscodeViewController.sharedUser setDelegate:self];

    BOOL pendingTasks = [[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] > 0 || [[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] > 0;
    if (pendingTasks) {
        [self beginBackgroundTaskWithName:@"PendingTasks"];
    }
    
    if (self.backgroundTaskMutableDictionary.count == 0) {
        self.appSuspended = YES;
        MEGALogDebug(@"App suspended property = YES.");
    }
    
    if (@available(iOS 12.0, *)) {} else {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
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
    
    if (self.wasAppSuspended && !MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
        //If the app has been suspended, we assume that the sockets have been closed, so we have to reconnect.
        [[MEGAReachabilityManager sharedManager] reconnect];
    } else {
        [[MEGAReachabilityManager sharedManager] retryOrReconnect];
    }
    self.appSuspended = NO;
    MEGALogDebug(@"App suspended property = NO.");
    
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:NO];
    
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        if (isFetchNodesDone) {
            MEGAShowPasswordReminderRequestDelegate *showPasswordReminderDelegate = [[MEGAShowPasswordReminderRequestDelegate alloc] initToLogout:NO];
            [[MEGASdkManager sharedMEGASdk] shouldShowPasswordReminderDialogAtLogout:NO delegate:showPasswordReminderDelegate];
        }
    }
    
    [self.privacyView removeFromSuperview];
    self.privacyView = nil;
    
    [self application:application shouldHideWindows:NO];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllPendingNotificationRequests];
    [center removeAllDeliveredNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did become active");
    
    if (MEGASdkManager.sharedMEGAChatSdk.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
    
    if (![NSStringFromClass([UIApplication sharedApplication].windows.firstObject.class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] enablePasscodeWhenApplicationEntersBackground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will terminate");
    
    [MEGASdkManager destroySharedMEGAChatSdk];
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[MEGAPurchase sharedInstance]];
    
    if ([[[[MEGASdkManager sharedMEGASdk] downloadTransfers] size] integerValue] == 0) {
        [NSFileManager.defaultManager mnz_removeFolderContentsRecursivelyAtPath:[Helper pathForOffline] forItemsExtension:@"mega"];
        [NSFileManager.defaultManager mnz_removeItemAtPath:[NSFileManager.defaultManager downloadsDirectory]];
    }
    if ([[[[MEGASdkManager sharedMEGASdk] uploadTransfers] size] integerValue] == 0) {
        [NSFileManager.defaultManager mnz_removeItemAtPath:[NSFileManager.defaultManager uploadsDirectory]];
    }
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
                            UIViewController *presentedVC = UIApplication.mnz_presentingViewController;
                            if ([presentedVC isKindOfClass:CallViewController.class]) {
                                CallViewController *callVC = (CallViewController *)UIApplication.mnz_presentingViewController;
                                if (!callVC.videoCall) {
                                    [callVC tapOnVideoCallkitWhenDeviceIsLocked];
                                    self.chatRoom = nil;
                                }
                            }
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
                    UIViewController *presentedVC = UIApplication.mnz_presentingViewController;
                    if ([presentedVC isKindOfClass:GroupCallViewController.class]) {
                        GroupCallViewController *callVC = (GroupCallViewController *)presentedVC;
                        callVC.callType = CallTypeActive;
                        [callVC tapOnVideoCallkitWhenDeviceIsLocked];
                        self.chatRoom = nil;
                    }
                    if ([presentedVC isKindOfClass:CallViewController.class]) {
                        CallViewController *callVC = (CallViewController *)UIApplication.mnz_presentingViewController;
                        [callVC tapOnVideoCallkitWhenDeviceIsLocked];
                        self.chatRoom = nil;
                    }
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
    
    [MEGAIndexer.sharedIndexer stopIndexing];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"[App Lifecycle] application handle events for background session: %@", identifier);
    [TransferSessionManager.shared saveSessionCompletion:completionHandler forIdentifier:identifier];
    [CameraUploadManager.shared startCameraUploadIfNeeded];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    MEGALogDebug(@"[App Lifecycle] application perform background refresh");
    [self.backgroundRefreshPerformer performBackgroundRefreshWithCompletionHandler:completionHandler];
}

#pragma mark - Properties

- (BackgroundRefreshPerformer *)backgroundRefreshPerformer {
    if (_backgroundRefreshPerformer == nil) {
        _backgroundRefreshPerformer = [[BackgroundRefreshPerformer alloc] init];
    }
    
    return _backgroundRefreshPerformer;
}

#pragma mark - Private

- (void)beginBackgroundTaskWithName:(NSString *)name {
    MEGALogDebug(@"Begin background task with name: %@", name);
    
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:name expirationHandler:^{
        [self endBackgroundTaskWithName:name];
    }];
    
    [self.backgroundTaskMutableDictionary setObject:name forKey:[NSNumber numberWithUnsignedInteger:backgroundTaskIdentifier]];
}

- (void)endBackgroundTaskWithName:(NSString *)name {
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
                [checkEmailAndFollowTheLinkVC.presentedViewController dismissViewControllerAnimated:NO completion:^{
                    if (completion) completion();
                }];
            } else {
                if (completion) completion();
            }
        } else {
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
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
        [self.mainTBC showOffline];
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
                if ([NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps]) {
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
            if (MEGALinkManager.nodeToPresentBase64Handle) {
                [MEGALinkManager presentNode];
            }
            
            if (isAccountFirstLogin) {
                isAccountFirstLogin = NO;
                if (self.isNewAccount) {
                    if (MEGAPurchase.sharedInstance.products.count > 0) {
                        [self showChooseAccountType];
                    } else {
                        [MEGAPurchase.sharedInstance setPricingsDelegate:self];
                        self.chooseAccountTypeLater = YES;
                    }
                    self.newAccount = NO;
                }
        
                [MEGALinkManager processSelectedOptionOnLink];
            }
            
            [self showLink:MEGALinkManager.linkURL];
            
            [self manageQuickActionType:self.quickActionType];
        }
    }
    
    [self openTabBasedOnNotificationMegatype];
    
    if (self.presentInviteContactVCLater) {
        [self presentInviteContactCustomAlertViewController];
    }
}

- (void)showOnboarding {
    OnboardingViewController *onboardingVC = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault];
    UIView *overlayView = [UIScreen.mainScreen snapshotViewAfterScreenUpdates:NO];
    [onboardingVC.view addSubview:overlayView];
    self.window.rootViewController = onboardingVC;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        overlayView.alpha = 0;
    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
        [SVProgressHUD dismiss];
    }];
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
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
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

void uncaughtExceptionHandler(NSException *exception) {
    MEGALogError(@"Exception name: %@\nreason: %@\nuser info: %@\n", exception.name, exception.reason, exception.userInfo);
    MEGALogError(@"Stack trace: %@", [exception callStackSymbols]);
}


- (void)performCall {
    if (self.chatRoom.isGroup) {
        GroupCallViewController *groupCallVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupCallViewControllerID"];
        groupCallVC.callType = CallTypeOutgoing;
        groupCallVC.videoCall = self.videoCall;
        groupCallVC.chatRoom = self.chatRoom;
        groupCallVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        groupCallVC.megaCallManager = self.megaCallManager;
        groupCallVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self.mainTBC presentViewController:groupCallVC animated:YES completion:nil];
    } else {
        CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
        callVC.chatRoom = self.chatRoom;
        callVC.videoCall = self.videoCall;
        callVC.callType = CallTypeOutgoing;
        callVC.megaCallManager = self.megaCallManager;
        callVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self.mainTBC presentViewController:callVC animated:YES completion:nil];
    }
    self.chatRoom = nil;
}

- (void)presentInviteContactCustomAlertViewController {
    CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
    
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
        customModalAlertVC.firstButtonTitle = AMLocalizedString(@"close", nil);
        customModalAlertVC.dismissButtonTitle = nil;
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.firstCompletion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
    } else {
        customModalAlertVC.image = [UIImage imageNamed:@"groupChat"];
        customModalAlertVC.viewTitle = AMLocalizedString(@"inviteContact", @"Title shown when the user tries to make a call and the destination is not in the contact list");
        customModalAlertVC.detail = [NSString stringWithFormat:@"Your contact %@ is not on MEGA. In order to call through MEGA's encrypted chat you need to invite your contact", self.email];
        customModalAlertVC.firstButtonTitle = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
        customModalAlertVC.dismissButtonTitle = AMLocalizedString(@"later", @"Button title to allow the user postpone an action");
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.firstCompletion = ^{
            MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
            [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:self.email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
    }
    
    [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    
    self.presentInviteContactVCLater = NO;
}

- (void)application:(UIApplication *)application shouldHideWindows:(BOOL)shouldHide {
    for (UIWindow *window in application.windows) {
        if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] || [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"]) {
            window.hidden = shouldHide;
        }
    }
}

- (void)showChooseAccountType {
    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"UpgradeAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeTableViewControllerID"];
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    upgradeTVC.chooseAccountType = YES;
    
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
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
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:^{
        weakSelf.overDiskQuotaPresented = YES;
    }];
}

- (void)presentUpgradeViewControllerTitle:(NSString *)title detail:(NSString *)detail image:(UIImage *)image {
    if (!self.isUpgradeVCPresented && ![UIApplication.mnz_visibleViewController isKindOfClass:UpgradeTableViewController.class] && ![UIApplication.mnz_visibleViewController isKindOfClass:ProductDetailViewController.class]) {
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.image = image;
        customModalAlertVC.viewTitle = title;
        customModalAlertVC.detail = detail;
        customModalAlertVC.firstButtonTitle = AMLocalizedString(@"seePlans", @"Button title to see the available pro plans in MEGA");
        if ([[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
            customModalAlertVC.secondButtonTitle = AMLocalizedString(@"getBonus", @"Button title to see the available bonus");
        }
        customModalAlertVC.dismissButtonTitle = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.firstCompletion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:^{
                self.upgradeVCPresented = NO;
                if ([MEGAPurchase sharedInstance].products.count > 0) {
                    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"UpgradeAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeTableViewControllerID"];
                    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
                    
                    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
                } else {
                    // Redirect to my account if the products are not available
                    [self.mainTBC setSelectedIndex:4];
                }
            }];
        };
        
        customModalAlertVC.dismissCompletion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:^{
                self.upgradeVCPresented = NO;
            }];
        };
        
        customModalAlertVC.secondCompletion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:^{
                self.upgradeVCPresented = NO;
                AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
                achievementsVC.enableCloseBarButton = YES;
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
                [UIApplication.mnz_presentingViewController presentViewController:navigation animated:YES completion:nil];
            }];
        };
        
        self.upgradeVCPresented = YES;
        [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
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
    if (!self.isAccountExpiredPresented && ![UIApplication.mnz_visibleViewController isKindOfClass:BusinessExpiredViewController.class]) {
        NSString *alertTitle = AMLocalizedString(@"Your business account is expired", @"A dialog title shown to users when their business account is expired.");
        NSString *alertMessage;
        if (MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
            alertMessage = AMLocalizedString(@"There has been a problem processing your payment. MEGA is limited to view only until this issue has been fixed in a desktop web browser.", @"Details shown when a Business account is expired. Details for the administrator of the Business account");
        } else {
            alertMessage = [[[[AMLocalizedString(@"Your account is currently [B]suspended[/B]. You can only browse your data.", @"A dialog message which is shown to sub-users of expired business accounts.") stringByReplacingOccurrencesOfString:@"[B]" withString:@""] stringByReplacingOccurrencesOfString:@"[/B]" withString:@""] stringByAppendingString:@"\n\n"] stringByAppendingString:AMLocalizedString(@"Contact your business account administrator to resolve the issue and activate your account.", @"A dialog message which is shown to sub-users of expired business accounts.")];
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"dismiss", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.accountExpiredPresented = NO;
        }]];
        
        self.accountExpiredPresented = YES;
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)presentBusinessExpiredViewIfNeeded {
    if ([UIApplication.mnz_visibleViewController isKindOfClass:InitialLaunchViewController.class] || [UIApplication.mnz_visibleViewController isKindOfClass:LaunchViewController.class]) {
        return;
    }
    
    if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusGracePeriod) {
        if (MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
            CustomModalAlertViewController *customModalAlertVC = CustomModalAlertViewController.alloc.init;
            customModalAlertVC.image = [UIImage imageNamed:@"paymentOverdue"];
            customModalAlertVC.viewTitle = AMLocalizedString(@"Something went wrong", @"");
            customModalAlertVC.detail = AMLocalizedString(@"There has been a problem with your last payment. Please access MEGA using a desktop browser for more information.", @"When logging in during the grace period, the administrator of the Business account will be notified that their payment is overdue, indicating that they need to access MEGA using a desktop browser for more information");
            customModalAlertVC.dismissButtonTitle = AMLocalizedString(@"dismiss", @"");
            __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
            customModalAlertVC.dismissCompletion = ^{
                [weakCustom dismissViewControllerAnimated:YES completion:^{
                    if (![self.window.rootViewController isKindOfClass:MainTabBarController.class] && ![self.window.rootViewController isKindOfClass:InitialLaunchViewController.class]) {
                        [self showMainTabBar];
                    }
                }];
            };
            
            [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
        }
    }
    
    if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusExpired) {
        BusinessExpiredViewController *businessStatusVC = BusinessExpiredViewController.alloc.init;
        [UIApplication.mnz_presentingViewController presentViewController:businessStatusVC animated:YES completion:nil];
    }
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    if (![MEGAReachabilityManager isReachable] || [self.window.rootViewController isKindOfClass:[LTHPasscodeViewController class]]) {
        _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [self.window setRootViewController:_mainTBC];
    } else {
        [self showLink:MEGALinkManager.linkURL];
        
        if (MEGALinkManager.nodeToPresentBase64Handle) {
            [MEGALinkManager presentNode];
        }
        
        [self manageQuickActionType:self.quickActionType];
    }
}

- (void)maxNumberOfFailedAttemptsReached {
    if ([NSUserDefaults.standardUserDefaults boolForKey:MEGAPasscodeLogoutAfterTenFailedAttemps]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
}

- (void)passcodeWasEnabled {
    MEGAIndexer.sharedIndexer.enableSpotlight = NO;
}

#pragma mark - Language

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
    NSString *scriptDesignator = [componentsFromLocaleID valueForKey:NSLocaleScriptCode];
    NSString *languageAndScriptDesignator = languageDesignator;
    if (scriptDesignator) languageAndScriptDesignator = [NSString stringWithFormat:@"%@-%@", languageAndScriptDesignator, scriptDesignator];
    
    if ([Helper isLanguageSupported:languageAndScriptDesignator]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageAndScriptDesignator];
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
    MEGALogDebug(@"Did receive incoming push with payload: %@ and type: %@", [payload dictionaryPayload], type);
    
    // Call
    if ([payload.dictionaryPayload[@"megatype"] integerValue] == 4) {
        [self initProviderDelegate];
        NSString *chatIdB64 = payload.dictionaryPayload[@"megadata"][@"chatid"];
        NSString *callIdB64 = payload.dictionaryPayload[@"megadata"][@"callid"];
        uint64_t chatId = [MEGASdk handleForBase64UserHandle:chatIdB64];
        uint64_t callId = [MEGASdk handleForBase64UserHandle:callIdB64];
        
        [self.megaProviderDelegate reportIncomingCallWithCallId:callId chatId:chatId];
    }
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"userNotificationCenter didReceiveNotificationResponse %@", response);
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[response.notification.request.identifier]];
    
    [self.mainTBC openChatRoomNumber:response.notification.request.content.userInfo[@"chatId"]];
    
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
    [self presentBusinessExpiredViewIfNeeded];
    [self showAddPhoneNumberIfNeeded];
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
                    [MEGAStore.shareInstance insertUserWithUserHandle:user.handle firstname:nil lastname:nil nickname:nil email:user.email];
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
                    if ([user hasChangedType:MEGAUserChangeTypeUserAlias]) {
                        [self fetchContactsNickname];
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
        
        if (user.visibility == MEGAUserVisibilityHidden) {
            [MEGAStore.shareInstance updateUserWithHandle:user.handle interactedWith:NO];
        }
    }
}

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (!nodeList) {
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
                    NSString *detail = event.number == StorageStateOrange ? AMLocalizedString(@"cloudDriveIsAlmostFull", @"Informs the user that they’ve almost reached the full capacity of their Cloud Drive for a Free account. Please leave the [S], [/S], [A], [/A] placeholders as they are.") : AMLocalizedString(@"cloudDriveIsFull", @"A message informing the user that they've reached the full capacity of their accounts. Please leave [S], [/S] as it is which is used to bolden the text.");
                    detail = [detail mnz_removeWebclientFormatters];
                    NSString *maxStorage = [NSString stringWithFormat:@"%ld", (long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:7]];
                    NSString *maxStorageTB = [NSString stringWithFormat:@"%ld", (long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:7] / 1024];
                    detail = [NSString stringWithFormat:detail, maxStorageTB, maxStorage];
                    alreadyPresented = YES;
                    NSString *title = AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
                    UIImage *image = event.number == StorageStateOrange ? [UIImage imageNamed:@"storage_almost_full"] : [UIImage imageNamed:@"storage_full"];
                    [self presentUpgradeViewControllerTitle:title detail:detail image:image];
                }
            }
            break;
        }
            
        case EventBusinessStatus:
            [self presentBusinessExpiredViewIfNeeded];
            break;
            
        case EventMiscFlagsReady:
            [self showAddPhoneNumberIfNeeded];
            break;
            
        case EventStorageSumChanged:
            [MEGASdkManager.sharedMEGASdk mnz_setShouldRequestAccountDetails:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
            
        case MEGARequestTypeLogout: {
            if (MEGALinkManager.urlType == URLTypeCancelAccountLink) {
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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    MEGALogDebug(@"onRequestFinish, request type: %ld, error type: %ld", (long)request.type, (long)error.type)
    
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs: {
                if ([request type] == MEGARequestTypeLogin) {
                    [Helper logout];
                    [self showOnboarding];
                }
                break;
            }
                
            case MEGAErrorTypeApiESid: {                                
                if (MEGALinkManager.urlType == URLTypeCancelAccountLink) {
                    [Helper logout];
                    [self showOnboarding];
                    
                    UIAlertController *accountCanceledSuccessfullyAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"accountCanceledSuccessfully", @"During account cancellation (deletion)") message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [accountCanceledSuccessfullyAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleCancel handler:nil]];
                    [UIApplication.mnz_presentingViewController presentViewController:accountCanceledSuccessfullyAlertController animated:YES completion:^{
                        [MEGALinkManager resetLinkAndURLType];
                    }];
                    return;
                }
                
                if ([request type] == MEGARequestTypeLogin || [request type] == MEGARequestTypeLogout) {
                    if (!self.API_ESIDAlertController || UIApplication.mnz_presentingViewController.presentedViewController != self.API_ESIDAlertController) {
                        [Helper logout];
                        [self showOnboarding];
                        
                        self.API_ESIDAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"loggedOut_alertTitle", nil) message:AMLocalizedString(@"loggedOutFromAnotherLocation", nil) preferredStyle:UIAlertControllerStyleAlert];
                        [self.API_ESIDAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                        [UIApplication.mnz_presentingViewController presentViewController:self.API_ESIDAlertController animated:YES completion:nil];
                    }
                }
                break;
            }
                
            case MEGAErrorTypeApiEgoingOverquota:
            case MEGAErrorTypeApiEOverQuota: {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
                
                NSString *title = AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
                NSString *detail = AMLocalizedString(@"This action can not be completed as it would take you over your current storage limit", @"Error message shown to user when a copy/import operation would take them over their storage limit.");
                UIImage *image = [api mnz_accountDetails].storageMax.longLongValue > [api mnz_accountDetails].storageUsed.longLongValue ? [UIImage imageNamed:@"storage_almost_full"] : [UIImage imageNamed:@"storage_full"];
                [self presentUpgradeViewControllerTitle:title detail:detail image:image];
                
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
            }
                        
            [self initProviderDelegate];
            [self registerForVoIPNotifications];
            [self registerForNotifications];
            [[MEGASdkManager sharedMEGASdk] fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:[MEGAPurchase sharedInstance]];
            [[MEGASdkManager sharedMEGASdk] enableTransferResumption];
            
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
            [self fetchContactsNickname];
            
            [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self.mainTBC];
            
            MEGAChatNotificationDelegate *chatNotificationDelegate = MEGAChatNotificationDelegate.new;
            [[MEGASdkManager sharedMEGAChatSdk] addChatNotificationDelegate:chatNotificationDelegate];
            
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                [[MEGASdkManager sharedMEGAChatSdk] connectInBackground];
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] connect];
            }
            
            if (!isAccountFirstLogin) {
                [self showMainTabBar];
                [self showEnableTwoFactorAuthenticationIfNeeded];
            }
      
            [MEGAIndexer.sharedIndexer reindexSpotlightIfNeeded];
            
            [[MEGASdkManager sharedMEGASdk] getAccountDetails];

            if (![ContactsOnMegaManager.shared areContactsOnMegaRequestedWithinDays:7]) {
                [ContactsOnMegaManager.shared configureContactsOnMegaWithCompletion:nil];
            } else {
                [ContactsOnMegaManager.shared loadContactsOnMegaFromLocal];
            }

            break;
        }
            
        case MEGARequestTypeLogout: {            
            [Helper logout];
            [self showOnboarding];
            
            [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:nil];
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
                [MEGAStore.shareInstance updateUserWithUserHandle:user.handle nickname:request.name context:nil];
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
        [MEGASdkManager destroySharedMEGAChatSdk];
        [self.megaProviderDelegate invalidateProvider];
        self.megaProviderDelegate = nil;
        self.megaCallManager = nil;
        [self.mainTBC setBadgeValueForChats];
    }
    
    if (request.type == MEGAChatRequestTypeImportMessages) {
        MEGALogDebug(@"Imported messages %lld", request.number);
        NSManagedObjectContext *childQueueContext = MEGAStore.shareInstance.childPrivateQueueContext;
        if (childQueueContext) {
            [childQueueContext performBlock:^{
                [MEGAStore.shareInstance deleteAllMessagesWithContext:childQueueContext];
            }];
        }
    }
    
    MEGALogInfo(@"onChatRequestFinish request type: %td", request.type);
}

#pragma mark - MEGAChatDelegate

- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState {
    MEGALogInfo(@"onChatInitStateUpdate new state: %td", newState);
    self.chatLastKnownInitState = newState;
    if (newState == MEGAChatInitError) {
        [[MEGASdkManager sharedMEGAChatSdk] logout];
    }
    if (newState == MEGAChatInitOnlineSession) {
        [self copyDatabasesForExtensions];
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    MEGALogInfo(@"onChatConnectionStateUpdate: %@, new state: %d", [MEGASdk base64HandleForUserHandle:chatId], newState);
    
    if (self.chatRoom.chatId == chatId && newState == MEGAChatConnectionOnline) {
        [self performCall];
    }
    
    if (chatId == MEGAInvalidHandle && newState == MEGAChatConnectionOnline) {
        [MEGAReachabilityManager sharedManager].chatRoomListState = MEGAChatRoomListStateOnline;
    } else if (newState >= MEGAChatConnectionLogging) {
        [MEGAReachabilityManager sharedManager].chatRoomListState = MEGAChatRoomListStateInProgress;
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

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload  && !transfer.isStreamingTransfer) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        [[Helper downloadingNodes] setObject:[NSNumber numberWithInteger:transfer.tag] forKey:base64Handle];
    }
    
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

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    MEGALogDebug(@"onTransferTemporaryError %td", error.type)
    if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
        [SVProgressHUD dismiss];
        
        if (error.value) { // Bandwidth overquota error
            NSString *title = AMLocalizedString(@"depletedTransferQuota_title", @"Title shown when you almost had used your available transfer quota.");
            NSString *detail = AMLocalizedString(@"depletedTransferQuota_message", @"Description shown when you almost had used your available transfer quota.");
            UIImage *image = [UIImage imageNamed:@"transfer-quota-empty"];
            [self presentUpgradeViewControllerTitle:title detail:detail image:image];
        } else { // Storage overquota error
            NSString *title = AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
            NSString *detail = AMLocalizedString(@"Your upload(s) cannot proceed because your account is full", @"uploads over storage quota warning dialog title");
            UIImage *image = [api mnz_accountDetails].storageMax.longLongValue > [api mnz_accountDetails].storageUsed.longLongValue ? [UIImage imageNamed:@"storage_almost_full"] : [UIImage imageNamed:@"storage_full"];
            [self presentUpgradeViewControllerTitle:title detail:detail image:image];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.type != MEGATransferTypeUpload && transfer.isStreamingTransfer) {
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
        
        if ([transfer.appData containsString:@"attachToChatID"] || [transfer.appData containsString:@"attachVoiceClipToChatID"]) {
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogInfo(@"Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
        }
        
        [transfer mnz_parseSavePhotosAndSetCoordinatesAppData];
        
        if ([transfer.appData containsString:@">localIdentifier"]) {
            NSString *localIdentifier = [transfer.appData mnz_stringBetweenString:@">localIdentifier=" andString:@""];
            [[Helper uploadingNodes] removeObject:localIdentifier];
        }
        
        [Helper startPendingUploadTransferIfNeeded];
    }
    
    if (error.type) {
        switch (error.type) {
            MEGAErrorTypeApiEgoingOverquota:
            MEGAErrorTypeApiEOverQuota: {
                NSString *title = AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
                NSString *detail = AMLocalizedString(@"Your upload(s) cannot proceed because your account is full", @"uploads over storage quota warning dialog title");
                UIImage *image = [api mnz_accountDetails].storageMax.longLongValue > [api mnz_accountDetails].storageUsed.longLongValue ? [UIImage imageNamed:@"storage_almost_full"] : [UIImage imageNamed:@"storage_full"];
                [self presentUpgradeViewControllerTitle:title detail:detail image:image];
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
                break;
            }
                
            case MEGAErrorTypeApiEBusinessPastDue:
                [self presentAccountExpiredAlertIfNeeded];
                break;
                
            default: {
                if (error.type != MEGAErrorTypeApiESid && error.type != MEGAErrorTypeApiESSL && error.type != MEGAErrorTypeApiEExist && error.type != MEGAErrorTypeApiEIncomplete) {
                    NSString *transferFailed = AMLocalizedString(@"Transfer failed:", @"Notification message shown when a transfer failed. Keep colon.");
                    NSString *errorString = [MEGAError errorStringWithErrorCode:error.type context:(transfer.type == MEGATransferTypeUpload) ? MEGAErrorContextUpload : MEGAErrorContextDownload];
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@\n%@ %@", transfer.fileName, transferFailed, AMLocalizedString(errorString, nil)]];
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
    if (MEGASdkManager.sharedMEGAChatSdk.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
}

@end
