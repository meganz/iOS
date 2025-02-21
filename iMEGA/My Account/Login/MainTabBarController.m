#import "MainTabBarController.h"

#import "CloudDriveViewController.h"
#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "UIApplication+MNZCategory.h"
#import "MainTabBarController+CameraUpload.h"
#import "TransfersWidgetViewController.h"
#import "MEGA-Swift.h"

#import "NSObject+Debounce.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

@interface MainTabBarController () < MEGAGlobalDelegate>

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadTabViewControllers];
    [MEGAChatSdk.shared addChatDelegate:self];
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    
    [self setupBottomOverlayIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tabBar bringSubviewToFront:self.phoneBadgeImageView];
    [self.tabBar invalidateIntrinsicContentSize];
    [self refreshBottomConstraint];
    [self updatePhoneImageBadgeFrame];
    [self.tabBar setNeedsLayout];
    [self.tabBar layoutIfNeeded];
    [self.tabBar updateBadgeLayoutAt:TabTypeChat];
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
    [self forceTabBarPositionToBottomIfNeeded];
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
        [self openChatRoomWithChatId:chatNumber.unsignedLongLongValue];
    }
}

- (void)showAchievements {
    if (![MEGASdk.shared isAchievementsEnabled]) {
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

- (void)showAddContact {
    InviteContactViewController *inviteContactVC = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
    MEGANavigationController *navigation = [MEGANavigationController.alloc initWithRootViewController:inviteContactVC];
    [navigation addLeftDismissButtonWithText:LocalizedString(@"close", @"A button label. The button allows the user to close the conversation.")];
    [self presentViewController:navigation animated:YES completion:nil];
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

- (void)setBadgeValue:(NSString *)badgeValue tabPosition:(NSInteger)tabPosition {
    if (tabPosition < self.tabBar.items.count) {
        [[self.viewControllers objectAtIndex:tabPosition] tabBarItem].badgeValue = badgeValue;
    }
}
- (void)internetConnectionChanged {
    [self setBadgeValueForChats];
}

- (UIViewController *)photosViewController {
    return [self photoAlbumViewController];
}

- (UIViewController *)SharedItemsViewController {
    MEGANavigationController *sharedItemsNavigationController = [[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController];
    if ([[sharedItemsNavigationController.viewControllers firstObject] conformsToProtocol:@protocol(MyAvatarPresenterProtocol)]) {
        [[sharedItemsNavigationController.viewControllers firstObject] configureMyAvatarManager];
    }
    return sharedItemsNavigationController;
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
    if (item.changes == MEGAChatListItemChangeTypeUnreadCount) {
        [self debounce:@selector(setBadgeValueForChats) delay:0.1];
        [self updateUnreadChatsOnBackButton];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self updateSharedItemsTabBadgeIfNeeded:nodeList];
}

@end
