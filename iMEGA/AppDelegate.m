#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <Intents/Intents.h>
#import <Photos/Photos.h>
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>

#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "CameraUploads.h"
#import "Helper.h"
#import "DevicePermissionsHelper.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAIndexer.h"
#import "MEGALogger.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPurchase.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "BrowserViewController.h"
#import "CallViewController.h"
#import "CameraUploadsPopUpViewController.h"
#import "ChangePasswordViewController.h"
#import "ChatRoomsViewController.h"
#import "CheckEmailAndFollowTheLinkViewController.h"
#import "CloudDriveTableViewController.h"
#import "ConfirmAccountViewController.h"
#import "ContactRequestsViewController.h"
#import "ContactsViewController.h"
#import "CreateAccountViewController.h"
#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "LaunchViewController.h"
#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "MessagesViewController.h"
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAPasswordLinkRequestDelegate.h"
#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MyAccountHallViewController.h"
#import "OfflineTableViewController.h"
#import "SecurityOptionsTableViewController.h"
#import "SettingsTableViewController.h"
#import "SharedItemsViewController.h"
#import "UnavailableLinkView.h"
#import "UpgradeTableViewController.h"
#import "CustomModalAlertViewController.h"

#define kUserAgent @"MEGAiOS"
#define kAppKey @"EVtjzb7R"

#define kFirstRun @"FirstRun"

typedef NS_ENUM(NSUInteger, URLType) {
    URLTypeDefault,
    URLTypeFileLink,
    URLTypeFolderLink,
    URLTypeEncryptedLink,
    URLTypeConfirmationLink,
    URLTypeOpenInLink,
    URLTypeNewSignUpLink,
    URLTypeBackupLink,
    URLTypeIncomingPendingContactsLink,
    URLTypeChangeEmailLink,
    URLTypeCancelAccountLink,
    URLTypeRecoverLink,
    URLTypeChatLink,
    URLTypeLoginRequiredLink,
    URLTypeHandleLink
};

@interface AppDelegate () <UIAlertViewDelegate, UNUserNotificationCenterDelegate, LTHPasscodeViewControllerDelegate, PKPushRegistryDelegate, MEGAPurchasePricingDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
    
    UIAlertView *overquotaAlertView;
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


@property (nonatomic, strong) UIAlertView *API_ESIDAlertView;

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

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
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
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [[MEGASdkManager sharedMEGASdk] httpServerSetMaxBufferSize:[UIDevice currentDevice].maxBufferSize];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];
    
    [self languageCompatibility];
    
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
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
                [MEGASdkManager createSharedMEGAChatSdk];
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
            }
            
            [[MEGALogger sharedLogger] enableChatlogs];
            
            MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:sessionV3];
            if (chatInit == MEGAChatInitError) {
                MEGALogError(@"Init Karere with session failed");
                NSString *message = [NSString stringWithFormat:@"Error (%ld) initializing the chat", (long)chatInit];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [[MEGASdkManager sharedMEGAChatSdk] logout];
                [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
            }
        } else {
            [[MEGALogger sharedLogger] enableSDKlogs];
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
                                                                         withLogout:YES
                                                                     andLogoutTitle:AMLocalizedString(@"logoutLabel", nil)];
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
        if (sessionId) {
            MEGACreateAccountRequestDelegate *createAccountRequestDelegate = [[MEGACreateAccountRequestDelegate alloc] initWithCompletion:^ (MEGAError *error) {
                CheckEmailAndFollowTheLinkViewController *checkEmailAndFollowTheLinkVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CheckEmailAndFollowTheLinkViewControllerID"];
                [self.window.rootViewController presentViewController:checkEmailAndFollowTheLinkVC animated:YES completion:nil];
            }];
            createAccountRequestDelegate.resumeCreateAccount = YES;
            [[MEGASdkManager sharedMEGASdk] resumeCreateAccountWithSessionId:sessionId delegate:createAccountRequestDelegate];
        }
    }
    
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied && [[CameraUploads syncManager] isCameraUploadsEnabled]) {
        MEGALogInfo(@"Disable Camera Uploads");
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
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
    
    MEGALogDebug(@"Application did finish launching with options %@", launchOptions);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    MEGALogDebug(@"Application will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    MEGALogDebug(@"Application did enter background");
    
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:YES];
    [[MEGASdkManager sharedMEGAChatSdk] saveCurrentState];

    BOOL pendingTasks = [[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] > 0 || [[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] > 0 || [[[CameraUploads syncManager] assetsOperationQueue] operationCount] > 0;
    if (pendingTasks) {
        [self startBackgroundTask];
    }
    
    if (self.privacyView == nil) {
        UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
        self.privacyView = privacyVC.view;
    }
    [self.window addSubview:self.privacyView];
    
    [self application:application shouldHideWindows:YES];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    MEGALogDebug(@"Application will enter foreground");
    
    [[MEGAReachabilityManager sharedManager] reconnectIfIPHasChanged];
    [[MEGASdkManager sharedMEGAChatSdk] setBackgroundStatus:NO];
    
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] && [[CameraUploads syncManager] isCameraUploadsEnabled]) {        
        MEGALogInfo(@"Enable Camera Uploads");
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
    }
    
    [self.privacyView removeFromSuperview];
    self.privacyView = nil;
    
    [self application:application shouldHideWindows:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    MEGALogDebug(@"Application did become active");
    
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    if (self.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    MEGALogDebug(@"Application will terminate");
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[MEGAPurchase sharedInstance]];
    
    if (![SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [Helper logout];
    }
    
    if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] == 0) {
        [self removeUnfinishedTransfersOnFolder:[Helper pathForOffline]];
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:[[NSFileManager defaultManager] downloadsDirectory] error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
        
        if (![[NSFileManager defaultManager] removeItemAtPath:[[NSFileManager defaultManager] uploadsDirectory] error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    MEGALogDebug(@"Application open URL %@, source application %@", url, sourceApplication);
    self.link = url;
    
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        if (![LTHPasscodeViewController doesPasscodeExist] && isFetchNodesDone) {
            [self processLink:self.link];
        }
    } else {
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            [self processLink:self.link];
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    MEGALogDebug(@"Application did register user notification settings");
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if([deviceToken length] == 0) {
        MEGALogError(@"Application did register for remote notifications with device token length 0");
        return;
    }
    
    const unsigned char *dataBuffer = (const unsigned char *)deviceToken.bytes;
    
    NSUInteger dataLength = deviceToken.length;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    NSString *deviceTokenString = [NSString stringWithString:hexString];
    MEGALogDebug(@"Application did register for remote notifications with device token %@", deviceTokenString);
    [[MEGASdkManager sharedMEGASdk] registeriOSdeviceToken:deviceTokenString];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    MEGALogError(@"Application did fail to register for remote notifications with error %@", error);
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    MEGALogDebug(@"Application continue user activity %@", userActivity.activityType);
    
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
                                                [[UIApplication mnz_visibleViewController] presentViewController:[DevicePermissionsHelper videoPermisionAlertController] animated:YES completion:nil];
                                            }
                                        }];
                                    } else {
                                        [self performCall];
                                    }
                                } else {
                                    [[UIApplication mnz_visibleViewController] presentViewController:[DevicePermissionsHelper audioPermisionAlertController] animated:YES completion:nil];
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
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    MEGALogDebug(@"Application perform action for shortcut item");
    
    if (isFetchNodesDone) {
        completionHandler([self manageQuickActionType:shortcutItem.type]);
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    MEGALogWarning(@"Application did receive memory warning");
    
    [self.indexer stopIndexing];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    MEGALogDebug(@"Application did receive remote notification");
    
    if (application.applicationState == UIApplicationStateInactive) {
        _megatype = [[userInfo objectForKey:@"megatype"] unsignedIntegerValue];
        [self openTabBasedOnNotificationMegatype];
    }
}

#pragma mark - Private

- (void)setupAppearance {    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]}];
    [[UINavigationBar appearance] setTintColor:[UIColor mnz_redD90007]];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor mnz_grayF9F9F9]];
    
    if (@available(iOS 10.0, *)) {
        [[UINavigationBar appearance] setShadowImage:[UIImage mnz_navigationBarShadow]];
        [[UINavigationBar appearance] setBackgroundImage:[UIImage mnz_navigationBarBackground] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsCompact];
    }
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:13.0f]} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"backArrow"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"backArrow"]];
    [UIBarButtonItem appearance].tintColor = [UIColor mnz_redD90007];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:8.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:8.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateSelected];
    
    [[UITextField appearance] setTintColor:[UIColor mnz_redD90007]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setBackgroundColor:[UIColor mnz_grayF9F9F9]];
    
    [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setTintColor:[UIColor mnz_redD90007]];
    
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

