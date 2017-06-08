#import "MainTabBarController.h"
#import "MEGASdkManager.h"

#import "MessagesViewController.h"

NSInteger const CLOUD = 0;
NSInteger const PHOTOS = 1;
NSInteger const CHAT = 2;
NSInteger const SHARED = 3;
NSInteger const OFFLINE = 4;
NSInteger const CONTACTS = 5;
NSInteger const TRANSFERS = 6;
NSInteger const MYACCOUNT = 7;
NSInteger const SETTINGS = 8;


@interface MainTabBarController () <UITabBarControllerDelegate, MEGAGlobalDelegate, MEGAChatDelegate>

@end

@implementation MainTabBarController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *defaultViewControllersMutableArray = [[NSMutableArray alloc] initWithCapacity:9];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Photos" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateInitialViewController]];
    [defaultViewControllersMutableArray addObject:[[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController]];
    
    for (NSInteger i = 0; i < [defaultViewControllersMutableArray count]; i++) {
        UITabBarItem *tabBarItem = [[defaultViewControllersMutableArray objectAtIndex:i] tabBarItem];
        switch (tabBarItem.tag) {
            case CLOUD:
                [tabBarItem setImage:[[UIImage imageNamed:@"cloudDriveIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"cloudDriveSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                break;
                
            case PHOTOS:
                [tabBarItem setImage:[[UIImage imageNamed:@"cameraUploadsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"cameraUploadsSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
                break;
                
            case OFFLINE:
                [tabBarItem setImage:[[UIImage imageNamed:@"offlineIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"offlineSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"offline", @"Title of the Offline section");
                break;
                
            case SHARED:
                [tabBarItem setImage:[[UIImage imageNamed:@"sharedItemsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"sharedItemsSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"shared", nil)];
                break;
                
            case CONTACTS:
                [tabBarItem setImage:[[UIImage imageNamed:@"contactsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"contactsSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"contactsTitle", nil)];
                break;
                
            case TRANSFERS:
                [tabBarItem setImage:[[UIImage imageNamed:@"transfersIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"transfersSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"transfers", nil)];
                break;
                
            case SETTINGS:
                [tabBarItem setImage:[[UIImage imageNamed:@"settingsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"settingsSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"settingsTitle", nil)];
                break;
                
            case MYACCOUNT:
                [tabBarItem setImage:[[UIImage imageNamed:@"myAccountIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"myAccountSelectedIcon"]];
                [tabBarItem setTitle:AMLocalizedString(@"myAccount", nil)];
                break;
                
            case CHAT:
                [tabBarItem setImage:[[UIImage imageNamed:@"chatIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
                [tabBarItem setSelectedImage:[UIImage imageNamed:@"chatSelectedIcon"]];
                tabBarItem.title = AMLocalizedString(@"chat", @"Chat section header");
                break;
        }
    }
    
    [self.view setTintColor:[UIColor mnz_redD90007]];
    [self.moreNavigationController.view setTintColor:[UIColor mnz_redD90007]];
    
    NSArray *tabsOrderArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"TabsOrderInTabBar"];
    if (tabsOrderArray && ([tabsOrderArray count] == [defaultViewControllersMutableArray count])) {
        NSMutableArray *customOrderMutableArray = [NSMutableArray arrayWithCapacity:defaultViewControllersMutableArray.count];
        for (NSNumber *tabBarNumber in tabsOrderArray) {
            [customOrderMutableArray addObject:[defaultViewControllersMutableArray objectAtIndex:tabBarNumber.unsignedIntegerValue]];
        }
        [self setViewControllers:customOrderMutableArray];
    } else {
        [self setViewControllers:defaultViewControllersMutableArray];
    }
    
    [self setDelegate:self];
    
    [self customizeMoreNavigationController];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [self setBadgeValueForChats];
    [self setBadgeValueForIncomingContactRequests];
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

#pragma mark - Private

- (void)customizeMoreNavigationController {
    UITableView *moreTableView = (UITableView *)self.moreNavigationController.topViewController.view;
    if ([moreTableView isKindOfClass:[UITableView class]]) {
        for (UITableViewCell *cell in [moreTableView visibleCells]) {
            
            UIView *view = [[UIView alloc] init];
            [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
            [cell setSelectedBackgroundView:view];
            
            cell.textLabel.font = [UIFont mnz_SFUIRegularWithSize:17.0f];
        }
    }
    
    [self.moreNavigationController.navigationBar setBarTintColor:[UIColor mnz_grayF9F9F9]];
}

- (void)setBadgeValueForIncomingContactRequests {
    NSInteger contactsTabPosition = [self tabPositionForTag:CONTACTS];
    
    MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
    long incomingContacts = [[incomingContactsLists size] longValue];
    
    NSString *badgeValue = incomingContacts ? [NSString stringWithFormat:@"%ld", incomingContacts] : nil;
    [self setBadgeValue:badgeValue tabPosition:contactsTabPosition];
}

- (void)setBadgeValueForChats {
    NSInteger chatTabPosition = [self tabPositionForTag:CHAT];
    NSInteger unreadChats = [[MEGASdkManager sharedMEGAChatSdk] unreadChats];
    
    NSString *badgeValue = unreadChats ? [NSString stringWithFormat:@"%ld", unreadChats] : nil;
    [self setBadgeValue:badgeValue tabPosition:chatTabPosition];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = unreadChats;
}

- (NSInteger)tabPositionForTag:(NSInteger)tag {
    NSInteger tabPosition;
    for (tabPosition = 0 ; tabPosition < self.viewControllers.count ; tabPosition++) {
        if ([[[self.viewControllers objectAtIndex:tabPosition] tabBarItem] tag] == tag) {
            break;
        }
    }
    
    return tabPosition;
}

- (void)setBadgeValue:(NSString *)badgeValue tabPosition:(NSInteger)tabPosition {
    NSInteger visibleTabs;
    BOOL landscape = [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight;
    if (([[UIDevice currentDevice] iPhone6XPlus] && landscape) || [[UIDevice currentDevice] iPad] ) {
        visibleTabs = 8;
    } else {
        visibleTabs = 4;
    }
    if (tabPosition >= visibleTabs) {
        [[[self moreNavigationController] tabBarItem] setBadgeValue:badgeValue];
    }
    
    [[self.viewControllers objectAtIndex:tabPosition] tabBarItem].badgeValue = badgeValue;
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
    if (changed) {
        NSMutableArray *tabsOrderMutableArray = [[NSMutableArray alloc] initWithCapacity:viewControllers.count];
        for (UINavigationController *navigationController in viewControllers) {
            [tabsOrderMutableArray addObject:[NSNumber numberWithInteger:navigationController.tabBarItem.tag]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:tabsOrderMutableArray] forKey:@"TabsOrderInTabBar"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self setBadgeValueForIncomingContactRequests];
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
    }
}

@end
