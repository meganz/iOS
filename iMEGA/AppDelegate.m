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
#import "MEGA-Swift.h"
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
#import "InitialLaunchViewController.h"
#import "LaunchViewController.h"
#import "MainTabBarController.h"
#import "MEGAAssetsPickerController.h"
#import "OnboardingViewController.h"
#import "ProductDetailViewController.h"
#import "UpgradeTableViewController.h"

#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGAChatNotificationDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGALocalNotificationManager.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAShowPasswordReminderRequestDelegate.h"
#import "CameraUploadManager+Settings.h"
#import "TransferSessionManager.h"
#import "MEGAConstants.h"
#import "BackgroundRefreshPerformer.h"

#define kFirstRun @"FirstRun"

@interface AppDelegate () <PKPushRegistryDelegate, UIApplicationDelegate, UNUserNotificationCenterDelegate, LTHPasscodeViewControllerDelegate, LaunchViewControllerDelegate, MEGAApplicationDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, MEGAGlobalDelegate, MEGAPurchasePricingDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
    
    BOOL isFirstFetchNodesRequestUpdate;
    NSTimer *timerAPI_EAGAIN;
}

@property (nonatomic, strong) UIView *privacyView;

@property (nonatomic, strong) NSString *quickActionType;
@property (nonatomic, strong) NSString *messageForSuspendedAccount;

@property (nonatomic, strong) UIAlertController *API_ESIDAlertController;

@property (nonatomic, weak) MainTabBarController *mainTBC;

@property (nonatomic, getter=isSignalActivityRequired) BOOL signalActivityRequired;

@property (nonatomic) MEGAIndexer *indexer;

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