- (void)startBackgroundTask {
    MEGALogDebug(@"Start background task");
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)showCameraUploadsPopUp {
    MEGANavigationController *cameraUploadsNavigationController =[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsPopUpNavigationControllerID"];
    
    [self.window.rootViewController presentViewController:cameraUploadsNavigationController animated:YES completion:^{
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
            [self.window.rootViewController.presentedViewController presentViewController:navigationController animated:YES completion:nil];
            
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
            [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:NO];
            break;
        }
            
        case 3: { //Import folder or nodes from link
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
            browserVC.selectedNodesArray = [NSArray arrayWithArray:[Helper nodesFromLinkMutableArray]];
            [self presentLinkViewController:navigationController];
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
                [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:YES];
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

- (void)processLink:(NSURL *)url {
    NSString *afterSlashesString = [[url absoluteString] substringFromIndex:7]; // "mega://" = 7 characters
        
    if (afterSlashesString.length < 2) {
        [self showLinkNotValid];
        return;
    }
        
    [self dismissPresentedViews];
    
    if ([[url absoluteString] rangeOfString:@"file:///"].location != NSNotFound) {
        self.urlType = URLTypeOpenInLink;
        [self openIn];
        return;
    }
        
    if ([self isFileLink:afterSlashesString]) {
        self.urlType = URLTypeFileLink;
        return;
    }
    
    if ([self isFolderLink:afterSlashesString]) {
        self.urlType = URLTypeFolderLink;
        return;
    }
    
    if ([self isEncryptedLink:afterSlashesString]) {
        self.urlType = URLTypeEncryptedLink;
        return;
    }
    
    if ([self isConfirmationLink:afterSlashesString]) {
        self.urlType = URLTypeConfirmationLink;
        return;
    }
    
    if ([self isNewSignUpLink:afterSlashesString]) {
        self.urlType = URLTypeNewSignUpLink;
        return;
    }
    
    if ([self isBackupLink:afterSlashesString]) {
        self.urlType = URLTypeBackupLink;
        return;
    }
    
    if ([self isIncomingPendingContactsLink:afterSlashesString]) {
        self.urlType = URLTypeIncomingPendingContactsLink;
        return;
    }
    
    if ([self isChangeEmailLink:afterSlashesString]) {
        self.urlType = URLTypeChangeEmailLink;
        return;
    }
    
    if ([self isCancelAccountLink:afterSlashesString]) {
        self.urlType = URLTypeCancelAccountLink;
        return;
    }
    
    if ([self isRecoverLink:afterSlashesString]) {
        self.urlType = URLTypeRecoverLink;
        return;
    }
    
    if ([self isChatLink:afterSlashesString]) {
        self.urlType = URLTypeChatLink;
        return;
    }
    
    if ([self isLoginRequiredLink:afterSlashesString]) {
        self.urlType = URLTypeLoginRequiredLink;
        return;
    }
    
    if ([self isHandleLink:afterSlashesString]) {
        self.urlType = URLTypeHandleLink;
        return;
    }
    
    [self showLinkNotValid];
}

- (void)dismissPresentedViews {
    if (self.window.rootViewController.presentedViewController != nil) {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)isFileLink:(NSString *)afterSlashesString {
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:2]; // mega://"#!"
    BOOL isFileLink = [megaURLTypeString isEqualToString:@"#!"];
    if (isFileLink) {
        NSString *fileLinkString = @"https://mega.nz/";
        fileLinkString = [fileLinkString stringByAppendingString:afterSlashesString];
        [self showFileLinkView:fileLinkString];
        return YES;
    }
    return NO;
}

- (void)showFileLinkView:(NSString *)fileLinkURLString {
    MEGANavigationController *fileLinkNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkNavigationControllerID"];
    FileLinkViewController *fileLinkVC = fileLinkNavigationController.viewControllers.firstObject;
    [fileLinkVC setFileLinkString:fileLinkURLString];
    
    [self presentLinkViewController:fileLinkNavigationController];
    
    self.link = nil;
}

- (BOOL)isFolderLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 3) {
        return NO;
    }
    
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:3]; // mega://"#F!"
    BOOL isFolderLink = [megaURLTypeString isEqualToString:@"#F!"];
    if (isFolderLink) {
        NSString *folderLinkString = @"https://mega.nz/";
        folderLinkString = [folderLinkString stringByAppendingString:afterSlashesString];
        [self showFolderLinkView:folderLinkString];
        return YES;
    }
    return NO;
}

- (void)showFolderLinkView:(NSString *)folderLinkURLString {
    MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
    
    FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
    
    [folderlinkVC setIsFolderRootNode:YES];
    [folderlinkVC setFolderLinkString:folderLinkURLString];
    
    [self presentLinkViewController:folderNavigationController];
    
    self.link = nil;
}

- (BOOL)isEncryptedLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 3) {
        return NO;
    }
    
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:3]; // mega://"#P!"
    BOOL isEncryptedLink = [megaURLTypeString isEqualToString:@"#P!"];
    if (isEncryptedLink) {
        NSString *encryptedLinkString = @"https://mega.nz/";
        encryptedLinkString = [encryptedLinkString stringByAppendingString:afterSlashesString];
        [self showEncryptedLinkAlert:encryptedLinkString];
        return YES;
    }
    return NO;
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
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", nil) message:AMLocalizedString(@"decryptionKeyAlertMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = AMLocalizedString(@"decryptionKey", nil);
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[MEGASdkManager sharedMEGASdk] decryptPasswordProtectedLink:encryptedLinkURLString password:alertController.textFields.firstObject.text delegate:delegate];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    
    self.link = nil;
}

