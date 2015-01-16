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
#import "ConfirmAccountViewController.h"

#define kUserAgent @"iOS3"
#define kAppKey @"EVtjzb7R"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [MEGASdkManager setAppKey:kAppKey];
    [MEGASdkManager setUserAgent:kUserAgent];
    [MEGASdkManager sharedMEGASdk];
    [MEGASdk setLogLevel:MEGALogLevelInfo];
    
    [self setupAppearance];
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:[SSKeychain passwordForService:@"MEGA" account:@"session"] delegate:self];
        UITabBarController *tabBarVC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        self.window.rootViewController = tabBarVC;
        
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSString *megaURLString = @"https://mega.co.nz/";
    
    NSString *afterSlashString = [[url absoluteString] substringFromIndex:7]; //"mega://" = 7 characters
    
    NSString *megaURLTypeString = [afterSlashString substringToIndex:2]; //"mega://#!"
    BOOL isDownloadLink = [megaURLTypeString isEqualToString:@"#!"];
    if (isDownloadLink) {
        return YES;
    }
    
    megaURLTypeString = [afterSlashString substringToIndex:7]; //"mega://confirm"
    BOOL isConfirmationLink = [megaURLTypeString isEqualToString:@"confirm"];
    if (isConfirmationLink) {
        NSString *megaURLConfirmationString = [megaURLString stringByAppendingString:@"#"];
        megaURLConfirmationString = [megaURLConfirmationString stringByAppendingString:afterSlashString];
        
        [[MEGASdkManager sharedMEGASdk] querySignupLink:megaURLConfirmationString delegate:self];
        return YES;
    }
    
    return NO;
}

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

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeFetchNodes:
            [SVProgressHUD showWithStatus:NSLocalizedString(@"updatingNodes", @"Updating nodes...")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
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
            [[MEGASdkManager sharedMEGASdk] fetchNodesWithDelegate:self];
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
}

@end
