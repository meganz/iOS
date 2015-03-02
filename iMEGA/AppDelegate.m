/**
 * @file AppDelegate.m
 * @brief The AppDelegate of the app
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
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

#define kUserAgent @"MEGAiOS/2.9.1.1"
#define kAppKey @"EVtjzb7R"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [MEGASdkManager setAppKey:kAppKey];
    [MEGASdkManager setUserAgent:kUserAgent];
    [MEGASdkManager sharedMEGASdk];
    [MEGASdk setLogLevel:MEGALogLevelInfo];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    
    [self setupAppearance];
    self.isLoginFromView = YES;
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.isLoginFromView = NO;
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:[SSKeychain passwordForService:@"MEGA" account:@"session"]];
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        self.window.rootViewController = mainTBC;
    }
    
    // Let the device know we want to receive push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
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
//    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
//        [[CameraUploads syncManager] getAllAssetsForUpload];
//    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    for (NSString *file in [fileManager contentsOfDirectoryAtPath:documentDirectory error:&error]) {
        if ([file.lowercaseString.pathExtension isEqualToString:@"mega"]) {
            BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentDirectory, file] error:&error];
            if (!success || error) {
                NSLog(@"Remove file error %@", error);
            }
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSString *megaURLString = @"https://mega.co.nz/";
    
    NSString *afterSlashesString = [[url absoluteString] substringFromIndex:7]; // "mega://" = 7 characters
    
    if ([afterSlashesString isEqualToString:@""] || (afterSlashesString.length < 2)) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"invalidLink", nil)];
        return YES;
    }
    
    NSString *megaURLTypeString = [afterSlashesString substringToIndex:2]; // mega://"#!"
    BOOL isFileLink = [megaURLTypeString isEqualToString:@"#!"];
    if (isFileLink) {
        NSString *fileLinkCodeString = [afterSlashesString substringFromIndex:2]; // mega://#!"xxxxxxxx..."!
        
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"!"];
        BOOL isEncryptedFileLink = ([fileLinkCodeString rangeOfCharacterFromSet:characterSet].location == NSNotFound);
        if (isEncryptedFileLink) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"fileEncrypted", @"File encrypted")
                                                                message:NSLocalizedString(@"fileEncryptedMessage", @"This function is not available. For the moment you can't import or download an encrypted file.")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                      otherButtonTitles:nil];
            [alertView show];
            [self checkingRootViewController];
            
        } else {
            FileLinkViewController *fileLinkVC = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkViewControllerID"];
            
            NSString *megaFileLinkURLString = [megaURLString stringByAppendingString:afterSlashesString];
            [fileLinkVC setFileLinkString:megaFileLinkURLString];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:fileLinkVC];
            self.window.rootViewController = navigationController;
        }
        
        return YES;
    }
    
    megaURLTypeString = [afterSlashesString substringToIndex:3]; // mega://"#F!"
    BOOL isFolderLink = [megaURLTypeString isEqualToString:@"#F!"];
    if (isFolderLink) {
        NSString *folderLinkCodeString = [afterSlashesString substringFromIndex:3]; // mega://#F!"xxxxxxxx..."!
        
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"!"];
        BOOL isEncryptedFolderLink = ([folderLinkCodeString rangeOfCharacterFromSet:characterSet].location == NSNotFound);
        if (isEncryptedFolderLink) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"folderEncrypted", @"Folder encrypted")
                                                                message:NSLocalizedString(@"folderEncryptedMessage", @"This function is not available. For the moment you can't import or download an encrypted folder.")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                      otherButtonTitles:nil];
            [alertView show];
            [self checkingRootViewController];
            
        } else {
            UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
            
            FolderLinkViewController *folderlinkVC = navigationController.viewControllers.firstObject;;
            
            NSString *megaFolderLinkString = [megaURLString stringByAppendingString:afterSlashesString];
            [folderlinkVC setIsFolderRootNode:YES];
            [folderlinkVC setFolderLinkString:megaFolderLinkString];
            
            [self.window setRootViewController:navigationController];
        }
        
        return YES;
    }
    
    megaURLTypeString = [afterSlashesString substringToIndex:7]; // mega://"confirm"
    BOOL isConfirmationLink = [megaURLTypeString isEqualToString:@"confirm"];
    if (isConfirmationLink) {
        NSString *megaURLConfirmationString = [megaURLString stringByAppendingString:@"#"];
        megaURLConfirmationString = [megaURLConfirmationString stringByAppendingString:afterSlashesString];
        
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLConfirmationString];
        return YES;
    }
    
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"invalidLink", nil)];
    return YES;
}

#pragma mark - Push Notifications

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}
#endif

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken{
    NSString* newToken = [deviceToken description];
    NSLog(@"device token %@", newToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[CameraUploads syncManager] getAllAssetsForUpload];
    [self startBackgroundTask];
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark - Private

- (void)setupAppearance {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UIColor *whiteColor = [UIColor whiteColor];
    
    NSMutableDictionary *titleTextAttributesDictionary = [[NSMutableDictionary alloc] init];
    [titleTextAttributesDictionary setValue:whiteColor forKey:NSForegroundColorAttributeName];
    [[UINavigationBar appearance] setTitleTextAttributes:titleTextAttributesDictionary];
    
    [[UINavigationBar appearance] setBarTintColor:megaRed];
    [[UINavigationBar appearance] setTintColor:whiteColor];
    
    [[UIBarButtonItem appearance] setTintColor:whiteColor];
    
    [[UITabBar appearance] setBarTintColor:[UIColor blackColor]];
    [[UITabBar appearance] setTintColor:whiteColor];
}

- (void)checkingRootViewController {
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        if (![self.window.rootViewController isKindOfClass:[MainTabBarController class]]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            [self.window setRootViewController:mainTBC];
//            [mainTBC setSelectedIndex:1]; //0 = Cloud, 1 = Offline, 2 = Contacts, 3 = Settings
        }
    } else {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
        [self.window setRootViewController:viewController];
    }
}

- (void)startBackgroundTask {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[CameraUploads syncManager].assetUploadArray.count];
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeFetchNodes:
            if (!self.isLoginFromView) {
                [SVProgressHUD showWithStatus:NSLocalizedString(@"updatingNodes", @"Updating nodes...") maskType:SVProgressHUDMaskTypeClear];
            }
            break;
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiESid) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"loggetOutTitle", nil) message:NSLocalizedString(@"loggedOutFromAnotherLocation", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
            [Helper logout];
        }
        
        if (([error type] == MEGAErrorTypeApiENoent) && ([request type] == MEGARequestTypeQuerySignUpLink)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"Error")
                                                            message:NSLocalizedString(@"accountAlreadyConfirmed", @"Account already confirmed.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            if (!self.isLoginFromView) {
                [[MEGASdkManager sharedMEGASdk] fetchNodes];
            }
            break;
        }
            
        case MEGARequestTypeQuerySignUpLink: {
            ConfirmAccountViewController *confirmAccountVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ConfirmAccountViewControllerID"];
            [confirmAccountVC setConfirmationLinkString:[request link]];
            [confirmAccountVC setEmailString:[request email]];
            
            self.window.rootViewController = confirmAccountVC;
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
#endif
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
#ifdef DEBUG
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
#endif
}

@end