- (void)presentLinkViewController:(UINavigationController *)navigationController {
    if ([self.window.rootViewController.presentedViewController isKindOfClass:[MEGANavigationController class]]) {
        MEGANavigationController *cameraUploadsPopUpNavigationController = (MEGANavigationController *)self.window.rootViewController.presentedViewController;
        if ([cameraUploadsPopUpNavigationController.topViewController isKindOfClass:[CameraUploadsPopUpViewController class]]) {
            [cameraUploadsPopUpNavigationController.topViewController presentViewController:navigationController animated:YES completion:nil];
        } else {
            [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
        }
    } else {
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (BOOL)isConfirmationLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 8) {
        return NO;
    }
    
    NSString *megaURLString = @"https://mega.nz/";
    BOOL isMEGACONZConfirmationLink = [[afterSlashesString substringToIndex:7] isEqualToString:@"confirm"]; // mega://"confirm"
    BOOL isMEGANZConfirmationLink = [[afterSlashesString substringToIndex:8] isEqualToString:@"#confirm"]; // mega://"#confirm"
    if (isMEGACONZConfirmationLink) {
        NSString *megaURLConfirmationString = [megaURLString stringByAppendingString:@"#"];
        megaURLConfirmationString = [megaURLConfirmationString stringByAppendingString:afterSlashesString];
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLConfirmationString];
        self.link = nil;
        return YES;
    } else if (isMEGANZConfirmationLink) {
        NSString *megaURLConfirmationString = [megaURLString stringByAppendingString:afterSlashesString];
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLConfirmationString];
        self.link = nil;
        return YES;
    }
    return NO;
}

- (BOOL)isNewSignUpLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 10) {
        return NO;
    }
    
    BOOL isNewSignUpLink = [[afterSlashesString substringToIndex:10] isEqualToString:@"#newsignup"]; // mega://"#newsignup"
    if (isNewSignUpLink) {
        NSString *megaURLString = @"https://mega.nz/";
        megaURLString = [megaURLString stringByAppendingString:afterSlashesString];
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLString];
        return YES;
    }
    return NO;
}

