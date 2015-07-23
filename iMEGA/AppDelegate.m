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

#import "BrowserViewController.h"
#import "MEGAStore.h"

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <QuickLook/QuickLook.h>

#import <AssetsLibrary/AssetsLibrary.h>

#define kUserAgent @"MEGAiOS"
#define kAppKey @"EVtjzb7R"

#define kFirstRun @"FirstRun"

@interface AppDelegate () <LTHPasscodeViewControllerDelegate> {
    BOOL isAccountFirstLogin;
    BOOL isFetchNodesDone;
}

@property (nonatomic, strong) NSString *IpAddress;
@property (nonatomic, strong) NSString *link;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.IpAddress = [self getIpAddress];
    [MEGAReachabilityManager sharedManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    [MEGASdkManager sharedMEGASdk];
    [MEGASdk setLogLevel:MEGALogLevelInfo];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    
    [[LTHPasscodeViewController sharedUser] setDelegate:self];

    [Fabric with:@[CrashlyticsKit]];
    
    //Clear keychain (session) and delete passcode on first run in case of reinstallation
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kFirstRun]) {
        [Helper clearSession];
        [Helper deletePasscode];
        [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:kFirstRun];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self setupAppearance];
    
    [MEGAStore shareInstance];
    
    self.link = nil;
    isFetchNodesDone = NO;
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        isAccountFirstLogin = NO;
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:[SSKeychain passwordForService:@"MEGA" account:@"session"]];
        
        if ([MEGAReachabilityManager isReachable]) {
            NSArray *objectsArray = [[NSBundle mainBundle] loadNibNamed:@"LaunchScreen" owner:self options:nil];
            UIViewController *viewController = [[UIViewController alloc] init];
            [viewController setView:[objectsArray objectAtIndex:0]];
            self.window.rootViewController = viewController;
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
                    [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                }
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                         withLogout:YES
                                                                     andLogoutTitle:NSLocalizedString(@"logoutLabel", "Log out")];
                [self.window setRootViewController:[LTHPasscodeViewController sharedUser]];
            } else {
                MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                [self.window setRootViewController:mainTBC];
            }
        }
    } else {
        isAccountFirstLogin = YES;
        
        [Helper setLinkNode:nil];
        [Helper setSelectedOptionOnLink:0];
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
       
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        [self photosUrlByModificationDate];
    }
    
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
    
    if (![SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        [Helper logout];
    } else {
        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:0];
        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
        [[MEGASdkManager sharedMEGASdkFolder] cancelTransfersForDirection:0];
        
        [self removeUnfinishedTransfersOnFolder:[Helper pathForOffline]];
        
        if ([Helper renamePathForPreviewDocument] != nil) {
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] moveItemAtPath:[Helper renamePathForPreviewDocument] toPath:[Helper pathForPreviewDocument] error:&error];
            if (!success || error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
            }
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    self.link = [url absoluteString];
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
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
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:20.0]}];
    [[UINavigationBar appearance] setTintColor:megaRed];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:13.0]} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTintColor:megaRed];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0]} forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:9.0]} forState:UIControlStateNormal];
        
    [[UITextField appearance] setTintColor:megaRed];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setBackgroundColor:megaLightGray];
    
    [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setTintColor:megaRed];
    
    [SVProgressHUD setFont:[UIFont fontWithName:kFont size:12.0]];
    [SVProgressHUD setBackgroundColor:megaInfoGray];
    [SVProgressHUD setForegroundColor:megaBlack];
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
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"moveNodeNav"];
                [self.window.rootViewController.presentedViewController presentViewController:navigationController animated:YES completion:nil];
                
                BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
                browserVC.selectedNodesArray = [NSArray arrayWithObject:node];
                [browserVC setIsPublicNode:YES];
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
    
// Get all photos from camera roll (key:modification date - Value:assetUrl), the photos taken in the same seconds are ignored
- (void)photosUrlByModificationDate {
    self.photosUrlDictionary = [[NSMutableDictionary alloc] init];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != nil && [[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            NSURL *url = [[result defaultRepresentation]url];
            [library assetForURL:url
                     resultBlock:^(ALAsset *asset) {
                         NSDate *assetModificationTime = [asset valueForProperty:ALAssetPropertyDate];
                         NSString *key = [NSString stringWithFormat:@"%lld", (long long)[assetModificationTime timeIntervalSince1970]];
                         
                         if ([self.photosUrlDictionary objectForKey:key] == nil) {
                             [self.photosUrlDictionary setValue:url forKey:key];
                         }
                     }
             
                    failureBlock:^(NSError *error) {
                        [MEGASdk logWithLevel:MEGALogLevelError message:@"assetForURL failureBlock"];
                    }];
        }
    };
    
    NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    
    void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos) {
                [group enumerateAssetsUsingBlock:assetEnumerator];
                [assetGroups addObject:group];
            }
        }
    };
    
    assetGroups = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                                usingBlock:assetGroupEnumerator
                              failureBlock:^(NSError *error) {
                                  [MEGASdk logWithLevel:MEGALogLevelError message:@"enumerateGroupsWithTypes failureBlock"];
                              }];

}

- (void)processLink:(NSString *)url {
    NSString *afterSlashesString = [url substringFromIndex:7]; // "mega://" = 7 characters
    
    if ([afterSlashesString isEqualToString:@""] || (afterSlashesString.length < 2)) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"invalidLink", nil)];
        return;
    }
    
    [self dissmissPreviousLinkIfPresented];
    
    if ([self isFileLink:afterSlashesString]) {
        return;
    }
    if ([self isFolderLink:afterSlashesString]) {
        return;
    }
    if ([self isConfirmationLink:afterSlashesString]) {
        return;
    }
    
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"invalidLink", nil)];
    return;
}

