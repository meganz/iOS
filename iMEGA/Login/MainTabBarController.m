
#import "MainTabBarController.h"

#import <UserNotifications/UserNotifications.h>

#import "CallViewController.h"
#import "ChatRoomsViewController.h"
#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAProviderDelegate.h"
#import "MEGAChatCall+MNZCategory.h"
#import "MyAccountHallViewController.h"
#import "MEGAUserAlertList+MNZCategory.h"
#import "MessagesViewController.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

@interface MainTabBarController () <UITabBarControllerDelegate, MEGAGlobalDelegate, MEGAChatCallDelegate>

@property (nonatomic, strong) MEGAProviderDelegate *megaProviderDelegate;
@property (getter=shouldReportOutgoingCall) BOOL reportOutgoingCall;
@property (nonatomic, strong) NSMutableDictionary *missedCallsDictionary;
@property (nonatomic, strong) NSMutableArray *currentNotifications;

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *defaultViewControllersMutableArray = [[NSMutableArray alloc] initWithCapacity:5];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateInitialViewController]];
    
    for (NSInteger i = 0; i < [defaultViewControllersMutableArray count]; i++) {
        UITabBarItem *tabBarItem = [[defaultViewControllersMutableArray objectAtIndex:i] tabBarItem];
        if (@available(iOS 10.0, *)) {
            tabBarItem.badgeColor = UIColor.clearColor;
            [tabBarItem setBadgeTextAttributes:@{ NSForegroundColorAttributeName: UIColor.mnz_redMain } forState:UIControlStateNormal];
        }
        [self reloadInsetsForTabBarItem:tabBarItem];
        switch (tabBarItem.tag) {
            case CLOUD:
                tabBarItem.image = [[UIImage imageNamed:@"cloudDriveIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                tabBarItem.selectedImage = [UIImage imageNamed:@"cloudDriveSelectedIcon"];
                tabBarItem.accessibilityLabel = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                break;
                
            case PHOTOS:
                tabBarItem.image = [[UIImage imageNamed:@"cameraUploadsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                tabBarItem.selectedImage = [UIImage imageNamed:@"cameraUploadsSelectedIcon"];
                tabBarItem.accessibilityLabel = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
                break;
                
            case CHAT:
                tabBarItem.image = [[UIImage imageNamed:@"chatIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                tabBarItem.selectedImage = [UIImage imageNamed:@"chatSelectedIcon"];
                tabBarItem.accessibilityLabel = AMLocalizedString(@"chat", @"Chat section header");
                break;
                
            case SHARES:
                tabBarItem.image = [[UIImage imageNamed:@"sharedItemsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                tabBarItem.selectedImage = [UIImage imageNamed:@"sharedItemsSelectedIcon"];
                tabBarItem.accessibilityLabel = AMLocalizedString(@"sharedItems", @"Title of Shared Items section");
                break;
                
            case MYACCOUNT:
                tabBarItem.image = [[UIImage imageNamed:@"myAccountIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                tabBarItem.selectedImage = [UIImage imageNamed:@"myAccountSelectedIcon"];
                tabBarItem.accessibilityLabel = AMLocalizedString(@"myAccount", @"Title of My Account section. There you can see your account details");
                break;
        }
    }
    
    self.viewControllers = defaultViewControllersMutableArray;
    
    self.view.tintColor = UIColor.mnz_redMain;
    
    [self setDelegate:self];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    [self setBadgeValueForChats];
    [self setBadgeValueForMyAccount];
    
    if (@available(iOS 10.0, *)) {
        _megaCallManager = [[MEGACallManager alloc] init];
        _megaProviderDelegate = [[MEGAProviderDelegate alloc] initWithMEGACallManager:self.megaCallManager];
    }
    
    _missedCallsDictionary = [[NSMutableDictionary alloc] init];
    _currentNotifications = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (@available(iOS 10.0, *)) {} else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentCallViewControllerIfThereIsAnIncomingCall) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}
    
- (BOOL)shouldAutorotate {
    if ([self.selectedViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.selectedViewController shouldAutorotate];
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([self.selectedViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
            if ([self.selectedViewController isEqual:self.moreNavigationController]) {
                return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
            }
            
            return [self.selectedViewController supportedInterfaceOrientations];
        }
        
        if ([self.selectedViewController isEqual:self.moreNavigationController]) {
            return UIInterfaceOrientationMaskAll;
        }
        return [self.selectedViewController supportedInterfaceOrientations];
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    for (UITabBarItem *tabBarItem in self.tabBar.items) {
        [self reloadInsetsForTabBarItem:tabBarItem];
    }
}

#pragma mark - Public

- (void)openChatRoomNumber:(NSNumber *)chatNumber {
    if (chatNumber) {
        self.selectedIndex = CHAT;
        MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:CHAT];
        ChatRoomsViewController *chatRoomsVC = navigationController.viewControllers.firstObject;
        
        if ([MEGASdkManager sharedMEGAChatSdk].numCalls == 0) {
            UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
            if (rootViewController.presentedViewController) {
                [rootViewController dismissViewControllerAnimated:YES completion:^{
                    [chatRoomsVC openChatRoomWithID:chatNumber.unsignedLongLongValue];
                }];
            } else {
                [chatRoomsVC openChatRoomWithID:chatNumber.unsignedLongLongValue];
            }
        }
    }
}

- (void)showAchievements {
    self.selectedIndex = MYACCOUNT;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:MYACCOUNT];
    MyAccountHallViewController *myAccountHallVC = navigationController.viewControllers.firstObject;
    if ([[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
        [myAccountHallVC openAchievements];
    }
}

- (void)showOffline {
    self.selectedIndex = MYACCOUNT;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:MYACCOUNT];
    MyAccountHallViewController *myAccountHallVC = navigationController.viewControllers.firstObject;
    [myAccountHallVC openOffline];
}

#pragma mark - Private

- (void)reloadInsetsForTabBarItem:(UITabBarItem *)tabBarItem {
    if (@available(iOS 11.0, *)) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            tabBarItem.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        } else {
            tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
        }
    } else {
        tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    }
}

- (void)setBadgeValueForMyAccount {
    int incomingContacts = [[MEGASdkManager sharedMEGASdk] incomingContactRequests].size.intValue;
    NSUInteger unseenUserAlerts = [MEGASdkManager sharedMEGASdk].userAlertList.mnz_unseenCount;
    
    NSString *badgeValue;
    NSUInteger total = incomingContacts + unseenUserAlerts;
    if (@available(iOS 10.0, *)) {
        badgeValue = total ? @"⦁" : nil;
    } else {
        badgeValue = total ? [NSString stringWithFormat:@"%tu", total] : nil;
    }
    [self setBadgeValue:badgeValue tabPosition:MYACCOUNT];
}

- (void)setBadgeValueForChats {
    NSInteger unreadChats = ([MEGASdkManager sharedMEGAChatSdk] != nil) ? [[MEGASdkManager sharedMEGAChatSdk] unreadChats] : 0;
    
    NSString *badgeValue;
    if (@available(iOS 10.0, *)) {
        badgeValue = unreadChats ? @"⦁" : nil;
    } else {
        badgeValue = unreadChats ? [NSString stringWithFormat:@"%td", unreadChats] : nil;
    }
    [self setBadgeValue:badgeValue tabPosition:CHAT];
}

- (void)setBadgeValue:(NSString *)badgeValue tabPosition:(NSInteger)tabPosition {
    if (tabPosition < self.tabBar.items.count) {
        [[self.viewControllers objectAtIndex:tabPosition] tabBarItem].badgeValue = badgeValue;
    }
}

- (void)presentRingingCall:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    if (call.status == MEGAChatCallStatusRingIn) {
        MEGAChatRoom *chatRoom = [api chatRoomForChatId:call.chatId];
        if (@available(iOS 10.0, *)) {
            NSUUID *uuid = [[NSUUID alloc] init];
            call.uuid = uuid;
            
            uint64_t peerHandle = [chatRoom peerHandleAtIndex:0];
            NSString *email = [chatRoom peerEmailByHandle:peerHandle];
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:email];
            
            [self.megaProviderDelegate reportIncomingCall:call user:user];
        } else {
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
                callVC.chatRoom  = chatRoom;
                callVC.videoCall = call.hasRemoteVideo;
                callVC.callType = CallTypeIncoming;
                [UIApplication.mnz_presentingViewController presentViewController:callVC animated:YES completion:nil];
            } else {
                MEGAChatRoom *chatRoom = [api chatRoomForChatId:call.chatId];
                UILocalNotification* localNotification = [[UILocalNotification alloc] init];
                localNotification.alertTitle = @"MEGA";
                localNotification.soundName = @"incoming_voice_video_call_iOS9.mp3";
                localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                localNotification.alertBody = [NSString stringWithFormat:@"%@: %@", chatRoom.title, AMLocalizedString(@"Incoming call", @"notification subtitle of incoming calls")];
                localNotification.userInfo = @{@"chatId" : @(call.chatId),
                                               @"callId" : @(call.callId)
                                               };
                [self.currentNotifications addObject:localNotification];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
        }
    }
}


- (void)presentCallViewControllerIfThereIsAnIncomingCall {
    NSArray *callsKeys = [self.missedCallsDictionary allKeys];
    if (callsKeys.count > 0) {
        MEGAChatCall *call = [self.missedCallsDictionary objectForKey:[callsKeys objectAtIndex:0]];
        
        [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];
        
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:call.chatId];
        CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
        callVC.chatRoom  = chatRoom;
        callVC.videoCall = call.hasRemoteVideo;
        callVC.callType = CallTypeIncoming;
        [UIApplication.mnz_presentingViewController presentViewController:callVC animated:YES completion:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self setBadgeValueForMyAccount];
}

- (void)onUserAlertsUpdate:(MEGASdk *)api userAlertList:(MEGAUserAlertList *)userAlertList {
    [self setBadgeValueForMyAccount];
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    if (item.changes == MEGAChatListItemChangeTypeUnreadCount) {
        [self setBadgeValueForChats];
        if ([[self.selectedViewController visibleViewController] isKindOfClass:[MessagesViewController class]]) {
            MessagesViewController *messagesViewController = (MessagesViewController *)[self.selectedViewController visibleViewController];
            if (messagesViewController.chatRoom.chatId != item.chatId) {
                [messagesViewController updateUnreadLabel];
            }
        }        
    } else if (item.changes == MEGAChatListItemChangeTypeArchived && item.unreadCount) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = api.unreadChats;
    }
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    switch (call.status) {
        case MEGAChatCallStatusInitial:
            break;
            
        case MEGAChatCallStatusHasLocalStream:
            break;
            
        case MEGAChatCallStatusRequestSent:
            if (@available(iOS 10.0, *)) {
                self.reportOutgoingCall = YES;
                self.megaProviderDelegate.outgoingCall = YES;
            }
            break;
            
        case MEGAChatCallStatusRingIn: {
            [self.missedCallsDictionary setObject:call forKey:@(call.chatId)];
            [DevicePermissionsHelper audioPermissionWithCompletionHandler:^(BOOL granted) {
                if (granted) {
                    if (call.hasRemoteVideo) {
                        [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                            if (granted) {
                                [self presentRingingCall:api call:[api chatCallForCallId:call.callId]];
                            } else {
                                [self presentViewController:DevicePermissionsHelper.videoPermissionAlertController animated:YES completion:nil];
                            }
                        }];
                    } else {
                        [self presentRingingCall:api call:[api chatCallForCallId:call.callId]];
                    }
                } else {
                    [self presentViewController:DevicePermissionsHelper.audioPermissionAlertController animated:YES completion:nil];
                }
            }];
            break;
        }
            
        case MEGAChatCallStatusJoining:
            if (@available(iOS 10.0, *)) {
                self.megaProviderDelegate.outgoingCall = NO;
            }
            break;
            
        case MEGAChatCallStatusInProgress:
            if (@available(iOS 10.0, *)) {
                if (self.shouldReportOutgoingCall) {
                    [self.megaProviderDelegate reportOutgoingCall:call];
                    self.reportOutgoingCall = NO;
                }
            }
            [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];

            break;
        case MEGAChatCallStatusTerminating:
            break;
        case MEGAChatCallStatusDestroyed:
            if (call.isLocalTermCode) {
                [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];
            }
            if ([self.missedCallsDictionary objectForKey:@(call.chatId)]) {
                MEGAChatRoom *chatRoom = [api chatRoomForChatId:call.chatId];
                if (@available(iOS 10.0, *)) {
                    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
                        NSInteger missedVideoCalls, missedAudioCalls;
                        if (call.hasRemoteVideo) {
                            missedVideoCalls = 1;
                            missedAudioCalls = 0;
                        } else {
                            missedAudioCalls = 1;
                            missedVideoCalls = 0;
                        }                        
                        
                        for (UNNotification *notification in notifications) {
                            if ([[MEGASdk base64HandleForUserHandle:call.chatId] isEqualToString:notification.request.identifier]) {
                                missedAudioCalls = [notification.request.content.userInfo[@"missedAudioCalls"] integerValue];
                                missedVideoCalls = [notification.request.content.userInfo[@"missedVideoCalls"] integerValue];
                                if (call.hasRemoteVideo) {
                                    missedVideoCalls++;
                                } else {
                                    missedAudioCalls++;
                                }
                                break;
                            }
                        }
                        
                        NSString *notificationText = [NSString mnz_stringByMissedAudioCalls:missedAudioCalls andMissedVideoCalls:missedVideoCalls];
                        
                        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                        content.title = chatRoom.title;
                        content.body = notificationText;
                        content.sound = [UNNotificationSound defaultSound];
                        content.userInfo = @{@"missedAudioCalls" : @(missedAudioCalls),
                                             @"missedVideoCalls" : @(missedVideoCalls),
                                             @"chatId" : @(call.chatId)
                                             };
                        content.categoryIdentifier = @"nz.mega.chat.call";
                        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                        NSString *identifier = [MEGASdk base64HandleForUserHandle:chatRoom.chatId];
                        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                            if (error) {
                                MEGALogError(@"Add NotificationRequest failed with error: %@", error);
                            }
                        }];
                    }];
                } else {
                    [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];
                    
                    for(UILocalNotification *notification in self.currentNotifications) {
                        if([notification.userInfo[@"callId"] unsignedLongLongValue] == call.callId) {
                            [[UIApplication sharedApplication] cancelLocalNotification:notification];
                            [self.currentNotifications removeObject:notification];
                            break;
                        }
                    }
                    
                    NSString *alertBody = [NSString mnz_stringByMissedAudioCalls:(call.hasRemoteVideo ? 0 : 1) andMissedVideoCalls:(call.hasRemoteVideo ? 1 : 0)];
                    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertTitle = @"MEGA";
                    localNotification.alertBody = [NSString stringWithFormat:@"%@: %@", chatRoom.title, alertBody];
                    localNotification.userInfo = @{@"chatId" : @(call.chatId),
                                                   @"callId" : @(call.callId)
                                                   };
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
            }
            
            if (@available(iOS 10.0, *)) {
                [self.megaProviderDelegate reportEndCall:call];
            }
            
            break;
            
        default:
            break;
    }
}

@end