- (BOOL)isBackupLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 7) {
        return NO;
    }
    
    BOOL isBackupLink = [[afterSlashesString substringToIndex:7] isEqualToString:@"#backup"]; //mega://"#backup"
    if (isBackupLink) {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            SecurityOptionsTableViewController *securityOptionsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"SecurityOptionsTableViewControllerID"];
            [securityOptionsTVC.navigationItem setRightBarButtonItem:[self cancelBarButtonItem]];
            MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:securityOptionsTVC];
            [self presentLinkViewController:navigationController];
        } else {
            [self showPleaseLogInToYourAccountAlert];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)isIncomingPendingContactsLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 7) {
        return NO;
    }
    
    BOOL isIncomingPendingContactsLink = [[afterSlashesString substringToIndex:7] isEqualToString:@"#fm/ipc"]; //mega://"#fm/ipc"
    if (isIncomingPendingContactsLink) {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            ContactRequestsViewController *contactsRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
            MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:contactsRequestsVC];
            [self presentLinkViewController:navigationController];
        } else {
            [self showPleaseLogInToYourAccountAlert];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)isChangeEmailLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 7) {
        return NO;
    }
    
    BOOL isChangeEmailLink = [[afterSlashesString substringToIndex:7] isEqualToString:@"#verify"]; //mega://"#verify"
    if (isChangeEmailLink) {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            NSString *megaURLString = [@"https://mega.nz/" stringByAppendingString:afterSlashesString];
            [[MEGASdkManager sharedMEGASdk] queryChangeEmailLink:megaURLString];
        } else {
            [self showPleaseLogInToYourAccountAlert];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)isCancelAccountLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 7) {
        return NO;
    }
    
    BOOL isCancelAccountLink = [[afterSlashesString substringToIndex:7] isEqualToString:@"#cancel"]; //mega://"#cancel"
    if (isCancelAccountLink) {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            NSString *megaURLString = [@"https://mega.nz/" stringByAppendingString:afterSlashesString];
            [[MEGASdkManager sharedMEGASdk] queryCancelLink:megaURLString];
        } else {
            [self showPleaseLogInToYourAccountAlert];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)isRecoverLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 8) {
        return NO;
    }
    
    BOOL isRecoverLink = [[afterSlashesString substringToIndex:8] isEqualToString:@"#recover"]; //mega://"#recover"
    if (isRecoverLink) {
        NSString *megaURLString = [@"https://mega.nz/" stringByAppendingString:afterSlashesString];
        [[MEGASdkManager sharedMEGASdk] queryResetPasswordLink:megaURLString];
        return YES;
    }
    
    return NO;
}

- (BOOL)isChatLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 8) {
        return NO;
    }
    
    BOOL isChatLink = [[afterSlashesString substringToIndex:8] isEqualToString:@"#fm/chat"]; //mega://"#fm/chat"
    if (isChatLink) {
        self.mainTBC.selectedIndex = CHAT;
    }
    return isChatLink;
}

- (BOOL)isLoginRequiredLink:(NSString *)afterSlashesString {
    if (afterSlashesString.length < 14) {
        return NO;
    }
    
    BOOL isLoginRequiredLink = [[afterSlashesString substringToIndex:14] isEqualToString:@"#loginrequired"]; //mega://"#loginrequired"
    if (isLoginRequiredLink) {
        NSString *session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
        if (session) {
            // The user logged in with a previous version of the MEGA app, so the session is stored in the standard
            // keychain. The session must be stored again so that it will be available for the shared keychain.
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
            [SAMKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
        } else {
            // The user is not logged in, so the standard login will be presented (there is nothing to do in this case)
        }
    }
    return isLoginRequiredLink;
}

- (BOOL)isHandleLink:(NSString *)afterSlashesString {
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:1]; // mega://"#"
    BOOL hasHash = [megaURLTypeString isEqualToString:@"#"];
    if (hasHash) {
        self.nodeToPresentBase64Handle = [afterSlashesString substringFromIndex:1];
        [self presentNode];
        
        return YES;
    }
    
    return NO;
}

- (void)openIn {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        MEGANavigationController *browserNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = browserNavigationController.viewControllers.firstObject;
        [browserVC setLocalpath:[self.link path]]; // "file://" = 7 characters
        [browserVC setBrowserAction:BrowserActionOpenIn];
        
        [self presentLinkViewController:browserNavigationController];
        
        self.link = nil;
    }
}

- (BOOL)manageQuickActionType:(NSString *)type {
    BOOL quickActionManaged = YES;
    if ([type isEqualToString:@"mega.ios.search"]) {
        self.mainTBC.selectedIndex = CLOUD;
        MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:CLOUD];
        CloudDriveTableViewController *cloudDriveTVC = navigationController.viewControllers.firstObject;
        if (self.quickActionType) { //Coming from didFinishLaunchingWithOptions
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                [cloudDriveTVC activateSearch]; // Cloud Drive already presented, so activate search bar
            } else {
                cloudDriveTVC.homeQuickActionSearch = YES; //Search will become active after the Cloud Drive did appear
            }
        } else {
            [cloudDriveTVC activateSearch];
        }
    } else if ([type isEqualToString:@"mega.ios.upload"]) {
        self.mainTBC.selectedIndex = CLOUD;
        MEGANavigationController *navigationController = [self.mainTBC.childViewControllers objectAtIndex:CLOUD];
        CloudDriveTableViewController *cloudDriveTVC = navigationController.viewControllers.firstObject;
        [cloudDriveTVC presentUploadAlertController];
    } else if ([type isEqualToString:@"mega.ios.offline"]) {
        [self showOffline];
    } else {
        quickActionManaged = NO;
    }
    
    self.quickActionType = nil;
    
    return quickActionManaged;
}

- (void)removeUnfinishedTransfersOnFolder:(NSString *)directory {
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[directory stringByAppendingPathComponent:item] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [self removeUnfinishedTransfersOnFolder:[directory stringByAppendingPathComponent:item]];
        } else {
            if ([item.pathExtension.lowercaseString isEqualToString:@"mega"]) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:item] error:&error]) {
                    MEGALogError(@"Remove item at path failed with error: %@", error);
                }
            }
        }
    }
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
    
    if (!overquotaAlertView.visible) {
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
    [self showEmptyStateViewWithImageNamed:@"noInternetConnection" title:AMLocalizedString(@"linkNotValid", nil) text:@""];
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
    [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

- (UIBarButtonItem *)cancelBarButtonItem {
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:nil action:@selector(dismissPresentedViews)];
    [cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
    return cancelBarButtonItem;
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    } else {
        MEGALogError(@"Save video to Camera roll: %@ (Domain: %@ - Code:%ld)", error.localizedDescription, error.domain, error.code);
    }
}

- (void)showPleaseLogInToYourAccountAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"pleaseLogInToYourAccount", nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)presentConfirmViewControllerType:(ConfirmType)confirmType link:(NSString *)link email:(NSString *)email {
    MEGANavigationController *confirmAccountNavigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ConfirmAccountNavigationControllerID"];
    
    ConfirmAccountViewController *confirmAccountVC = confirmAccountNavigationController.viewControllers.firstObject;
    confirmAccountVC.confirmType = confirmType;
    confirmAccountVC.confirmationLinkString = link;
    confirmAccountVC.emailString = email;
    
    [self presentLinkViewController:confirmAccountNavigationController];
}