@property (strong, nonatomic) dispatch_queue_t indexSerialQueue;
@property (strong, nonatomic) BackgroundRefreshPerformer *backgroundRefreshPerformer;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
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
    
    self.indexSerialQueue = dispatch_queue_create("nz.mega.spotlight.nodesIndexing", DISPATCH_QUEUE_SERIAL);
    
    [CameraUploadManager.shared setupCameraUploadWhenApplicationLaunches];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self migrateLocalCachesLocation];
    
    if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        _megatype = [[[launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"] objectForKey:@"megatype"] unsignedIntegerValue];
    }
    
    _signalActivityRequired = NO;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    [MEGAReachabilityManager sharedManager];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pointToStaging"]) {
        [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
        [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
    }
    
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
    
    NSString *sessionV3 = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    
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
    
    [MEGALinkManager resetLinkAndURLType];
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
            }
        }
        
        if ([sharedUserDefaults boolForKey:@"useHttpsOnly"]) {
            [[MEGASdkManager sharedMEGASdk] useHttpsOnly:YES];
        }
    } else {
        // Resume ephemeral account
        self.window.rootViewController = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault];
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
    
    [self.window makeKeyAndVisible];
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
    
    [self beginBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:YES];
    [[MEGASdkManager sharedMEGAChatSdk] saveCurrentState];

    BOOL pendingTasks = [[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] > 0 || [[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] > 0;
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
    
    if (UIApplication.sharedApplication.windows.count > 0 && ![NSStringFromClass(UIApplication.sharedApplication.windows.firstObject.class) isEqualToString:@"UIWindow"]) {
        [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application will enter foreground");
    
    MEGAHandleList *chatRoomIDsWithCallInProgress = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusInProgress];
    MEGAHandleList *chatRoomIDsWithCallRequestSent = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusRequestSent];
    if (self.wasAppSuspended && (chatRoomIDsWithCallInProgress.size == 0) && (chatRoomIDsWithCallRequestSent.size == 0)) {
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
    [center removeAllDeliveredNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    MEGALogDebug(@"[App Lifecycle] Application did become active");
    
    if (self.isSignalActivityRequired) {
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
                            UIViewController *presentedVC = UIApplication.mnz_presentingViewController;
                            if ([presentedVC isKindOfClass:CallViewController.class]) {
                                CallViewController *callVC = (CallViewController *)UIApplication.mnz_presentingViewController;
                                if (!callVC.videoCall) {
                                    [callVC tapOnVideoCallkitWhenDeviceIsLocked];
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
            } if (personHandle.type == INPersonHandleTypeUnknown) {
                uint64_t handle = [MEGASdk handleForBase64UserHandle:personHandle.value];
                MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:handle];
                self.videoCall = [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"];

                if (call && call.status == MEGAChatCallStatusInProgress) {
                    self.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:call.chatId];
                    MEGALogDebug(@"call id %tu", call.callId);
                    MEGALogDebug(@"There is a call in progress for this chat %@", call);
                    UIViewController *presentedVC = UIApplication.mnz_presentingViewController;
                    if ([presentedVC isKindOfClass:GroupCallViewController.class]) {
                        GroupCallViewController *callVC = (GroupCallViewController *)presentedVC;
                        callVC.callType = CallTypeActive;
                        if (!callVC.videoCall) {
                            [callVC tapOnVideoCallkitWhenDeviceIsLocked];
                        }
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
    [UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]].textColor = UIColor.mnz_black333333;
    [UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]].font = [UIFont mnz_SFUIRegularWithSize:17.0f];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:13.0f]} forState:UIControlStateNormal];
    
    UISwitch.appearance.onTintColor = UIColor.mnz_green00BFA5;
    
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
        if (![LTHPasscodeViewController doesPasscodeExist] && isFetchNodesDone) {
            [self showLink:url];
        }
    } else {
        [self showLink:url];
    }
}

- (void)showLink:(NSURL *)url {
    if (!MEGALinkManager.linkURL) return;
    
    [self dismissPresentedViewsAndDo:^{
        [MEGALinkManager processLinkURL:url];
    }];
}

- (void)dismissPresentedViewsAndDo:(void (^)(void))completion {
    if (self.window.rootViewController.presentedViewController) {
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
            if (completion) completion();
        }];
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
    
    if (isAccountFirstLogin) {
        [self registerForVoIPNotifications];
        [self registerForNotifications];
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
    if (self.chatRoom.isGroup) {
        GroupCallViewController *groupCallVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupCallViewControllerID"];
        groupCallVC.callType = CallTypeOutgoing;
        groupCallVC.videoCall = self.videoCall;
        groupCallVC.chatRoom = self.chatRoom;
        groupCallVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if (@available(iOS 10.0, *)) {
            groupCallVC.megaCallManager = [self.mainTBC megaCallManager];
        }
        [self.mainTBC presentViewController:groupCallVC animated:YES completion:nil];
    } else {
        CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
        callVC.chatRoom = self.chatRoom;
        callVC.videoCall = self.videoCall;
        callVC.callType = CallTypeOutgoing;
        if (@available(iOS 10.0, *)) {
            callVC.megaCallManager = [self.mainTBC megaCallManager];
        }
        [self.mainTBC presentViewController:callVC animated:YES completion:nil];
    }
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
    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
    upgradeTVC.chooseAccountType = YES;
    
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)presentUpgradeViewControllerTitle:(NSString *)title detail:(NSString *)detail image:(UIImage *)image {
    if (!self.isUpgradeVCPresented && ![UIApplication.mnz_visibleViewController isKindOfClass:UpgradeTableViewController.class] && ![UIApplication.mnz_visibleViewController isKindOfClass:ProductDetailViewController.class]) {
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
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
                    UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
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
                AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
                achievementsVC.enableCloseBarButton = YES;
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
                [UIApplication.mnz_presentingViewController presentViewController:navigation animated:YES completion:nil];
            }];
        };
        
        self.upgradeVCPresented = YES;
        [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
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
    MEGALogDebug(@"Did receive incoming push with payload: %@", [payload dictionaryPayload]);
    
    // Call
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground && [[[payload dictionaryPayload] objectForKey:@"megatype"] integerValue] == 4) {
        [self beginBackgroundTaskWithName:@"VoIP"];
        
        if (!DevicePermissionsHelper.shouldAskForNotificationsPermissions) {
            [DevicePermissionsHelper notificationsPermissionWithCompletionHandler:^(BOOL granted) {
                if (@available(iOS 10.0, *)) {
                    if (granted && !DevicePermissionsHelper.shouldAskForAudioPermissions) {
                        [DevicePermissionsHelper audioPermissionModal:NO forIncomingCall:YES withCompletionHandler:^(BOOL granted) {
                            if (!granted) {
                                UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                                content.body = AMLocalizedString(@"Incoming call", @"notification subtitle of incoming calls");
                                content.sound = [UNNotificationSound soundNamed:@"incoming_voice_video_call_iOS9.mp3"];
                                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                                NSString *identifier = @"Incoming call";
                                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                                      content:content
                                                                                                      trigger:trigger];
                                [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:nil];
                            }
                        }];
                    }
                }
            }];
        }
    }
    
    // Message
    if ([[[payload dictionaryPayload] objectForKey:@"megatype"] integerValue] == 2) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"VoIP_messages"];
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
    
    [self.mainTBC openChatRoomNumber:response.notification.request.content.userInfo[@"chatId"]];
    
    completionHandler();
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (@available(iOS 10, *)) {} else {
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
            [self.mainTBC openChatRoomNumber:notification.userInfo[@"chatId"]];
        }
    }
}

