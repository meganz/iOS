
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
#import <PureLayout/PureLayout.h>
#import "TransfersWidgetViewController.h"
#import "MEGA-Swift.h"

#import "NSObject+Debounce.h"

@interface MainTabBarController () <UITabBarControllerDelegate, MEGAChatCallDelegate, MEGANavigationControllerDelegate, PSAViewRouterDelegate>

@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UIImageView *phoneBadgeImageView;

@property (nonatomic, strong) PSAViewRouter *psaRouter;

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIViewController *homeViewController = [self homeViewController];
    NSMutableArray *defaultViewControllersMutableArray = [[NSMutableArray alloc] initWithCapacity:5];

    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:homeViewController];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController]];
    
    for (NSInteger i = 0; i < [defaultViewControllersMutableArray count]; i++) {
        MEGANavigationController *navigationController = defaultViewControllersMutableArray[i];
        navigationController.navigationDelegate = self;
        UITabBarItem *tabBarItem = navigationController.tabBarItem;
        tabBarItem.title = nil;
        tabBarItem.badgeColor = UIColor.clearColor;
        [tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]} forState:UIControlStateNormal];
        [self reloadInsetsForTabBarItem:tabBarItem];
        switch (i) {
            case CLOUD:
                tabBarItem.accessibilityLabel = NSLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                break;
                
            case PHOTOS:
                tabBarItem.accessibilityLabel = NSLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
                break;
                
            case CHAT:
                tabBarItem.accessibilityLabel = NSLocalizedString(@"chat", @"Chat section header");
                break;
                
            case SHARES:
                tabBarItem.accessibilityLabel = NSLocalizedString(@"sharedItems", @"Title of Shared Items section");
                break;
                
            case HOME:
                tabBarItem.accessibilityLabel = NSLocalizedString(@"Home", @"Accessibility label of Home section in tabbar item");
                break;
        }
    }
    
    self.viewControllers = defaultViewControllersMutableArray;
    
    [self setDelegate:self];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];

    self.progressView = ({
        ProgressIndicatorView *view = [ProgressIndicatorView.alloc initWithFrame:CGRectMake(0, 0, 70, 70)];
        view.userInteractionEnabled = YES;
        [self.view addSubview:view];
    
        [view addGestureRecognizer:({
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapProgressView)];
        })];
        [view autoSetDimensionsToSize:CGSizeMake(70, 70)];
        [view autoPinEdgeToSuperviewSafeArea:ALEdgeRight withInset:8];
        [view autoPinEdgeToSuperviewSafeArea:ALEdgeBottom withInset:60];
        [TransfersWidgetViewController sharedTransferViewController].progressView = view;
        view.hidden = YES;
        view;
        
    });
    
    [self setBadgeValueForChats];
    [self configurePhoneImageBadge];

    self.selectedViewController = homeViewController;
    [self showPSAViewIfNeeded];
}

- (void)tapProgressView {
    TransfersWidgetViewController *transferVC = [TransfersWidgetViewController sharedTransferViewController];
    MEGANavigationController *nav = [[MEGANavigationController alloc] initWithRootViewController:transferVC];
    [nav addLeftDismissButtonWithText:NSLocalizedString(@"close", @"A button label.")];
    [self presentViewController:nav animated:YES completion:nil];
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
            
           //Force appearance changes on the tab bar
            self.tabBar.barTintColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
            self.tabBar.tintColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
            self.tabBar.unselectedItemTintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
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

- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID {
    self.selectedIndex = CHAT;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:CHAT];
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

    self.selectedIndex = HOME;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:HOME];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    [homeRouting showAchievements];
}

- (void)showOffline {
    self.selectedIndex = HOME;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:HOME];
    id<HomeRouting> homeRouting = navigationController.viewControllers.firstObject;
    [homeRouting showOfflines];
}

- (void)showUploadFile {
    self.selectedIndex = CLOUD;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:CLOUD];
    CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
    [cloudDriveVC presentUploadAlertController];
}

- (void)showScanDocument {
    self.selectedIndex = CLOUD;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:CLOUD];
    CloudDriveViewController *cloudDriveVC = navigationController.viewControllers.firstObject;
    [cloudDriveVC presentScanDocument];
}

- (void)showStartConversation {
    self.selectedIndex = CHAT;
    MEGANavigationController *navigationController = [self.childViewControllers objectAtIndex:CHAT];
    ChatRoomsViewController *chatRoomsViewController = navigationController.viewControllers.firstObject;
    [chatRoomsViewController showStartConversation];
}

- (void)showAddContact {
    InviteContactViewController *inviteContactVC = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
    MEGANavigationController *navigation = [MEGANavigationController.alloc initWithRootViewController:inviteContactVC];
    [navigation addLeftDismissButtonWithText:NSLocalizedString(@"close", @"A button label. The button allows the user to close the conversation.")];
    [self presentViewController:navigation animated:YES completion:nil];
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
    self.phoneBadgeImageView.frame = CGRectMake(self.tabBar.frame.size.width / 4 * 3 - 10, 6, 10, 10);
}

- (UIViewController *)homeViewController {
    return [HomeScreenFactory.new createHomeScreenFrom:self];
}

- (void)showPSAViewIfNeeded {
    if (self.psaRouter != nil) {
        return;
    }
    
    self.psaRouter = [PSAViewRouter.alloc initWithTabBarController:self delegate:self];
    [self.psaRouter start];
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
            self.phoneBadgeImageView.hidden = NO;
            break;
            
        case MEGAChatCallStatusDestroyed:
            self.phoneBadgeImageView.hidden = ([MEGASdkManager sharedMEGAChatSdk].numCalls == 0);
            break;
            
        default:
            break;
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if (tabBarController.selectedIndex == HOME) {
        [self showPSAViewIfNeeded];
    }
}

#pragma mark - MEGANavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController {
    if (viewController.hidesBottomBarWhenPushed) {
        [self.psaRouter hidePSAView:true];
    } else {
        [self.psaRouter hidePSAView:false];
    }
}


#pragma mark - PSAViewRouterDelegate

- (void)psaViewdismissed {
    self.psaRouter = nil;
}

@end