- (void)presentChangeViewType:(ChangeType)changeType email:(NSString *)email masterKey:(NSString *)masterKey link:(NSString *)link {
    ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
    changePasswordVC.changeType = changeType;
    changePasswordVC.email = email;
    changePasswordVC.masterKey = masterKey;
    changePasswordVC.link = link;
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:changePasswordVC];
    [self presentLinkViewController:navigationController];
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
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                         withLogout:YES
                                                                     andLogoutTitle:AMLocalizedString(@"logoutLabel", nil)];
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
                    
                    [self.window.rootViewController presentViewController:warningAlertController animated:YES completion:nil];
                } else {
                    [[MEGASdkManager sharedMEGASdk] logout];
                }
            }]];
            
            [self.window.rootViewController presentViewController:theContentIsNotAvailableAlertController animated:YES completion:nil];
        }
    }
    self.nodeToPresentBase64Handle = nil;
}

- (void)presentNode:(MEGANode *)node inNavigationController:(UINavigationController *)navigationController {
    NSMutableArray *nodes = [[NSMutableArray alloc] init];
    
    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) { // node from inshare
        MEGANode *tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.parentHandle];
        while (tempNode != nil) {
            [nodes insertObject:tempNode atIndex:0];
            tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:tempNode.parentHandle];
        }
    } else {
        uint64_t rootHandle;
        if ([[[MEGASdkManager sharedMEGASdk] nodePathForNode:node] hasPrefix:@"//bin"]) {
            rootHandle = [[MEGASdkManager sharedMEGASdk] rubbishNode].parentHandle;
        } else {
            rootHandle = [[MEGASdkManager sharedMEGASdk] rootNode].handle;
        }
        uint64_t tempHandle = node.parentHandle;
        while (tempHandle != rootHandle) {
            MEGANode *tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:tempHandle];
            if (tempNode) {
                [nodes insertObject:tempNode atIndex:0];
                tempHandle = tempNode.parentHandle;
            } else {
                break;
            }
        }
    }
    
    [navigationController popToRootViewControllerAnimated:NO];
    
    for (MEGANode *node in nodes) {
        CloudDriveTableViewController *cloudDriveTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        [cloudDriveTVC setParentNode:node];
        [navigationController pushViewController:cloudDriveTVC animated:NO];
    }
    
    switch ([node type]) {
        case MEGANodeTypeFolder:
        case MEGANodeTypeRubbish: {
            CloudDriveTableViewController *cloudDriveTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveTVC.parentNode = node;
            [navigationController pushViewController:cloudDriveTVC animated:NO];
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension) {
                MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.parentHandle];
                NSArray *nodes = [[[MEGASdkManager sharedMEGASdk] childrenForParent:parentNode] mnz_nodesArrayFromNodeList];
                [node mnz_openImageInNavigationController:navigationController withNodes:nodes folderLink:NO displayMode:DisplayModeCloudDrive];
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
        if ([filename containsString:@"megaclient"]) {
            NSString *destinationPath = [groupSupportPath stringByAppendingPathComponent:filename];
            if ([fileManager fileExistsAtPath:destinationPath]) {
                if (![fileManager removeItemAtPath:destinationPath error:&error]) {
                    MEGALogError(@"Remove item at path failed with error: %@", error);
                }
            }
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
        customModalAlertVC.image = @"inviteSent";
        customModalAlertVC.viewTitle = AMLocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
        customModalAlertVC.detail = [NSString stringWithFormat:@"The user %@ has been invited and will appear in your contact list once accepted", self.email];
        customModalAlertVC.action = AMLocalizedString(@"close", nil);
        customModalAlertVC.dismiss = nil;
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
    } else {
        customModalAlertVC.image = @"groupChat";
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
    
    [[UIApplication mnz_visibleViewController] presentViewController:customModalAlertVC animated:YES completion:nil];
    
    self.presentInviteContactVCLater = NO;
}

- (void)openChatRoomWithChatNumber:(NSNumber *)chatNumber {
    if (chatNumber) {
        self.mainTBC.selectedIndex = CHAT;
        MEGANavigationController *navigationController = [[self.mainTBC viewControllers] objectAtIndex:CHAT];
        ChatRoomsViewController *chatRoomsVC = navigationController.viewControllers.firstObject;
        [chatRoomsVC openChatRoomWithID:chatNumber.unsignedLongLongValue];
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
    
    [self presentLinkViewController:navigationController];
    self.urlType = URLTypeDefault;
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ((alertView.tag == 0) && (buttonIndex == 1)) {
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
        
        [self dismissPresentedViews];
        
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
    } else if ([alertView tag] == 1) { //alreadyLoggedInAlertView
        if (buttonIndex == 0) {
            _emailOfNewSignUpLink = nil;
        } else if (buttonIndex == 1) {
            [[MEGASdkManager sharedMEGASdk] logout];
        }
    } else if ((alertView.tag == 2 && buttonIndex == 1) || (alertView.tag == 3 && buttonIndex == 1)) { //masterKeyLoggedInAlertView, masterKeyLoggedOutAlertView
        NSString *masterKey = (alertView.tag == 2) ? [[MEGASdkManager sharedMEGASdk] masterKey] : [[alertView textFieldAtIndex:0] text];
        [self presentChangeViewType:ChangeTypeResetPassword email:self.emailOfNewSignUpLink masterKey:masterKey link:self.recoveryLink];
        
        self.emailOfNewSignUpLink = nil;
        self.recoveryLink = nil;
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
                if ([[NSFileManager defaultManager] fileExistsAtPath:attributePath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:attributePath error:nil];
                }
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
        if ([[NSFileManager defaultManager] fileExistsAtPath:v2Path]) {
            [[NSFileManager defaultManager] removeItemAtPath:v2Path error:nil];
        }
    }
}

- (void)cameraUploadsSettingsCompatibility {
    // PhotoSync old location of completed uploads
    NSString *oldCompleted = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"PhotoSync/completed.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldCompleted]) {
        [[NSFileManager defaultManager] removeItemAtPath:oldCompleted error:nil];
    }
    
    // PhotoSync v2 location of completed uploads
    NSString *v2Completed = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"PhotoSync/com.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:v2Completed]) {
        [[NSFileManager defaultManager] removeItemAtPath:v2Completed error:nil];
    }
    
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
        
        [[NSFileManager defaultManager] removeItemAtPath:v2PspPath error:nil];
    }
}

