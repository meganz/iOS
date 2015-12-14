/**
 * @file AppDelegate.m
 * @brief The AppDelegate of the app
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "AppDelegate.h"
#import "SSKeychain.h"
#import "SVProgressHUD.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "ConfirmAccountViewController.h"
#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "CameraUploads.h"
#import "MEGAReachabilityManager.h"
#import "LTHPasscodeViewController.h"
#import "MEGAProxyServer.h"
#import "CameraUploadsPopUpViewController.h"
#import "MEGANavigationController.h"
#import "UpgradeTableViewController.h"

#import "LaunchViewController.h"

#import "BrowserViewController.h"
#import "MEGAStore.h"
#import "MEGAPurchase.h"

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <QuickLook/QuickLook.h>

#import <StoreKit/StoreKit.h>

#import <AVFoundation/AVFoundation.h>

#define kUserAgent @"MEGAiOS"
#define kAppKey @"EVtjzb7R"

#define kFirstRun @"FirstRun"

typedef NS_ENUM(NSUInteger, URLType) {
    URLTypeFileLink,
    URLTypeFolderLink,
    URLTypeConfirmationLink,
    URLTypeOpenInLink
};

@interface AppDelegate () <UIAlertViewDelegate, LTHPasscodeViewControllerDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
    BOOL isOverquota;
    
    BOOL isFirstFetchNodesRequestUpdate;
    BOOL isFirstAPI_EAGAIN;
    NSTimer *timerAPI_EAGAIN;
}

@property (nonatomic, strong) NSString *IpAddress;
@property (nonatomic, strong) NSURL *link;
@property (nonatomic) URLType urlType;

@property (nonatomic, weak) MainTabBarController *mainTBC;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error: nil];
    
    self.IpAddress = [self getIpAddress];
    [MEGAReachabilityManager sharedManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    [MEGASdkManager sharedMEGASdk];
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];

    [Fabric with:@[CrashlyticsKit]];
    
    [self languageCompatibility];
    
    // Delete username and password if exists - V1
    if ([SSKeychain passwordForService:@"MEGA" account:@"username"] && [SSKeychain passwordForService:@"MEGA" account:@"password"]) {
        [SSKeychain deletePasswordForService:@"MEGA" account:@"username"];
        [SSKeychain deletePasswordForService:@"MEGA" account:@"password"];
    }
    
    // Session from v2
    NSData *sessionV2 = [SSKeychain passwordDataForService:@"MEGA" account:@"session"];
    NSString *sessionV3 = [SSKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    
    if (sessionV2) {
        // Save session for v3 and delete the previous one
        sessionV3 = [sessionV2 base64EncodedStringWithOptions:0];
        sessionV3 = [sessionV3 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
        sessionV3 = [sessionV3 stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        sessionV3 = [sessionV3 stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        [SSKeychain setPassword:sessionV3 forService:@"MEGA" account:@"sessionV3"];
        
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
        
        [SSKeychain deletePasswordForService:@"MEGA" account:@"session"];
    }

    // Rename attributes (thumbnails and previews)- handle to base64Handle
    NSString *v2ThumbsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:v2ThumbsPath]) {
        NSString *v3ThumbsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:v3ThumbsPath]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:v3ThumbsPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
            }
        }
        [self renameAttributesAtPath:v2ThumbsPath v3Path:v3ThumbsPath];
    }
    
    NSString *v2previewsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:v2previewsPath]) {
        NSString *v3PreviewsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:v3PreviewsPath]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:v3PreviewsPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
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
    
    [MEGAStore shareInstance];
    
    self.link = nil;
    isFetchNodesDone = NO;
    
    if (sessionV3) {
        isAccountFirstLogin = NO;
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:sessionV3];
        
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
    }
    
    // Let the device know we want to receive push notifications
//    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
//        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
//                                                                                             |UIRemoteNotificationTypeSound
//                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
//        [application registerUserNotificationSettings:settings];
//    } else {
//        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
//        [application registerForRemoteNotificationTypes:myTypes];
//    }
    
    // Start Proxy server for streaming
    [[MEGAProxyServer sharedInstance] start];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self startBackgroundTask];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] && [[CameraUploads syncManager] isCameraUploadsEnabled]) {
        [[CameraUploads syncManager] getAllAssetsForUpload];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[MEGAPurchase sharedInstance]];
    
    if (![SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [Helper logout];
    } else {
        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:0];
        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
        [[MEGASdkManager sharedMEGASdkFolder] cancelTransfersForDirection:0];
        
        [self removeUnfinishedTransfersOnFolder:[Helper pathForOffline]];
    }
    
    // Clean up temporary directory
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove temporary directory error: %@", error]];
    }
    
    // Clean up Documents/Inbox directory
    NSString *inboxDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Inbox"];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxDirectory error:&error]) {
        error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[inboxDirectory stringByAppendingPathComponent:file] error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    self.link = url;
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        if (![LTHPasscodeViewController doesPasscodeExist] && isFetchNodesDone) {
            [self processLink:self.link];
            self.link = nil;
        }
    } else {
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            [self processLink:self.link];
            self.link = nil;
        }
    }
    
    return YES;
}

//#pragma mark - Push Notifications
//
//#ifdef __IPHONE_8_0
//- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
//    //register to receive notifications
//    [application registerForRemoteNotifications];
//}
//
//- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
//    //handle the actions
//    if ([identifier isEqualToString:@"declineAction"]){
//    }
//    else if ([identifier isEqualToString:@"answerAction"]){
//    }
//}
//#endif
//
//- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken{
//    NSString* newToken = [deviceToken description];
//    NSLog(@"device token %@", newToken);
//}
//
//- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error{
//    NSLog(@"Failed to get token, error: %@", error);
//}
//
//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
//    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] && [[CameraUploads syncManager] isCameraUploadsEnabled]) {
//        [[CameraUploads syncManager] getAllAssetsForUpload];
//        [self startBackgroundTask];
//    
//        completionHandler(UIBackgroundFetchResultNewData);
//    }
//}

#pragma mark - Private

- (void)setupAppearance {    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIDisplay-Light" size:20.0]}];
    [[UINavigationBar appearance] setTintColor:megaRed];
    [[UINavigationBar appearance] setBackgroundColor:megaInfoGray];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:13.0]} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTintColor:megaRed];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0]} forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:8.0], NSForegroundColorAttributeName:megaMediumGray} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:8.0], NSForegroundColorAttributeName:megaRed} forState:UIControlStateSelected];
    
    [[UITextField appearance] setTintColor:megaRed];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setBackgroundColor:megaLightGray];
    
    [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setTintColor:megaRed];
    
    [SVProgressHUD setFont:[UIFont fontWithName:kFont size:12.0]];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setBackgroundColor:megaInfoGray];
    [SVProgressHUD setForegroundColor:megaDarkGray];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hudSuccess"]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hudError"]];
}

- (void)startBackgroundTask {
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)showCameraUploadsPopUp {
    MEGANavigationController *cameraUploadsNavigationController =[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsPopUpNavigationControllerID"];
    
    [self.window.rootViewController presentViewController:cameraUploadsNavigationController animated:YES completion:nil];
}

- (void)selectedOptionOnLink {
    switch ([Helper selectedOptionOnLink]) {
        case 1: { //IMPORT
            MEGANode *node = [Helper linkNode];
            if ([node type] == MEGANodeTypeFile) {
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                [self.window.rootViewController.presentedViewController presentViewController:navigationController animated:YES completion:nil];
                
                BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
                browserVC.selectedNodesArray = [NSArray arrayWithObject:node];
                [browserVC setBrowserAction:BrowserActionImport];
            }
            break;
        }
            
        case 2: { //DOWNLOAD
            MEGANode *node = [Helper linkNode];
            if ([node type] == MEGANodeTypeFile) {
                if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                    return;
                }
                [Helper downloadNode:node folderPath:[Helper pathForOffline] isFolderLink:NO];
            } else if ([node type] == MEGANodeTypeFolder) {
                if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                    return;
                }
                [Helper downloadNode:node folderPath:[Helper pathForOffline] isFolderLink:YES];
            }
            break;
        }
            
        default:
            break;
    }
    
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
}

- (void)processLink:(NSURL *)url {
    
    NSString *afterSlashesString = [[url absoluteString] substringFromIndex:7]; // "mega://" = 7 characters
        
    if ([afterSlashesString isEqualToString:@""] || (afterSlashesString.length < 2)) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"invalidLink", nil)];
        return;
    }
        
    [self dissmissPresentedViews];
    
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
    
    if ([self isConfirmationLink:afterSlashesString]) {
        self.urlType = URLTypeConfirmationLink;
        return;
    }
    
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"invalidLink", nil)];
}

- (void)dissmissPresentedViews {
    if (self.window.rootViewController.presentedViewController != nil) {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)isFileLink:(NSString *)afterSlashesString {
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:2]; // mega://"#!"
    BOOL isFileLink = [megaURLTypeString isEqualToString:@"#!"];
    if (isFileLink) {
        NSString *megaURLString = @"https://mega.nz/";
        NSString *fileLinkCodeString = [afterSlashesString substringFromIndex:2]; // mega://#!"xxxxxxxx..."!
        
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"!"];
        BOOL isEncryptedFileLink = ([fileLinkCodeString rangeOfCharacterFromSet:characterSet].location == NSNotFound);
        if (isEncryptedFileLink) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"fileEncrypted", @"File encrypted")
                                                                message:AMLocalizedString(@"fileEncryptedMessage", @"This function is not available. For the moment you can't import or download an encrypted file.")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            
        } else {
            MEGANavigationController *fileLinkNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkNavigationControllerID"];
            FileLinkViewController *fileLinkVC = fileLinkNavigationController.viewControllers.firstObject;
            NSString *megaFileLinkURLString = [megaURLString stringByAppendingString:afterSlashesString];
            [fileLinkVC setFileLinkString:megaFileLinkURLString];
            
            if ([self.window.rootViewController.presentedViewController isKindOfClass:[MEGANavigationController class]]) {
                MEGANavigationController *cameraUploadsPopUpNavigationController = (MEGANavigationController *)self.window.rootViewController.presentedViewController;
                if ([cameraUploadsPopUpNavigationController.topViewController isKindOfClass:[CameraUploadsPopUpViewController class]]) {
                    [cameraUploadsPopUpNavigationController.topViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
                } else {
                    [self.window.rootViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
                }
            } else {
                [self.window.rootViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
            }
        }
        return YES;
    }
    return NO;
}

- (BOOL)isFolderLink:(NSString *)afterSlashesString {
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:3]; // mega://"#F!"
    BOOL isFolderLink = [megaURLTypeString isEqualToString:@"#F!"];
    if (isFolderLink) {
        NSString *megaURLString = @"https://mega.nz/";
        NSString *folderLinkCodeString = [afterSlashesString substringFromIndex:3]; // mega://#F!"xxxxxxxx..."!
        
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"!"];
        BOOL isEncryptedFolderLink = ([folderLinkCodeString rangeOfCharacterFromSet:characterSet].location == NSNotFound);
        if (isEncryptedFolderLink) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"folderEncrypted", @"Folder encrypted")
                                                                message:AMLocalizedString(@"folderEncryptedMessage", @"This function is not available. For the moment you can't import or download an encrypted folder.")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            
        } else {
            MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
            
            FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
            
            NSString *megaFolderLinkString = [megaURLString stringByAppendingString:afterSlashesString];
            [folderlinkVC setIsFolderRootNode:YES];
            [folderlinkVC setFolderLinkString:megaFolderLinkString];
            
            if ([self.window.rootViewController.presentedViewController isKindOfClass:[MEGANavigationController class]]) {
                MEGANavigationController *cameraUploadsPopUpNavigationController = (MEGANavigationController *)self.window.rootViewController.presentedViewController;
                if ([cameraUploadsPopUpNavigationController.topViewController isKindOfClass:[CameraUploadsPopUpViewController class]]) {
                    [cameraUploadsPopUpNavigationController.topViewController presentViewController:folderNavigationController animated:YES completion:nil];
                } else {
                    [self.window.rootViewController presentViewController:folderNavigationController animated:YES completion:nil];
                }
            } else {
                [self.window.rootViewController presentViewController:folderNavigationController animated:YES completion:nil];
            }
        }
        return YES;
    }
    return NO;
}

- (BOOL)isConfirmationLink:(NSString *)afterSlashesString {
    NSString *megaURLString = @"https://mega.nz/";
    BOOL isMEGACONZConfirmationLink = [[afterSlashesString substringToIndex:7] isEqualToString:@"confirm"]; // mega://"confirm"
    BOOL isMEGANZConfirmationLink = [[afterSlashesString substringToIndex:8] isEqualToString:@"#confirm"]; // mega://"#confirm"
    if (isMEGACONZConfirmationLink) {
        NSString *megaURLConfirmationString = [megaURLString stringByAppendingString:@"#"];
        megaURLConfirmationString = [megaURLConfirmationString stringByAppendingString:afterSlashesString];
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLConfirmationString];
        return YES;
    } else if (isMEGANZConfirmationLink) {
        NSString *megaURLConfirmationString = [megaURLString stringByAppendingString:afterSlashesString];
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLConfirmationString];
        return YES;
    }
    return NO;
}

- (void)openIn {
    if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        MEGANavigationController *browserNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = browserNavigationController.viewControllers.firstObject;
        browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
        [browserVC setLocalpath:[self.link path]]; // "file://" = 7 characters
        [browserVC setBrowserAction:BrowserActionOpenIn];
        
        if ([self.window.rootViewController.presentedViewController isKindOfClass:[MEGANavigationController class]]) {
            MEGANavigationController *cameraUploadsPopUpNavigationController = (MEGANavigationController *)self.window.rootViewController.presentedViewController;
            if ([cameraUploadsPopUpNavigationController.topViewController isKindOfClass:[CameraUploadsPopUpViewController class]]) {
                [cameraUploadsPopUpNavigationController.topViewController presentViewController:browserNavigationController animated:YES completion:nil];
            } else {
                [self.window.rootViewController presentViewController:browserNavigationController animated:YES completion:nil];
            }
        } else {
            [self.window.rootViewController presentViewController:browserNavigationController animated:YES completion:nil];
        }
    }
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
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:item] error:&error];
                if (!success || error) {
                    [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
                }
            }
        }
    }
}

- (void)setBadgeValueForIncomingContactRequests {
    NSInteger contactsTabPosition;
    for (contactsTabPosition = 0 ; contactsTabPosition < self.mainTBC.viewControllers.count ; contactsTabPosition++) {
        if ([[[self.mainTBC.viewControllers objectAtIndex:contactsTabPosition] tabBarItem] tag] == 4) {
            break;
        }
    }
    
    MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
    long incomingContacts = [[incomingContactsLists size] longValue];
    NSString *badgeValue;
    if (incomingContacts) {
        badgeValue = [NSString stringWithFormat:@"%ld", incomingContacts];
    } else {
        badgeValue = nil;
    }
    
    if ((contactsTabPosition >= 4) && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)) {
        [[[self.mainTBC moreNavigationController] tabBarItem] setBadgeValue:badgeValue];
    }
    [[self.mainTBC.viewControllers objectAtIndex:contactsTabPosition] tabBarItem].badgeValue = badgeValue;
}

- (void)startTimerAPI_EAGAIN {
    timerAPI_EAGAIN = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showServersTooBusy) userInfo:nil repeats:NO];
}

- (void)showServersTooBusy {
    if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
        LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
        [launchVC.label setText:AMLocalizedString(@"serversTooBusy", nil)];
    }
}

#pragma mark - Get IP Address

- (NSString *)getIpAddress {
    NSString *address = nil;
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    char straddr[INET_ADDRSTRLEN];
                    inet_ntop(AF_INET, (void *)&((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr, straddr, sizeof(straddr));
                    
                    if(strncasecmp(straddr, "127.", 4) && strncasecmp(straddr, "169.254.", 8)) {
                        address = [NSString stringWithUTF8String:straddr];
                    }
                }
            }
            
            if(temp_addr->ifa_addr->sa_family == AF_INET6) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    char straddr[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, (void *)&((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr, straddr, sizeof(straddr));
                    
                    if(strncasecmp(straddr, "FE80:", 5) && strncasecmp(straddr, "FD00:", 5)) {
                        address = [NSString stringWithUTF8String:straddr];
                    }
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

#pragma mark - Reachability Changes

- (void)reachabilityDidChange:(NSNotification *)notification {
    
    if ([MEGAReachabilityManager isReachable]) {
        NSString *currentIP = [self getIpAddress];
        if (![self.IpAddress isEqualToString:currentIP]) {
            [[MEGASdkManager sharedMEGASdk] reconnect];
            self.IpAddress = currentIP;
        }
    }
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        if (![[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
            if ([MEGAReachabilityManager isReachableViaWWAN]) {
                [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
                [[[CameraUploads syncManager] assetUploadArray] removeAllObjects];
            }
            
            if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] && [MEGAReachabilityManager isReachableViaWiFi]) {
                [[CameraUploads syncManager] getAllAssetsForUpload];
            }
        }
    }
}

#pragma mark - Battery changed

- (void)batteryChanged:(NSNotification *)notification {
    if ([[CameraUploads syncManager] isOnlyWhenChargingEnabled]) {
        // Status battery unplugged
        if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnplugged) {
            [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
            [[[CameraUploads syncManager] assetUploadArray] removeAllObjects];
        }
        // Status battery plugged
        else {
            [[CameraUploads syncManager] getAllAssetsForUpload];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ((alertView.tag == 0) && (buttonIndex == 1)) {
        
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:nil action:@selector(dissmissPresentedViews)];
        [upgradeTVC.navigationItem setRightBarButtonItem:cancelBarButtonItem];
        
        [self dissmissPresentedViews];
        
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    if ([MEGAReachabilityManager isReachable]) {
        if (self.link != nil) {
            [self processLink:self.link];
            self.link = nil;
        }
    } else {
        _mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [self.window setRootViewController:_mainTBC];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
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
            if (isImage(attributePath.pathExtension)) {
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
    [[LocalizationSystem sharedLocalSystem] setLanguage:@"en"];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
            
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
                isFirstAPI_EAGAIN = YES;
                isFirstFetchNodesRequestUpdate = YES;
                LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
                [launchVC.activityIndicatorView setHidden:NO];
                [launchVC.activityIndicatorView startAnimating];
            }
            break;
        }
            
        case MEGARequestTypeLogout:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudLogOut"] status:AMLocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
#endif
    
    if ([request type] == MEGARequestTypeFetchNodes){
        if ([self.window.rootViewController isKindOfClass:[LaunchViewController class]]) {
            LaunchViewController *launchVC = (LaunchViewController *)self.window.rootViewController;
            float progress = [[request transferredBytes] floatValue] / [[request totalBytes] floatValue];
            
            if (isFirstFetchNodesRequestUpdate) {
                [launchVC.activityIndicatorView stopAnimating];
                [launchVC.activityIndicatorView setHidden:YES];
                isFirstFetchNodesRequestUpdate = NO;
            }
            
            if (progress > 0 && progress < 0.99) {
                [launchVC.progressView setProgress:progress];
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
                }
                break;
            }
                
            case MEGAErrorTypeApiESid: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"loggedOut_alertTitle", nil) message:AMLocalizedString(@"loggedOutFromAnotherLocation", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
                [Helper logout];
                break;
            }
                
            case MEGAErrorTypeApiEOverQuota: {
                [[MEGASdkManager sharedMEGASdk] getAccountDetails];
                isOverquota = YES;
                break;
            }
                
            case MEGAErrorTypeApiESSL: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"sslUnverified_alertTitle", nil) message:nil delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                [Helper logout];
                break;
            }
                
            default:
                break;
        }
        
        if ([request type] == MEGARequestTypeSubmitPurchaseReceipt) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"wrongPurchase", nil), [error name], (long)[error type]]];
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [timerAPI_EAGAIN invalidate];
            
            if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                isAccountFirstLogin = NO;
                isFetchNodesDone = NO;
            } else {
                isAccountFirstLogin = YES;
                self.link = nil;
            }
                        
            [[SKPaymentQueue defaultQueue] addTransactionObserver:[MEGAPurchase sharedInstance]];
            [[MEGASdkManager sharedMEGASdk] fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [timerAPI_EAGAIN invalidate];
            
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
            } else {
                if (isAccountFirstLogin) {
                    [self performSelector:@selector(showCameraUploadsPopUp) withObject:nil afterDelay:0.0];
                    
                    if ([Helper selectedOptionOnLink] != 0) {
                        [self performSelector:@selector(selectedOptionOnLink) withObject:nil afterDelay:0.75f];
                    } else {
                        if (self.urlType == URLTypeOpenInLink) {
                            [self performSelector:@selector(openIn) withObject:nil afterDelay:0.75f];
                        }
                    }
                }
                
                if (self.link != nil) {
                    [self processLink:self.link];
                    self.link = nil;
                }
            }
            
            [[CameraUploads syncManager] setTabBarController:_mainTBC];
            if ([CameraUploads syncManager].isCameraUploadsEnabled) {
                [[CameraUploads syncManager] getAllAssetsForUpload];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [[MEGASdkManager sharedMEGASdk] pauseTransfers:YES];
                [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"TransfersPaused"];
            }
            isFetchNodesDone = YES;
            
            [SVProgressHUD dismiss];
            
            [self setBadgeValueForIncomingContactRequests];
            break;
        }
            
        case MEGARequestTypeQuerySignUpLink: {
            MEGANavigationController *confirmAccountNavigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ConfirmAccountNavigationControllerID"];
            
            ConfirmAccountViewController *confirmAccountVC = confirmAccountNavigationController.viewControllers.firstObject;
            [confirmAccountVC setConfirmationLinkString:[request link]];
            [confirmAccountVC setEmailString:[request email]];
            
            if ([self.window.rootViewController.presentedViewController isKindOfClass:[MEGANavigationController class]]) {
                MEGANavigationController *cameraUploadsPopUpNavigationController = (MEGANavigationController *)self.window.rootViewController.presentedViewController;
                if ([cameraUploadsPopUpNavigationController.topViewController isKindOfClass:[CameraUploadsPopUpViewController class]]) {
                    [cameraUploadsPopUpNavigationController.topViewController presentViewController:confirmAccountNavigationController animated:YES completion:nil];
                } else {
                    [self.window.rootViewController presentViewController:confirmAccountNavigationController animated:YES completion:nil];
                }
            } else {
                [self.window.rootViewController presentViewController:confirmAccountNavigationController animated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeLogout: {
            [Helper logout];
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeSubmitPurchaseReceipt: {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
            
        case MEGARequestTypeAccountDetails: {
            
            if (isOverquota) {
                UIAlertView *alertView;
                if ([[request megaAccountDetails] type] > MEGAAccountTypeFree) {
                    alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"overquotaAlert_title", nil) message:AMLocalizedString(@"quotaExceeded", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
                } else {
                    alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"overquotaAlert_title", nil) message:AMLocalizedString(@"overquotaAlert_message", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                }
                [alertView setTag:0];
                [alertView show];
                isOverquota = NO;
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
    
    switch ([request type]) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if (isFirstAPI_EAGAIN) {
                [self startTimerAPI_EAGAIN];
                isFirstAPI_EAGAIN = NO;
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload  && !transfer.isStreamingTransfer) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        [[Helper downloadingNodes] setObject:[NSNumber numberWithInteger:transfer.tag] forKey:base64Handle];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
#endif
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiEOverQuota: {
                [[MEGASdkManager sharedMEGASdk] getAccountDetails];
                isOverquota = YES;
                break;
            }
                
            default:
                break;
        }
    }
    
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    //Delete local file even if we get an error
    if ([transfer type] == MEGATransferTypeUpload) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:transfer.path error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
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
    
    if ([error type]) {
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        // Don't add to the database downloads to the tmp folder
        if ([transfer.path rangeOfString:@"/tmp/" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return;
        }
        
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[api fingerprintForNode:node]];
        if (!offlineNodeExist) {
            [[MEGAStore shareInstance] insertOfflineNode:node api:api path:[[Helper pathRelativeToOfflineDirectory:transfer.path] decomposedStringWithCanonicalMapping]];
        }
        
        if (isImage([transfer fileName].pathExtension)) {
            MEGANode *node = [api nodeForHandle:transfer.nodeHandle];
            
            NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            
            if (!thumbnailExists) {
                [api createThumbnail:[transfer path] destinatioPath:thumbnailFilePath];
            }
            
            NSString *previewFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"];
            BOOL previewExists = [[NSFileManager defaultManager] fileExistsAtPath:previewFilePath];
            
            if (!previewExists) {
                [api createPreview:[transfer path] destinatioPath:previewFilePath];
            }
        }
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        if (isImage([transfer fileName].pathExtension)) {
            MEGANode *node = [api nodeForHandle:transfer.nodeHandle];
            [api createThumbnail:transfer.path destinatioPath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"]];
            [api createPreview:transfer.path destinatioPath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previewsV3"]];
        }
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
}

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self setBadgeValueForIncomingContactRequests];
}

@end
