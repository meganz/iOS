
#import "MainTabBarController.h"

#import "ChatRoomsViewController.h"
#import "CloudDriveViewController.h"
#import "Helper.h"
#import "MEGANavigationController.h"
#import "MyAccountHallViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGAUserAlertList+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MainTabBarController+CameraUpload.h"
#import "TransfersWidgetViewController.h"
#import "MEGA-Swift.h"

#import "NSObject+Debounce.h"
@import PureLayout;

@interface MainTabBarController () <UITabBarControllerDelegate, MEGAChatCallDelegate, MEGANavigationControllerDelegate>

@property (nonatomic, assign) NSInteger unreadMessages;
@property (nonatomic, strong) UIImageView *phoneBadgeImageView;

@property (nonatomic, strong) PSAViewModel *psaViewModel;

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *defaultViewControllersMutableArray = [[NSMutableArray alloc] initWithCapacity:5];
    
    [defaultViewControllersMutableArray addObject:[self cloudDriveViewController]];
    [defaultViewControllersMutableArray addObject:[self photosViewController]];
    [defaultViewControllersMutableArray addObject:[self homeViewController]];
    [defaultViewControllersMutableArray addObject:[self chatViewController]];
    [defaultViewControllersMutableArray addObject:[self SharedItemsViewController]];
    
    for (NSInteger i = 0; i < [defaultViewControllersMutableArray count]; i++) {
        MEGANavigationController *navigationController = defaultViewControllersMutableArray[i];
        navigationController.navigationDelegate = self;
        UITabBarItem *tabBarItem = navigationController.tabBarItem;
        tabBarItem.title = nil;
        [self reloadInsetsForTabBarItem:tabBarItem];
        tabBarItem.accessibilityLabel = [[Tab alloc] initWithTabType:i].title;
    }
    
    self.viewControllers = defaultViewControllersMutableArray;
    
    [self setDelegate:self];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    [self configProgressView];
    
    [self setBadgeValueForChats];
    [self configurePhoneImageBadge];
    
    self.selectedViewController = [defaultViewControllersMutableArray objectAtIndex:[TabManager getPreferenceTab].tabType];
    [self showPSAViewIfNeeded];
    
    [AppearanceManager setupTabbar:self.tabBar traitCollection:self.traitCollection];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tabBar bringSubviewToFront:self.phoneBadgeImageView];
    [self.tabBar invalidateIntrinsicContentSize];
    [self refreshBottomConstraint];
    
    if (self.psaViewModel != nil) {
        [self adjustPSAFrameIfNeededWithPsaViewModel:self.psaViewModel];
    }
    
    [self updatePhoneImageBadgeFrame];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(showPSAViewIfNeeded)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
    [self.view setNeedsLayout];
    [AudioPlayerManager.shared addMiniPlayerHandler:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [AudioPlayerManager.shared removeMiniPlayerHandler:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self showCameraUploadV2MigrationScreenIfNeeded];
    
    [self shouldShowMiniPlayer];
    
    [TransfersWidgetViewController.sharedTransferViewController bringProgressToFrontKeyWindowIfNeeded];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        
        //Force appearance changes on the tab bar
        [AppearanceManager setupTabbar:self.tabBar traitCollection:self.traitCollection];
    }
    
    [self configurePhoneImageBadge];
    for (UITabBarItem *tabBarItem in self.tabBar.items) {
        [self reloadInsetsForTabBarItem:tabBarItem];
    }
}

#pragma mark - Public

- (void)openChatRoomNumber:(NSNumber *)chatNumber {
    if (chatNumber) {
        self.selectedIndex = TabTypeChat;
        MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeChat];
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

- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID {
    self.selectedIndex = TabTypeChat;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeChat];
    ChatRoomsViewController *chatRoomsVC = navigationController.viewControllers.firstObject;
    
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    if (rootViewController.presentedViewController) {
        [rootViewController dismissViewControllerAnimated:YES completion:^{
            [chatRoomsVC openChatRoomWithPublicLink:publicLink chatID:chatID];
        }];
    } else {
        [chatRoomsVC openChatRoomWithPublicLink:publicLink chatID:chatID];
    }
}