- (void)removeOldStateCache {
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libraryDirectory error:nil];
    
    for (NSString *item in directoryContent) {
        if([item.pathExtension isEqualToString:@"db"]) {
            NSString *stateCachePath = [libraryDirectory stringByAppendingPathComponent:item];
            if ([[NSFileManager defaultManager] fileExistsAtPath:stateCachePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:stateCachePath error:nil];
            }
        }
    }
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
    [self startBackgroundTask];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    MEGALogDebug(@"userNotificationCenter didReceiveNotificationResponse %@", response);
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[response.notification.request.identifier]];
    
    [self openChatRoomWithChatNumber:response.notification.request.content.userInfo[@"chatId"]];
    
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self openChatRoomWithChatNumber:notification.userInfo[@"chatId"]];
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
        
        if ([user hasChangedType:MEGAUserChangeTypeEmail]) {
            MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:user.handle];
            if (moUser) {
                [[MEGAStore shareInstance] updateUserWithUserHandle:user.handle email:user.email];
            } else {
                [[MEGAStore shareInstance] insertUserWithUserHandle:user.handle firstname:nil lastname:nil email:user.email];
            }
        }
        
        if (([user handle] == [[[MEGASdkManager sharedMEGASdk] myUser] handle])) {
            if (user.isOwnChange == 0) { //If the change is external
                if ([user hasChangedType:MEGAUserChangeTypeAvatar]) { //If you have changed your avatar, remove the old and request the new one
                    NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
                    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:userBase64Handle];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
                    if (fileExists) {
                        [[NSFileManager defaultManager] removeItemAtPath:avatarFilePath error:nil];
                    }
                    [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath];
                }
                
                if ([user hasChangedType:MEGAUserChangeTypeFirstname]) {
                    [[MEGASdkManager sharedMEGASdk] getUserAttributeType:MEGAUserAttributeFirstname];
                }
                if ([user hasChangedType:MEGAUserChangeTypeLastname]) {
                    [[MEGASdkManager sharedMEGASdk] getUserAttributeType:MEGAUserAttributeLastname];
                }
            }
        } else {
            if (user.changes) {
                if ([user hasChangedType:MEGAUserChangeTypeFirstname]) {
                    [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
                }
                if ([user hasChangedType:MEGAUserChangeTypeLastname]) {
                    [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname];
                }
            } else if (user.visibility == MEGAUserVisibilityVisible) {
                [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname];
                [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname];
            }
        }
    }
}

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (!nodeList) {
        MEGATransferList *transferList = [api uploadTransfers];
        if (transferList.size.integerValue == 0) {
            if ([CameraUploads syncManager].isCameraUploadsEnabled) {
                MEGALogInfo(@"Enable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
            }
        } else {
            for (NSInteger i = 0; i < transferList.size.integerValue; i++) {
                MEGATransfer *transfer = [transferList transferAtIndex:i];
                if (transfer.appData) {
                    NSArray *appDataComponentsArray = [transfer.appData componentsSeparatedByString:@"="];
                    NSString *appDataFirstComponentString = [appDataComponentsArray objectAtIndex:0];
                    if ([appDataFirstComponentString isEqualToString:@"CU"]) {
                        if ([CameraUploads syncManager].isCameraUploadsEnabled) {
                            if (![CameraUploads syncManager].isUseCellularConnectionEnabled && [MEGAReachabilityManager isReachableViaWWAN]) {
                                [api cancelTransfer:transfer];
                            } else {
                                MEGALogInfo(@"Camera Upload should be delayed");
                                [CameraUploads syncManager].shouldCameraUploadsBeDelayed = YES;
                            }
                        } else {
                            [api cancelTransfer:transfer];
                        }
                        break;
                    }
                    break;
                }
            }
        }
    } else {
        NSArray<MEGANode *> *nodesToIndex = [nodeList mnz_nodesArrayFromNodeList];
        MEGALogDebug(@"Spotlight indexing %lu nodes updated", nodesToIndex.count);
        for (MEGANode *node in nodesToIndex) {
            [self.indexer index:node];
        }
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
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudLogOut"] status:AMLocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
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
                    UIAlertView *linkHasExpiredAlertView = [[UIAlertView alloc] initWithTitle:alertTitle message:nil delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [linkHasExpiredAlertView show];
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                if ([request type] == MEGARequestTypeQuerySignUpLink) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"error", nil)
                                                                    message:AMLocalizedString(@"accountAlreadyConfirmed", @"Account already confirmed.")
                                                                   delegate:self
                                                          cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                } else if ([request type] == MEGARequestTypeQueryRecoveryLink) {
                    [self showLinkNotValid];
                }
                break;
            }
                
            case MEGAErrorTypeApiESid: {                                
                if (self.urlType == URLTypeCancelAccountLink) {
                    self.urlType = URLTypeDefault;
                    [Helper logout];
                    return;
                }
                
                if ([request type] == MEGARequestTypeLogin || [request type] == MEGARequestTypeLogout) {
                    if (![_API_ESIDAlertView isVisible]) {
                        _API_ESIDAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"loggedOut_alertTitle", nil) message:AMLocalizedString(@"loggedOutFromAnotherLocation", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                        [_API_ESIDAlertView show];
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
                
            case MEGAErrorTypeApiESSL: {
                if ([request type] == MEGARequestTypeLogout) {
                    NSString *issuer = [NSString stringWithFormat:@"(Issuer: %@)", [request text] ? [request text] : @"Unknown"];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"sslUnverified_alertTitle", nil) message:issuer delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [alertView show];
                    [Helper logout];
                }
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                if ([request type] == MEGARequestTypeSetAttrFile) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                    BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (thumbnailExists) {
                        [[NSFileManager defaultManager] removeItemAtPath:thumbnailFilePath error:nil];
                    }
                }
                
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                if ([request type] == MEGARequestTypeQuerySignUpLink) {
                    [self showLinkNotValid];
                }
                break;
            }
                
                
            case MEGAErrorTypeApiEBlocked: {
                if ([request type] == MEGARequestTypeLogin || [request type] == MEGARequestTypeFetchNodes) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"error", nil)
                                                                    message:AMLocalizedString(@"accountBlocked", @"Error message when trying to login and the account is blocked")
                                                                   delegate:self
                                                          cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
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
                
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                    [[MEGASdkManager sharedMEGAChatSdk] connectInBackground];
                } else {
                    [[MEGASdkManager sharedMEGAChatSdk] connect];
                }
                if (isAccountFirstLogin) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IsChatEnabled"];
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
                [self presentConfirmViewControllerType:ConfirmTypeAccount link:request.link email:request.email];
            } else if (self.urlType == URLTypeNewSignUpLink) {

                if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
                    _emailOfNewSignUpLink = [request email];
                    UIAlertView *alreadyLoggedInAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"alreadyLoggedInAlertTitle", nil)
                                                                        message:AMLocalizedString(@"alreadyLoggedInAlertMessage", nil)
                                                                       delegate:self
                                                              cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                              otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    [alreadyLoggedInAlertView setTag:1];
                    [alreadyLoggedInAlertView show];
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
                if (request.flag) {
                    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                        UIAlertView *masterKeyLoggedInAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:AMLocalizedString(@"youRecoveryKeyIsGoingTo", @"Text of the alert after opening the recovery link to reset pass being logged.") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                        masterKeyLoggedInAlertView.tag = 2;
                        [masterKeyLoggedInAlertView show];
                    } else {
                        UIAlertView *masterKeyLoggedOutAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:AMLocalizedString(@"pleaseEnterYourRecoveryKey", @"A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                        masterKeyLoggedOutAlertView.tag = 3;
                        masterKeyLoggedOutAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                        UITextField *textField = [masterKeyLoggedOutAlertView textFieldAtIndex:0];
                        textField.placeholder = AMLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
                        [masterKeyLoggedOutAlertView show];
                    }
                    
                    self.emailOfNewSignUpLink = request.email;
                    self.recoveryLink = request.link;
                } else {
                    [self presentChangeViewType:ChangeTypeParkAccount email:request.email masterKey:nil link:request.link];
                }
            }
            break;
        }
            
        case MEGARequestTypeLogout: {            
            [Helper logout];
            [SVProgressHUD dismiss];
            
            if (self.messageForSuspendedAccount) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:self.messageForSuspendedAccount preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
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
                if ([[request megaAccountDetails] type] > MEGAAccountTypeFree) {
                    overquotaAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"overquotaAlert_title", nil) message:AMLocalizedString(@"quotaExceeded", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
                } else {
                    overquotaAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"overquotaAlert_title", nil) message:AMLocalizedString(@"overquotaAlert_message", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                }
                [overquotaAlertView setTag:0];
                [overquotaAlertView show];
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
        MEGALogError(@"onChatRequestFinish error type: %ld request type: %ld", error.type, request.type);
        return;
    }
    
    if (request.type == MEGAChatRequestTypeLogout) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
            [[MEGALogger sharedLogger] enableSDKlogs];
        }
        [MEGASdkManager destroySharedMEGAChatSdk];
        
        [self.mainTBC setBadgeValueForChats];
    }
    
    MEGALogInfo(@"onChatRequestFinish request type: %ld", request.type);
}