- (void)dissmissPreviousLinkIfPresented {
    if ([self.window.rootViewController.presentedViewController isKindOfClass:[MEGANavigationController class]]) {
        MEGANavigationController *navigationController = (MEGANavigationController *)self.window.rootViewController.presentedViewController;
        if ([navigationController.topViewController isKindOfClass:[FileLinkViewController class]] || [navigationController.topViewController isKindOfClass:[FolderLinkViewController class]]) {
            [self.window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
                if ([navigationController.presentedViewController isKindOfClass:[QLPreviewController class]]) {
                    [self.window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
                }
            }];
        }
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
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"fileEncrypted", @"File encrypted")
                                                                message:NSLocalizedString(@"fileEncryptedMessage", @"This function is not available. For the moment you can't import or download an encrypted file.")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"ok", nil)
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
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"folderEncrypted", @"Folder encrypted")
                                                                message:NSLocalizedString(@"folderEncryptedMessage", @"This function is not available. For the moment you can't import or download an encrypted folder.")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"ok", nil)
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

#pragma mark - Get IP Address

- (NSString *)getIpAddress {
    NSString *address = nil;
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

#pragma mark - Reachability Changes

- (void)reachabilityDidChange:(NSNotification *)notification {
    if (!self.IpAddress) {
        self.IpAddress = [self getIpAddress];
    }
    
    if ([MEGAReachabilityManager isReachable]) {
        if (![self.IpAddress isEqualToString:[self getIpAddress]]) {
            [[MEGASdkManager sharedMEGASdk] reconnect];
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

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    if ([MEGAReachabilityManager isReachable]) {
        if (self.link != nil) {
            [self processLink:self.link];
            self.link = nil;
        }
    } else {
        MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [self.window setRootViewController:mainTBC];
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

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeFetchNodes: {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"updatingNodes", @"Updating nodes...") maskType:SVProgressHUDMaskTypeClear];
            break;
        }
            
        case MEGARequestTypeLogout:
            [SVProgressHUD showWithStatus:NSLocalizedString(@"logout", @"Logout...") maskType:SVProgressHUDMaskTypeClear];
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
        float progress = [[request transferredBytes] floatValue] / [[request totalBytes] floatValue];
        if (progress > 0 && progress <0.99) {
            [SVProgressHUD showProgress:progress status:NSLocalizedString(@"fetchingNodes", @"Fetching nodes") maskType:SVProgressHUDMaskTypeClear];
        } else if (progress > 0.99 || progress < 0) {
            [SVProgressHUD showProgress:1 status:NSLocalizedString(@"preparingNodes", @"Preparing nodes") maskType:SVProgressHUDMaskTypeClear];
        }
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiESid) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"loggetOutTitle", nil) message:NSLocalizedString(@"loggedOutFromAnotherLocation", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
            [Helper logout];
        }
        
        if (([error type] == MEGAErrorTypeApiENoent) && ([request type] == MEGARequestTypeQuerySignUpLink)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil)
                                                            message:NSLocalizedString(@"accountAlreadyConfirmed", @"Account already confirmed.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
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
            MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            [self.window setRootViewController:mainTBC];
            
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
                    [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                }
                
                [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                         withLogout:YES
                                                                     andLogoutTitle:NSLocalizedString(@"logoutLabel", "Log out")];
            } else {
                if (isAccountFirstLogin) {
                    [self performSelector:@selector(showCameraUploadsPopUp) withObject:nil afterDelay:0.0];
                    
                    if ([Helper selectedOptionOnLink] != 0) {
                        [self performSelector:@selector(selectedOptionOnLink) withObject:nil afterDelay:0.75f];
                    }
                }
                
                if (self.link != nil) {
                    [self processLink:self.link];
                    self.link = nil;
                }
            }
            
            [[CameraUploads syncManager] setTabBarController:mainTBC];
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
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
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
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEIncomplete) {
            NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
            [[Helper downloadingNodes] removeObjectForKey:base64Handle];
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        [[Helper downloadingNodes] removeObjectForKey:base64Handle];
        
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:transfer.path]];
        if (!offlineNodeExist) {
            MOOfflineNode *offlineNode = [[MEGAStore shareInstance] insertOfflineNode];
            [offlineNode setBase64Handle:base64Handle];
            [offlineNode setParentBase64Handle:[[[MEGASdkManager sharedMEGASdk] parentNodeForNode:[[MEGASdkManager sharedMEGASdk] nodeForHandle:transfer.nodeHandle]] base64Handle]];
            [offlineNode setLocalPath:[[Helper pathRelativeToOfflineDirectory:transfer.path] decomposedStringWithCanonicalMapping]];
            [[MEGAStore shareInstance] saveContext];
        }
        
        if (isImage([transfer fileName].pathExtension)) {
            MEGANode *node = [api nodeForHandle:transfer.nodeHandle];
            
            NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            
            if (!thumbnailExists) {
                [api createThumbnail:[transfer path] destinatioPath:thumbnailFilePath];
            }
            
            NSString *previewFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previews"];
            BOOL previewExists = [[NSFileManager defaultManager] fileExistsAtPath:previewFilePath];
            
            if (!previewExists) {
                [api createPreview:[transfer path] destinatioPath:previewFilePath];
            }
        }
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[transfer fileName]];
        
        if (isImage([transfer fileName].pathExtension)) {
            MEGANode *node = [api nodeForHandle:transfer.nodeHandle];
            [api createThumbnail:localFilePath destinatioPath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"]];
            [api createPreview:localFilePath destinatioPath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previews"]];
        }
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
}

@end