- (void)showAchievements {
    if (![[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
        return;
    }
    
    self.selectedIndex = TabTypeHome;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeHome];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    [homeRouting showAchievements];
}

- (void)showOfflineAndPresentFileWithHandle:(NSString * _Nullable )base64handle {
    self.selectedIndex = TabTypeHome;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeHome];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    if (base64handle) {
        [homeRouting showOfflineFile:base64handle];
    } else {
        [homeRouting showOfflines];
    }
}

- (void)showFavouritesNodeWithHandle:(NSString * _Nullable )base64handle {
    self.selectedIndex = TabTypeHome;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeHome];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    if (base64handle) {
        [homeRouting showFavouritesNode:base64handle];
    } else {
        [homeRouting showFavourites];
    }
}

- (void)showRecents {
    self.selectedIndex = TabTypeHome;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeHome];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    [homeRouting showRecents];
}

- (void)showUploadFile {
    self.selectedIndex = TabTypeCloudDrive;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeCloudDrive];
    CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
    [cloudDriveVC presentUploadOptions];
}

- (void)showScanDocument {
    self.selectedIndex = TabTypeCloudDrive;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeCloudDrive];
    CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
    [cloudDriveVC presentScanDocument];
}

- (void)showStartConversation {
    self.selectedIndex = TabTypeChat;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:TabTypeChat];
    ChatRoomsViewController *chatRoomsViewController = navigationController.viewControllers.firstObject;
    [chatRoomsViewController showStartConversation];
}

- (void)showAddContact {
    InviteContactViewController *inviteContactVC = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
    MEGANavigationController *navigation = [MEGANavigationController.alloc initWithRootViewController:inviteContactVC];
    [navigation addLeftDismissButtonWithText:NSLocalizedString(@"close", @"A button label. The button allows the user to close the conversation.")];
    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)configProgressView {
    [TransfersWidgetViewController.sharedTransferViewController configProgressIndicator];
    [TransfersWidgetViewController.sharedTransferViewController setProgressViewInKeyWindow];
}

- (void)shouldUpdateProgressViewLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:[ProgressIndicatorView class]]) {
                CGFloat bottomConstant = [AudioPlayerManager.shared isPlayerAlive] ? -120.0 : -60.0;
                [TransfersWidgetViewController.sharedTransferViewController updateProgressViewWithBottomConstant:bottomConstant];
                
                [UIView animateWithDuration:0.3 animations:^{
                    [subview layoutIfNeeded];
                }];
            }
        }
    });
}

#pragma mark - Private

- (void)reloadInsetsForTabBarItem:(UITabBarItem *)tabBarItem {
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        tabBarItem.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    }
}

- (void)setBadgeValueForChats {
    NSInteger unreadChats = [MEGASdkManager sharedMEGAChatSdk] ? [MEGASdkManager sharedMEGAChatSdk].unreadChats : 0;
    NSInteger numCalls = [MEGASdkManager sharedMEGAChatSdk] ? [MEGASdkManager sharedMEGAChatSdk].numCalls : 0;
    
    self.unreadMessages = unreadChats;
    
    NSString *badgeValue;
    
    if (MEGAReachabilityManager.isReachable && numCalls > 0) {
        MEGAHandleList *chatRoomIDsWithCallInProgress = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusInProgress];
        self.phoneBadgeImageView.hidden = !(chatRoomIDsWithCallInProgress.size > 0) || self.unreadMessages > 0;
        
        badgeValue = self.phoneBadgeImageView.hidden && unreadChats ? @"⦁" : nil;
    } else {
        self.phoneBadgeImageView.hidden = YES;
        badgeValue = unreadChats ? @"⦁" : nil;
    }
    
    [self setBadgeValue:badgeValue tabPosition:TabTypeChat];
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
}