#pragma mark - MEGAChatDelegate

- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState {
    MEGALogInfo(@"onChatInitStateUpdate new state: %ld", newState);
    if (newState == MEGAChatInitError) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:@"Chat disabled (Init error). Enable chat in More -> Settings -> Chat" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        [[MEGASdkManager sharedMEGAChatSdk] logout];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
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
    if (transfer.type == MEGATransferTypeUpload && transfer.fileName.mnz_isImagePathExtension) {
        NSString *transferAbsolutePath = [NSHomeDirectory() stringByAppendingPathComponent:transfer.path];
        [api createThumbnail:transferAbsolutePath destinatioPath:[transferAbsolutePath stringByAppendingString:@"_thumbnail"]];
        [api createPreview:transferAbsolutePath destinatioPath:[transferAbsolutePath stringByAppendingString:@"_preview"]];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        if (transfer.appData) {
            NSArray *appDataComponentsArray = [transfer.appData componentsSeparatedByString:@"="];
            NSString *appDataFirstComponentString = [appDataComponentsArray objectAtIndex:0];
            if ([appDataFirstComponentString isEqualToString:@"CU"] && ![CameraUploads syncManager].isUseCellularConnectionEnabled && [MEGAReachabilityManager isReachableViaWWAN]) {
                [api cancelTransfer:transfer];
            }
        }
    }
}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type == MEGAErrorTypeApiEOverQuota && error.value) {
        [SVProgressHUD dismiss];
        
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        customModalAlertVC.image = @"transfer-quota-empty";
        customModalAlertVC.viewTitle = AMLocalizedString(@"depletedTransferQuota_title", @"Title shown when you almost had used your available transfer quota.");;
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
                    
                    [[UIApplication mnz_visibleViewController] presentViewController:navigationController animated:YES completion:nil];
                } else {
                    // Redirect to my account if the products are not available
                    [self.mainTBC setSelectedIndex:4];
                }
            }];
        };
        
        [[UIApplication mnz_visibleViewController] presentViewController:customModalAlertVC animated:YES completion:nil];
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
        if (transfer.fileName.mnz_isImagePathExtension) {
            NSString *transferAbsolutePath = [NSHomeDirectory() stringByAppendingPathComponent:transfer.path];
            NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
            NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
            if ([error type] == MEGAErrorTypeApiOk) {
                MEGANode *node = [api nodeForHandle:transfer.nodeHandle];
                
                [[NSFileManager defaultManager] moveItemAtPath:[transferAbsolutePath stringByAppendingString:@"_thumbnail"] toPath:[thumbsDirectory stringByAppendingPathComponent:node.base64Handle] error:nil];
                [[NSFileManager defaultManager] moveItemAtPath:[transferAbsolutePath stringByAppendingString:@"_preview"] toPath:[previewsDirectory stringByAppendingPathComponent:node.base64Handle] error:nil];
            } else {
                [[NSFileManager defaultManager] removeItemAtPath:[transferAbsolutePath stringByAppendingString:@"_thumbnail"] error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:[transferAbsolutePath stringByAppendingString:@"_preview"] error:nil];
            }
        }
        
        if ([CameraUploads syncManager].shouldCameraUploadsBeDelayed) {
            [CameraUploads syncManager].shouldCameraUploadsBeDelayed = NO;
            if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
                MEGALogInfo(@"Enable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
            }
        }
        
        NSArray *appDataComponentsArray = [transfer.appData componentsSeparatedByString:@"="];
        NSString *appDataFirstComponentString = [appDataComponentsArray objectAtIndex:0];
        if ([appDataFirstComponentString isEqualToString:@"attachToChatID"]) {
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogInfo(@"Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
            
            if (appDataComponentsArray.count > 2) {
                NSArray *multipleAppDataComponentsArray = [transfer.appData componentsSeparatedByString:@"!"];
                for (NSString *attachToChatID in multipleAppDataComponentsArray) {
                    NSArray *attachToChatIDComponentsArray = [attachToChatID componentsSeparatedByString:@"="];
                    NSString *chatID = [attachToChatIDComponentsArray objectAtIndex:1];
                    unsigned long long chatIdUll = strtoull(chatID.UTF8String, NULL, 0);
                    [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatIdUll node:transfer.nodeHandle];
                }
            } else {
                NSString *chatID = [appDataComponentsArray objectAtIndex:1];
                unsigned long long chatIdUll = strtoull(chatID.UTF8String, NULL, 0);
                [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatIdUll node:transfer.nodeHandle];
            }
        }
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
        if ([transfer.appData isEqualToString:@"SaveInPhotosApp"]) {
            if (node.name.mnz_isVideoPathExtension && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([NSHomeDirectory() stringByAppendingPathComponent:transfer.path])) {
                UISaveVideoAtPathToSavedPhotosAlbum([NSHomeDirectory() stringByAppendingPathComponent:transfer.path], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
            
            if (transfer.fileName.mnz_isImagePathExtension) {
                NSURL *imageURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path]];
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCreationRequest *assetCreationRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [assetCreationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
                    
                } completionHandler:^(BOOL success, NSError * _Nullable nserror) {
                    [[NSFileManager defaultManager] removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path] error:nil];
                    if (nserror) {
                        MEGALogError(@"Add asset to camera roll: %@ (Domain: %@ - Code:%ld)", nserror.localizedDescription, nserror.domain, nserror.code);
                    }
                }];
            }
            return;
        }
        
        if ([transfer.appData isEqualToString:@"generate_fa"]) {
            NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            
            if (!thumbnailExists) {
                [api createThumbnail:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path] destinatioPath:thumbnailFilePath];
            }
            
            NSString *previewFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"];
            BOOL previewExists = [[NSFileManager defaultManager] fileExistsAtPath:previewFilePath];
            
            if (!previewExists) {
                [api createPreview:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path] destinatioPath:previewFilePath];
            }
            
            return;
        }
        
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]];
        if (!offlineNodeExist) {
            MEGALogDebug(@"Transfer finish: insert node to DB: base64 handle: %@ - local path: %@", node.base64Handle, transfer.path);
            NSRange replaceRange = [transfer.path rangeOfString:@"Documents/"];
            if (replaceRange.location != NSNotFound) {
                NSString *result = [transfer.path stringByReplacingCharactersInRange:replaceRange withString:@""];
                [[MEGAStore shareInstance] insertOfflineNode:node api:api path:[result decomposedStringWithCanonicalMapping]];
            }
        }
        
        if (transfer.fileName.mnz_isVideoPathExtension && !node.hasThumbnail) {
            NSURL *videoURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:transfer.path]];
            [node mnz_generateThumbnailForVideoAtPath:videoURL];
        }
    }
}

#pragma mark - MEGAApplicationDelegate

- (void)application:(MEGAApplication *)application willSendTouchEvent:(UIEvent *)event {
    if (self.isSignalActivityRequired) {
        [[MEGASdkManager sharedMEGAChatSdk] signalPresenceActivity];
    }
}

@end
