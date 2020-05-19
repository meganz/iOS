
#import "MainTabBarController.h"

#import "ChatRoomsViewController.h"
#import "Helper.h"
#import "MEGANavigationController.h"
#import "MyAccountHallViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGAUserAlertList+MNZCategory.h"
#import "MessagesViewController.h"
#import "UIApplication+MNZCategory.h"
#import "MainTabBarController+CameraUpload.h"

@interface MainTabBarController () <UITabBarControllerDelegate, MEGAGlobalDelegate>

@property (nonatomic, strong) UIImageView *phoneBadgeImageView;

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
        tabBarItem.title = nil;
        tabBarItem.badgeColor = UIColor.clearColor;
        [tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName: [UIColor mnz_redMainForTraitCollection:(self.traitCollection)]} forState:UIControlStateNormal];
        [self reloadInsetsForTabBarItem:tabBarItem];
        switch (tabBarItem.tag) {
            case CLOUD:
                tabBarItem.accessibilityLabel = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                break;
                
            case PHOTOS:
                tabBarItem.accessibilityLabel = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
                break;
                
            case CHAT:
                tabBarItem.accessibilityLabel = AMLocalizedString(@"chat", @"Chat section header");
                break;
                
            case SHARES:
                tabBarItem.accessibilityLabel = AMLocalizedString(@"sharedItems", @"Title of Shared Items section");
                break;
                
            case MYACCOUNT:
                tabBarItem.accessibilityLabel = AMLocalizedString(@"myAccount", @"Title of My Account section. There you can see your account details");
                break;
        }
    }
    
    self.viewControllers = defaultViewControllersMutableArray;
    
    self.view.tintColor = [UIColor mnz_redMainForTraitCollection:(self.traitCollection)];
    
    [self setDelegate:self];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self setBadgeValueForChats];
    [self setBadgeValueForMyAccount];
    [self configurePhoneImageBadge];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tabBar bringSubviewToFront:self.phoneBadgeImageView];
    [self.tabBar invalidateIntrinsicContentSize];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [self.view setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self showCameraUploadV2MigrationScreenIfNeeded];
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager setupAppearance:self.traitCollection];
            [AppearanceManager invalidateViews];
        }
    }
    
    [self configurePhoneImageBadge];
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
    NSUInteger unseenUserAlerts = [MEGASdkManager sharedMEGASdk].userAlertList.mnz_relevantUnseenCount;
    NSUInteger total = incomingContacts + unseenUserAlerts;
    NSString *badgeValue = total ? @"⦁" : nil;
    [self setBadgeValue:badgeValue tabPosition:MYACCOUNT];
}

- (void)setBadgeValueForChats {
    NSInteger unreadChats = [MEGASdkManager sharedMEGAChatSdk] ? [MEGASdkManager sharedMEGAChatSdk].unreadChats : 0;
    NSInteger numCalls = [MEGASdkManager sharedMEGAChatSdk] ? [MEGASdkManager sharedMEGAChatSdk].numCalls : 0;
    
    NSString *badgeValue;
    self.phoneBadgeImageView.hidden = YES;
    if (MEGAReachabilityManager.isReachable && numCalls) {
        MEGAHandleList *chatRoomIDsWithCallInProgress = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusInProgress];
        self.phoneBadgeImageView.hidden = (chatRoomIDsWithCallInProgress.size > 0);
        
        badgeValue = self.phoneBadgeImageView.hidden && unreadChats ? @"⦁" : nil;
    } else {
        badgeValue = unreadChats ? @"⦁" : nil;
    }
    [self setBadgeValue:badgeValue tabPosition:CHAT];
}

- (void)setBadgeValue:(NSString *)badgeValue tabPosition:(NSInteger)tabPosition {
    if (tabPosition < self.tabBar.items.count) {
        [[self.viewControllers objectAtIndex:tabPosition] tabBarItem].badgeValue = badgeValue;
    }
}
- (void)internetConnectionChanged {
    [self setBadgeValueForChats];
}

- (void)configurePhoneImageBadge {
    if (!self.phoneBadgeImageView) {
        self.phoneBadgeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"onACall"]];
        self.phoneBadgeImageView.hidden = YES;
        [self.tabBar addSubview:self.phoneBadgeImageView];
    }
    self.phoneBadgeImageView.frame = CGRectMake(self.tabBar.frame.size.width / 2 + 10, 6, 10, 10);
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
            [messagesViewController updateUnreadLabel];
        }        
    } else if (item.changes == MEGAChatListItemChangeTypeArchived && item.unreadCount) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = api.unreadChats;
    }
}

@end