- (UIViewController *)cloudDriveViewController {
    MEGANavigationController *cloudDriveNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController];
    if ([[cloudDriveNavigationController.viewControllers firstObject] conformsToProtocol:@protocol(MyAvatarPresenterProtocol)]) {
        [[cloudDriveNavigationController.viewControllers firstObject] configureMyAvatarManager];
    }
    return cloudDriveNavigationController;
}

- (UIViewController *)photosViewController {
    if (@available(iOS 14.0, *)) {
        return [self photoAlbumViewController];
    } else {
        return [self photoViewController];
    }
}

- (UIViewController *)homeViewController {
    return [HomeScreenFactory.new createHomeScreenFrom:self];
}

- (UIViewController *)chatViewController {
    MEGANavigationController *chatNavigationController = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateInitialViewController];
    if ([[chatNavigationController.viewControllers firstObject] conformsToProtocol:@protocol(MyAvatarPresenterProtocol)]) {
        [[chatNavigationController.viewControllers firstObject] configureMyAvatarManager];
    }
    return chatNavigationController;
}

- (UIViewController *)SharedItemsViewController {
    MEGANavigationController *sharedItemsNavigationController = [[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController];
    if ([[sharedItemsNavigationController.viewControllers firstObject] conformsToProtocol:@protocol(MyAvatarPresenterProtocol)]) {
        [[sharedItemsNavigationController.viewControllers firstObject] configureMyAvatarManager];
    }
    return sharedItemsNavigationController;
}

- (void)showPSAViewIfNeeded {
    if (self.psaViewModel == nil) {
        self.psaViewModel = [self createPSAViewModel];
    }
    
    [self showPSAViewIfNeeded:self.psaViewModel];
}

- (void)updatePhoneImageBadgeFrame {
    UITabBarItem *item = self.tabBar.items[TabTypeChat];
    CGFloat iconWidth = item.image.size.width;
    CGRect frame = [self frameForTabInTabBar:self.tabBar withIndex: TabTypeChat];
    CGFloat originX = frame.origin.x + (frame.size.width-iconWidth) / 2 + iconWidth;
    
    self.phoneBadgeImageView.frame = CGRectMake(originX-6, 6, 10, 10);
}

- (CGRect)frameForTabInTabBar:(UITabBar*)tabBar withIndex:(NSUInteger)index {
    NSUInteger currentTabIndex = 0;
    
    for (UIView* subView in tabBar.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            if (currentTabIndex == index)
                return subView.frame;
            else
                currentTabIndex++;
        }
    }
    
    return CGRectNull;
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    if (item.changes == MEGAChatListItemChangeTypeUnreadCount) {
        [self debounce:@selector(setBadgeValueForChats) delay:0.1];
        if ([[self.selectedViewController visibleViewController] isKindOfClass:[ChatViewController class]]) {
            ChatViewController *chatViewController = (ChatViewController *)[self.selectedViewController visibleViewController];
            [chatViewController updateUnreadLabel];
        }
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    switch (call.status) {
        case MEGAChatCallStatusInProgress:
            self.phoneBadgeImageView.hidden = self.unreadMessages > 0;
            break;
            
        case MEGAChatCallStatusDestroyed:
        case MEGAChatCallStatusTerminatingUserParticipation:
            self.phoneBadgeImageView.hidden = ![[MEGASdkManager sharedMEGAChatSdk] mnz_existsActiveCall];
            break;
            
        default:
            break;
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self showPSAViewIfNeeded];
}

#pragma mark - MEGANavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController {
    if (self.psaViewModel != nil) {
        [self hidePSAView:viewController.hidesBottomBarWhenPushed psaViewModel:self.psaViewModel];
    }
}
@end