#pragma mark - LaunchViewControllerDelegate

- (void)setupFinished {
    [self showMainTabBar];
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
        [Helper startPendingUploadTransferIfNeeded];
    } else {
        dispatch_async(self.indexSerialQueue, ^{
            NSArray<MEGANode *> *nodesToIndex = [nodeList mnz_nodesArrayFromNodeList];
            MEGALogDebug(@"Spotlight indexing %tu nodes updated", nodesToIndex.count);
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
            } else {
                static BOOL alreadyPresented = NO;
                if (!alreadyPresented && (event.number == StorageStateRed || event.number == StorageStateOrange)) {
                    NSString *detail = event.number == StorageStateOrange ? AMLocalizedString(@"cloudDriveIsAlmostFull", @"Informs the user that they’ve almost reached the full capacity of their Cloud Drive for a Free account. Please leave the [S], [/S], [A], [/A] placeholders as they are.") : AMLocalizedString(@"cloudDriveIsFull", @"A message informing the user that they've reached the full capacity of their accounts. Please leave [S], [/S] as it is which is used to bolden the text.");
                    detail = [detail mnz_removeWebclientFormatters];
                    NSString *maxStorage = [NSString stringWithFormat:@"%ld", (long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:7]];
                    NSString *maxStorageTB = [NSString stringWithFormat:@"%ld", (long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:7] / 1024];
                    detail = [detail stringByReplacingOccurrencesOfString:@"4096" withString:maxStorage];
                    detail = [detail stringByReplacingOccurrencesOfString:@"4" withString:maxStorageTB];
                    alreadyPresented = YES;
                    NSString *title = AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
                    UIImage *image = event.number == StorageStateOrange ? [UIImage imageNamed:@"storage_almost_full"] : [UIImage imageNamed:@"storage_full"];
                    [self presentUpgradeViewControllerTitle:title detail:detail image:image];
                }
            }
        }
            
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
                self.newAccount = (MEGALinkManager.urlType == URLTypeConfirmationLink);
                if (MEGALinkManager.selectedOption != LinkOptionJoinChatLink) {
                    [MEGALinkManager resetLinkAndURLType];
                }
            }
                        
            [self registerForVoIPNotifications];
            [self registerForNotifications];
            [[MEGASdkManager sharedMEGASdk] fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:[MEGAPurchase sharedInstance]];
            [[MEGASdkManager sharedMEGASdk] enableTransferResumption];
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
            
            if (!isAccountFirstLogin) {
                [self showMainTabBar];
            }
            
            NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
            dispatch_async(self.indexSerialQueue, ^{
                if (![sharedUserDefaults boolForKey:@"treeCompleted"]) {
                    [self.indexer generateAndSaveTree];
                }
                @try {
                    [self.indexer indexTree];
                } @catch (NSException *exception) {
                    MEGALogError(@"Exception during spotlight indexing: %@", exception);
                }
            });
            
            [[MEGASdkManager sharedMEGASdk] getAccountDetails];
            [self copyDatabasesForExtensions];
            [[NSUserDefaults standardUserDefaults] setBool:[api appleVoipPushEnabled] forKey:@"VoIP_messages"];
            
            [ContactsOnMegaManager.shared configureContactsOnMegaWithCompletion:nil];

            break;
        }
            
        case MEGARequestTypeLogout: {            
            [Helper logout];
            [self showOnboarding];
            
            [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:nil];
            
            if (self.messageForSuspendedAccount) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:self.messageForSuspendedAccount preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeAccountDetails:
            [[MEGASdkManager sharedMEGASdk] mnz_setAccountDetails:[request megaAccountDetails]];
            break;
            
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
                        [[MEGAStore shareInstance] insertUserWithUserHandle:[MEGASdk handleForBase64UserHandle:request.email] firstname:request.text lastname:nil email:request.email];
                    }
                    
                    if (request.paramType == MEGAUserAttributeLastname) {
                        [[MEGAStore shareInstance] insertUserWithUserHandle:[MEGASdk handleForBase64UserHandle:request.email] firstname:nil lastname:request.text email:request.email];
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
    if (request.type == MEGAChatRequestTypeSetBackgroundStatus && request.flag) {
        [self endBackgroundTaskWithName:@"Chat-Request-SET_BACKGROUND_STATUS=YES"];
    }
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
        
        if ([transfer.appData containsString:@"attachToChatID"] || [transfer.appData containsString:@"attachVoiceClipToChatID"]) {
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogInfo(@"Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
        }
        
        [transfer mnz_parseAppData];
        
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
    if (self.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
}

@end
