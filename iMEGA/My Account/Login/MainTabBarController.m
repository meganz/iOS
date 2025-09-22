#import "MainTabBarController.h"

#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "UIApplication+MNZCategory.h"
#import "MainTabBarController+CameraUpload.h"
#import "TransfersWidgetViewController.h"
#import "MEGA-Swift.h"

#import "NSObject+Debounce.h"

#import "LocalizationHelper.h"
@import MEGAUIKit;

@interface MainTabBarController () < MEGAGlobalDelegate>

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadTabViewControllers];
    [MEGAChatSdk.shared addChatDelegate:self];
    [self addMEGAGlobalDelegate];
    [self setupBottomOverlayIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tabBar bringSubviewToFront:self.phoneBadgeImageView];
    [self.tabBar invalidateIntrinsicContentSize];
    [self refreshBottomConstraint];
    [self.tabBar setNeedsLayout];
    [self.tabBar layoutIfNeeded];
    [self updateBadgeLayoutAt:[TabManager chatTabIndex]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(handleApplicationWillEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
    [self.view setNeedsLayout];
    [self registerMiniPlayerHandler];
    [self forceTabBarPositionToBottomIfNeeded];
    
    [self refreshMiniPlayerVisibility];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self unregisterMiniPlayerHandler];
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
        [AppearanceManager setupTabbar:self.tabBar];
    }
    [self updatePhoneImageBadgeFrame];
}

#pragma mark - Public

- (void)openChatRoomNumber:(NSNumber *)chatNumber {
    if (chatNumber) {
        [self openChatRoomWithChatId:chatNumber.unsignedLongLongValue];
    }
}

- (void)showAchievements {
    [self showAchievementsScreen];
}

- (void)showOfflineAndPresentFileWithHandle:(NSString * _Nullable )base64handle {
    NSInteger homeTabIndex = [TabManager homeTabIndex];
    self.selectedIndex = homeTabIndex;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:homeTabIndex];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    if (base64handle) {
        [homeRouting showOfflineFile:base64handle];
    } else {
        [homeRouting showOfflines];
    }
}

- (void)showFavouritesNodeWithHandle:(NSString * _Nullable )base64handle {
    NSInteger homeTabIndex = [TabManager homeTabIndex];
    self.selectedIndex = homeTabIndex;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:homeTabIndex];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    if (base64handle) {
        [homeRouting showFavouritesNode:base64handle];
    } else {
        [homeRouting showFavourites];
    }
}

- (void)showRecents {
    NSInteger homeTabIndex = [TabManager homeTabIndex];
    self.selectedIndex = homeTabIndex;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:homeTabIndex];

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
                CGFloat bottomConstant = [self updateTransferWidgetBottomConstraint];
                [TransfersWidgetViewController.sharedTransferViewController updateProgressViewWithBottomConstant:bottomConstant];
                
                [UIView animateWithDuration:0.3 animations:^{
                    [subview layoutIfNeeded];
                }];
            }
        }
    });
}

#pragma mark - Private

- (void)setBadgeValue:(NSString *)badgeValue tabPosition:(NSInteger)tabPosition {
    if (tabPosition < self.tabBar.items.count) {
        [[self.viewControllers objectAtIndex:tabPosition] tabBarItem].badgeValue = badgeValue;
    }
}
- (void)internetConnectionChanged {
    [self updateBadgeValueForChats];
}

- (UIViewController *)photosViewController {
    return [self photoAlbumViewController];
}

- (UIViewController *)SharedItemsViewController {
    MEGANavigationController *sharedItemsNavigationController = [[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController];
    return sharedItemsNavigationController;
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    if (item.changes == MEGAChatListItemChangeTypeUnreadCount) {
        [self debounce:@selector(updateBadgeValueForChats) delay:0.1];
    }
}

@end
