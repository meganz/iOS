#import "ChatRoomsViewController.h"

#import <Contacts/Contacts.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIApplication+MNZCategory.h"

#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGAChatChangeGroupNameRequestDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGALinkManager.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "MEGA-Swift.h"
#import "UITableView+MNZCategory.h"
#import "UIViewController+MNZCategory.h"

#import "CallViewController.h"
#import "ChatRoomCell.h"
#import "ChatSettingsTableViewController.h"
#import "ContactDetailsViewController.h"
#import "ContactsViewController.h"
#import "EmptyStateView.h"
#import "GroupCallViewController.h"
#import "GroupChatDetailsViewController.h"
#import "MEGA-Swift.h"

@interface ChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAChatDelegate, UIScrollViewDelegate, MEGAChatCallDelegate, UISearchControllerDelegate, PushNotificationControlProtocol>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIView *archivedChatEmptyState;
@property (weak, nonatomic) IBOutlet UILabel *archivedChatEmptyStateTitle;
@property (weak, nonatomic) IBOutlet UILabel *archivedChatEmptyStateCount;
@property (weak, nonatomic) IBOutlet UIStackView *contactsOnMegaEmptyStateView;
@property (weak, nonatomic) IBOutlet UILabel *contactsOnMegaEmptyStateTitle;

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) MEGAChatListItemList *archivedChatListItemList;
@property (nonatomic, strong) NSMutableArray *chatListItemArray;
@property (nonatomic, strong) NSMutableArray *searchChatListItemArray;
@property (nonatomic, strong) NSMutableDictionary *chatIdIndexPathDictionary;
@property (nonatomic) NSMutableArray<MEGAUser *> *usersWithoutChatArray;
@property (nonatomic) NSMutableArray<MEGAUser *> *searchUsersWithoutChatArray;

@property (strong, nonatomic) UISearchController *searchController;

@property (assign, nonatomic) BOOL isArchivedChatsRowVisible;
@property (assign, nonatomic) BOOL isScrollAtTop;

@property (weak, nonatomic) IBOutlet UIButton *topBannerButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBannerButtonTopConstraint;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (strong, nonatomic) MEGAChatRoom *chatRoomOnGoingCall;

@property (nonatomic, getter=isReconnecting) BOOL reconnecting;

@property (assign, nonatomic) NSInteger contactsOnMegaCount;

@property (nonatomic) GlobalDNDNotificationControl *globalDNDNotificationControl;
@property (nonatomic) ChatNotificationControl *chatNotificationControl;

@end

@implementation ChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self customNavigationBarLabel];
    
    self.chatIdIndexPathDictionary = [[NSMutableDictionary alloc] init];
    self.chatListItemArray = [[NSMutableArray alloc] init];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    MEGAUserList *users = [[MEGASdkManager sharedMEGASdk] contacts];
    self.usersWithoutChatArray = [[NSMutableArray alloc] init];
    NSInteger count = users.size.integerValue;
    for (NSInteger i = 0; i < count; i++) {
        MEGAUser *user = [users userAtIndex:i];
        if (![[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle] && user.visibility == MEGAUserVisibilityVisible) {
            [self.usersWithoutChatArray addObject:user];
        }
    }
    
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault:
            self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] chatListItems];
            self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
            self.addBarButtonItem.enabled = [MEGAReachabilityManager isReachable] && MEGASdkManager.sharedMEGASdk.businessStatus != BusinessStatusExpired;
            break;
            
        case ChatRoomsTypeArchived:
            self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
            self.navigationItem.rightBarButtonItem = nil;
            break;
    }
    
    if (self.chatListItemList.size) {
        [self reorderList];
        
        [self updateChatIdIndexPathDictionary];
        [self configureSearchController];
    }
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    if (@available(iOS 13.0, *)) {
        [self configPreviewingRegistration];
    }
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.chatRoomOnGoingCall) {
        self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        if (![ContactsOnMegaManager.shared areContactsOnMegaRequestedWithinDays:1]) {
            [ContactsOnMegaManager.shared configureContactsOnMegaWithCompletion:^{
                self.contactsOnMegaCount = ContactsOnMegaManager.shared.contactsOnMegaCount;
                if (self.contactsOnMegaCount > 0) {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
        } else {
            [ContactsOnMegaManager.shared loadContactsOnMegaFromLocal];
            self.contactsOnMegaCount = ContactsOnMegaManager.shared.contactsOnMegaCount;
        }
    }
    
    self.tabBarController.tabBar.hidden = NO;
    [self customNavigationBarLabel];

    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    if ([[MEGASdkManager sharedMEGAChatSdk] initState] == MEGAChatInitOnlineSession) {
        [self reloadData];
    }
    
    self.chatRoomOnGoingCall = nil;
    MEGAHandleList *chatRoomIDsWithCallInProgress = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusInProgress];
    if ((chatRoomIDsWithCallInProgress.size > 0) && MEGAReachabilityManager.isReachable) {
        self.chatRoomOnGoingCall = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:[chatRoomIDsWithCallInProgress megaHandleAtIndex:0]];
        
        if (self.topBannerButtonTopConstraint.constant == -44) {
            MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:self.chatRoomOnGoingCall.chatId];
            [self showTopBannerButton:call];
            [self configureTopBannerButtonForInProgressCall:call];
        }
        
        if (!self.chatRoomOnGoingCall && self.topBannerButtonTopConstraint.constant == 0) {
            [self hideTopBannerButton];
        }
    } else {
        [self hideTopBannerButton];
    }
    
    self.globalDNDNotificationControl = [GlobalDNDNotificationControl.alloc initWithDelegate:self];
    self.chatNotificationControl = [ChatNotificationControl.alloc initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([DevicePermissionsHelper shouldAskForNotificationsPermissions]) {
        [DevicePermissionsHelper modalNotificationsPermission];
    }
    
    self.navigationController.toolbarHidden = true;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.chatRoomsType == ChatRoomsTypeArchived) {
        [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
        [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
            [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar traitCollection:self.traitCollection];
        }
    }
    
    [self configPreviewingRegistration];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
        if (self.searchController.active) {
            if (UIDevice.currentDevice.iPad) {
                if (self != UIApplication.mnz_visibleViewController) {
                    [Helper resetSearchControllerFrame:self.searchController];
                }
            } else {
                [Helper resetSearchControllerFrame:self.searchController];
            }
        }
    } completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if (MEGAReachabilityManager.isReachable) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"IsChatEnabled"]) {
            if (MEGASdkManager.sharedMEGAChatSdk.initState == MEGAChatInitWaitingNewSession || MEGASdkManager.sharedMEGAChatSdk.initState == MEGAChatInitNoCache) {
                return [UIImageView.alloc initWithImage:[UIImage imageNamed:@"chatListLoading"]];
            }
        }
    }
    
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - DZNEmptyDataSetDelegate

- (void)emptyDataSetWillAppear:(UIScrollView *)scrollView {
    if (!self.searchController.active) {
        self.searchController.searchBar.hidden = YES;
        self.archivedChatListItemList = MEGASdkManager.sharedMEGAChatSdk.archivedChatListItems;
        if (self.archivedChatListItemList.size) {
            self.archivedChatEmptyStateTitle.text = AMLocalizedString(@"archivedChats", @"Title of archived chats button");
            self.archivedChatEmptyStateCount.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
            self.archivedChatEmptyState.hidden = NO;
        }
        if (self.chatRoomsType == ChatRoomsTypeDefault) {
            if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) {
                if (self.contactsOnMegaCount) {//[X] contacts found on MEGA
                    self.contactsOnMegaEmptyStateTitle.text = self.contactsOnMegaCount == 1 ? AMLocalizedString(@"1 contact found on MEGA", @"Title showing the user one of his contacts are using MEGA") : [AMLocalizedString(@"[X] contacts found on MEGA", @"Title showing the user how many of his contacts are using MEGA") stringByReplacingOccurrencesOfString:@"[X]" withString:[NSString stringWithFormat:@"%tu", self.contactsOnMegaCount]];
                } else {
                    self.contactsOnMegaEmptyStateTitle.text = AMLocalizedString(@"Invite contact now", @"Text emncouraging the user to add contacts in MEGA");
                }
                self.contactsOnMegaEmptyStateView.hidden = NO;
            } else {
                self.contactsOnMegaEmptyStateTitle.text = AMLocalizedString(@"See who's already on MEGA", @"Title encouraging the user to check who of its contacts are using MEGA");
                self.contactsOnMegaEmptyStateView.hidden = NO;
            }
        }
    }
}

- (void)emptyDataSetWillDisappear:(UIScrollView *)scrollView {
    if (!self.searchController.active) {
        self.searchController.searchBar.hidden = NO;
        if (!self.archivedChatEmptyState.hidden) {
            self.archivedChatEmptyState.hidden = YES;
        }
        if (!self.contactsOnMegaEmptyStateView.hidden) {
            self.contactsOnMegaEmptyStateView.hidden = YES;
        }
    }
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        switch (self.chatRoomsType) {
            case ChatRoomsTypeDefault:
                text = AMLocalizedString(@"noConversations", @"Empty Conversations section");
                break;
                
            case ChatRoomsTypeArchived:
                text = AMLocalizedString(@"noArchivedChats", @"Title of empty state view for archived chats.");
                break;
        }
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";

    if (self.searchController.isActive) {
        text = @"";
    } else {
        switch (self.chatRoomsType) {
            case ChatRoomsTypeDefault:
                text = AMLocalizedString(@"Start chatting securely with your contacts using end-to-end encryption", @"Empty Conversations description");
                break;
                
            case ChatRoomsTypeArchived:
                break;
        }
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"searchEmptyState"];
            } else {
                return nil;
            }
        } else {
            if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) && UIDevice.currentDevice.iPhoneDevice) {
                return nil;
            } else {
                switch (self.chatRoomsType) {
                    case ChatRoomsTypeDefault:
                        return [UIImage imageNamed:@"chatEmptyState"];
                        
                    case ChatRoomsTypeArchived:
                        return [UIImage imageNamed:@"chatsArchivedEmptyState"];
                }
            }
        }
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.searchController.isActive) {
            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault:
                    text = AMLocalizedString(@"New Chat Link", @"Text button for init a group chat with link.");
                    break;
                case ChatRoomsTypeArchived:
                    return nil;
            }
        }
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    [navigationController addLeftDismissButtonWithText:AMLocalizedString(@"cancel", nil)];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.contactsMode = ContactsModeChatNamingGroup;
    contactsVC.getChatLinkEnabled = YES;
    [self blockCompletionsForCreateChatInContacts:contactsVC];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    self.navigationController.view.backgroundColor = UIColor.mnz_background;

    self.archivedChatEmptyStateCount.textColor = UIColor.mnz_secondaryLabel;
    
    self.topBannerButton.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
}

- (void)openChatRoomWithID:(uint64_t)chatID {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        UIViewController *currentVC = self.navigationController.viewControllers[1];
        if ([currentVC isKindOfClass:ChatViewController.class]) {
            ChatViewController *currentChatViewController= (ChatViewController *)currentVC;
            if (currentChatViewController.chatRoom.chatId == chatID) {
                if (viewControllers.count != 2) {
                    [self.navigationController popToViewController:currentChatViewController animated:YES];
                }
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAOpenChatRoomFromPushNotification object:nil];
                return;
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:currentChatViewController.chatRoom.chatId
                                                         delegate:currentChatViewController];
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
        }
    }
    
    ChatViewController *chatViewController = [ChatViewController.alloc init];
    chatViewController.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatID];
    
    [self updateBackBarButtonItem:chatViewController.chatRoom.unreadCount];
    
    [self.navigationController pushViewController:chatViewController animated:YES];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable] && MEGASdkManager.sharedMEGASdk.businessStatus != BusinessStatusExpired;
    self.addBarButtonItem.enabled = boolValue;
    
    [self customNavigationBarLabel];
    [self.tableView reloadData];
}

- (MEGAChatListItem *)chatListItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = nil;
    if (indexPath) {
        if (self.searchController.isActive) {
            chatListItem = [self.searchChatListItemArray objectAtIndex:indexPath.row];
        } else {
            chatListItem = [self.chatListItemArray objectAtIndex:indexPath.row];
        }
    }
    return chatListItem;
}

- (void)deleteRowByChatId:(uint64_t)chatId {
    BOOL isUserContactsSectionVisible = [self isUserContactsSectionVisible];

    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray removeObjectAtIndex:indexPath.row];
    } else {
        [self.chatListItemArray removeObjectAtIndex:indexPath.row];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if ([self numberOfChatRooms] == 0  && self.chatRoomsType == ChatRoomsTypeDefault) {
        if (self.isArchivedChatsRowVisible) {
            self.isScrollAtTop = NO;
            self.isArchivedChatsRowVisible = NO;
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        if (isUserContactsSectionVisible) {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    [self.tableView endUpdates];
    [self updateChatIdIndexPathDictionary];
}

- (void)insertRowByChatListItem:(MEGAChatListItem *)item {
    BOOL addingFirstChat = [self numberOfChatRooms] == 0;
    
    NSInteger section = self.chatRoomsType == ChatRoomsTypeDefault ? 2 : 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray insertObject:item atIndex:indexPath.row];
    } else {
        [self.chatListItemArray insertObject:item atIndex:indexPath.row];
    }
    [self updateChatIdIndexPathDictionary];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if (addingFirstChat && [self isUserContactsSectionVisible]) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        [self configureSearchController];
    }
    [self.tableView endUpdates];
}

- (void)moveRowByChatListItem:(MEGAChatListItem *)item {
    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(item.chatId)];
    NSIndexPath *newIndexPath;
    NSMutableArray *tempArray = self.searchController.isActive ? self.searchChatListItemArray : self.chatListItemArray;
    for (MEGAChatListItem *chatListItem in tempArray) {
        if ([item.lastMessageDate compare:chatListItem.lastMessageDate]>=NSOrderedSame) {
            newIndexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatListItem.chatId)];
            [tempArray removeObjectAtIndex:indexPath.row];
            [tempArray insertObject:item atIndex:newIndexPath.row];
            break;
        }
    }

    [self updateChatIdIndexPathDictionary];
    
    if (newIndexPath) {
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

- (void)updateChatIdIndexPathDictionary {
    [self.chatIdIndexPathDictionary removeAllObjects];
    NSInteger i = 0;
    NSInteger section = self.chatRoomsType == ChatRoomsTypeDefault ? 2 : 0;

    NSArray *tempArray = self.searchController.isActive ? self.searchChatListItemArray : self.chatListItemArray;
    for (MEGAChatListItem *item in tempArray) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [self.chatIdIndexPathDictionary setObject:indexPath forKey:@(item.chatId)];
        i++;
    }
}

- (void)customNavigationBarLabel {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            NSString *onlineStatusString = [NSString chatStatusString:[[MEGASdkManager sharedMEGAChatSdk] onlineStatus]];
            
            if (onlineStatusString) {
                UILabel *label = [Helper customNavigationBarLabelWithTitle:AMLocalizedString(@"chat", @"Chat section header") subtitle:onlineStatusString];
                label.adjustsFontSizeToFitWidth = YES;
                label.minimumScaleFactor = 0.8f;
                label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
                [self.navigationItem setTitleView:label];
            } else {
                self.navigationItem.titleView = nil;
                self.navigationItem.title = AMLocalizedString(@"chat", @"Chat section header");
            }
        }
            break;
            
        case ChatRoomsTypeArchived:
            self.navigationItem.title = AMLocalizedString(@"archivedChats", @"Title of archived chats button");
            break;
    }
}

- (void)presentChangeOnlineStatusAlertController {
    __weak __typeof__(self) weakSelf = self;
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    
    MEGAChatStatus onlineStatus = MEGASdkManager.sharedMEGAChatSdk.onlineStatus;
    if (MEGAChatStatusOnline != onlineStatus) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:AMLocalizedString(@"online", @"") detail:nil image:nil style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf changeToOnlineStatus:MEGAChatStatusOnline];
        }]];
    }
    
    if (MEGAChatStatusAway != onlineStatus) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:AMLocalizedString(@"away", @"") detail:nil image:nil style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf changeToOnlineStatus:MEGAChatStatusAway];
        }]];
    }
    
    if (MEGAChatStatusBusy != onlineStatus) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:AMLocalizedString(@"busy", @"") detail:nil image:nil style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf changeToOnlineStatus:MEGAChatStatusBusy];
        }]];
    }
    
    if (MEGAChatStatusOffline != onlineStatus) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:AMLocalizedString(@"offline", @"Title of the Offline section") detail:nil image:nil style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf changeToOnlineStatus:MEGAChatStatusOffline];
        }]];
    }
    
    ActionSheetViewController *moreActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:self.navigationItem.titleView];
    [self presentViewController:moreActionSheet animated:YES completion:nil];
}

- (void)changeToOnlineStatus:(MEGAChatStatus)chatStatus {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    if (chatStatus != [[MEGASdkManager sharedMEGAChatSdk] onlineStatus]) {
        [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:chatStatus];
    }
}

- (void)presentGroupOrContactDetailsForChatListItem:(MEGAChatListItem *)chatListItem {
    if (chatListItem.isGroup) {
        if ([MEGALinkManager.joiningOrLeavingChatBase64Handles containsObject:[MEGASdk base64HandleForUserHandle:chatListItem.chatId]]) {
            return;
        }
        GroupChatDetailsViewController *groupChatDetailsVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupChatDetailsViewControllerID"];
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        groupChatDetailsVC.chatRoom = chatRoom;
        [self.navigationController pushViewController:groupChatDetailsVC animated:YES];
    } else {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        NSString *peerEmail     = [[MEGASdkManager sharedMEGAChatSdk] contacEmailByHandle:[chatRoom peerHandleAtIndex:0]];
        uint64_t peerHandle     = [chatRoom peerHandleAtIndex:0];
        
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromChat;
        contactDetailsVC.userEmail          = peerEmail;
        contactDetailsVC.userHandle         = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

- (void)reloadData {
    self.chatListItemList = self.chatRoomsType == ChatRoomsTypeDefault ? [[MEGASdkManager sharedMEGAChatSdk] chatListItems] : [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
    self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
    [self reorderList];
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

- (void)reorderList {
    [self.chatListItemArray removeAllObjects];
    
    for (NSUInteger i = 0; i < self.chatListItemList.size ; i++) {
        MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:i];
        [self.chatListItemArray addObject:chatListItem];
    }
    self.chatListItemArray = [[self.chatListItemArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first  = [(MEGAChatListItem *)a lastMessageDate];
        NSDate *second = [(MEGAChatListItem *)b lastMessageDate];
        
        if (!first) {
            first = [NSDate dateWithTimeIntervalSince1970:0];
        }
        if (!second) {
            second = [NSDate dateWithTimeIntervalSince1970:0];
        }
        
        return [second compare:first];
    }] mutableCopy];
}

- (NSInteger)numberOfChatRooms {
    return self.searchController.isActive ? self.searchChatListItemArray.count : self.chatListItemArray.count;
}

- (void)showChatRoomAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    MEGAChatRoom *chatRoom         = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
    
    ChatViewController *chatViewController = [ChatViewController.alloc init];
    chatViewController.chatRoom = chatRoom;
    
    [self updateBackBarButtonItem:chatRoom.unreadCount];
    
    [self.navigationController pushViewController:chatViewController animated:YES];
}

- (void)createChatRoomWithUserAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.searchUsersWithoutChatArray objectAtIndex:indexPath.row];
    
    [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
        ChatViewController *chatViewController = [ChatViewController.alloc init];
        chatViewController.chatRoom = chatRoom;
        [self.navigationController pushViewController:chatViewController animated:YES];
    }];
    
    [self.searchUsersWithoutChatArray removeObject:user];
    [self.usersWithoutChatArray removeObject:user];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateBackBarButtonItem:(BOOL)hasUnreadMessages {
    NSInteger unreadChats = [MEGASdkManager sharedMEGAChatSdk].unreadChats;
    if (hasUnreadMessages) {
        unreadChats--;
    }
    
    NSString *unreadChatsString = unreadChats ? [NSString stringWithFormat:@"(%td)", unreadChats] : @"";
    
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithTitle:unreadChatsString style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backBarButton;
}

- (UITableViewCell *)archivedChatRoomCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = (ChatRoomCell *)[self chatRoomCellForIndexPath:indexPath];
    [cell configureCellForArchivedChat];
    return cell;
}

- (UITableViewCell *)chatRoomCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    BOOL muted = [self.chatNotificationControl isChatDNDEnabledWithChatId:chatListItem.chatId];
    [cell configureCellForChatListItem:chatListItem isMuted:muted];
    return cell;
}

- (UITableViewCell *)userCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    MEGAUser *user = [self.searchUsersWithoutChatArray objectAtIndex:indexPath.row];
    [cell configureCellForUser:user];
    return cell;
}

- (UITableViewCell *)contactsOnMegaCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"contactsOnMegaCell" forIndexPath:indexPath];
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) {
        if (self.contactsOnMegaCount == 0) {
            cell.chatTitle.text = AMLocalizedString(@"Invite contact now", @"Text emncouraging the user to add contacts in MEGA");
        } else {
            cell.chatTitle.text = self.contactsOnMegaCount == 1 ? AMLocalizedString(@"1 contact found on MEGA", @"Title showing the user one of his contacts are using MEGA") : [AMLocalizedString(@"[X] contacts found on MEGA", @"Title showing the user how many of his contacts are using MEGA") stringByReplacingOccurrencesOfString:@"[X]" withString:[NSString stringWithFormat:@"%tu", self.contactsOnMegaCount]];
        }
    } else {
        cell.chatTitle.text = AMLocalizedString(@"See who's already on MEGA", @"Title encouraging the user to check who of its contacts are using MEGA");
    }
    return cell;
}

- (UITableViewCell *)archivedChatsCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"archivedChatsCell" forIndexPath:indexPath];
    cell.avatarView.avatarImageView.image = [UIImage imageNamed:@"archiveChat"];
    cell.avatarView.avatarImageView.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    [cell.avatarView configureWithMode:MegaAvatarViewModeSingle];
    cell.chatTitle.text = AMLocalizedString(@"archivedChats", @"Title of archived chats button");
    cell.chatLastMessage.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
    return cell;
}

- (BOOL)isUserContactsSectionVisible {
    return [self numberOfChatRooms] > 0;
}

- (void)configureSearchController {
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
        [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
        self.definesPresentationContext = YES;
        self.searchController.hidesNavigationBarDuringPresentation = YES;
    }
}

#pragma mark - TopBannerButton

- (void)showTopBannerButton:(MEGAChatCall *)call {
    if (self.topBannerButton.hidden) {
         self.topBannerButton.hidden = NO;
           [UIView animateWithDuration:.5f animations:^ {
               self.topBannerButtonTopConstraint.constant = 0;
               self.tableView.contentOffset = CGPointZero;
               [self.view layoutIfNeeded];
           } completion:nil];
    }
}

- (void)hideTopBannerButton {
    if (!self.topBannerButton.hidden) {
         [UIView animateWithDuration:.5f animations:^ {
               self.topBannerButtonTopConstraint.constant = -44;
               [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
               [self.view layoutIfNeeded];
           } completion:^(BOOL finished) {
               self.topBannerButton.hidden = YES;
           }];
    }
}

- (void)setTopBannerButtonTitle:(NSString *)title color:(UIColor *)color {
    [self.topBannerButton setTitle:title forState:UIControlStateNormal];
    self.topBannerButton.backgroundColor = color;
}

- (void)initTimerForCall:(MEGAChatCall *)call {
    self.initDuration = call.duration;
    self.baseDate = [NSDate date];
    if (!self.timer.isValid) {
        [self updateDuration];
        self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    self.reconnecting = NO;
}
- (void)updateDuration {
    if (!self.isReconnecting) {
        NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
        [self setTopBannerButtonTitle:[NSString stringWithFormat:AMLocalizedString(@"Touch to return to call %@", @"Message shown in a chat room for a group call in progress displaying the duration of the call"), [NSString mnz_stringFromTimeInterval:interval]] color:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection]];
    }
}

- (void)configureTopBannerButtonForInProgressCall:(MEGAChatCall *)call {
    if (self.isReconnecting) {
        [self setTopBannerButtonTitle:AMLocalizedString(@"You are back!", @"Title shown when the user reconnect in a call.") color:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection]];
    }
    [self initTimerForCall:call];
}

#pragma mark - IBActions

- (IBAction)joinActiveCall:(id)sender {
    [DevicePermissionsHelper audioPermissionModal:YES forIncomingCall:NO withCompletionHandler:^(BOOL granted) {
        if (granted) {
            [self.timer invalidate];
            if (self.chatRoomOnGoingCall.isGroup) {
                GroupCallViewController *groupCallVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupCallViewControllerID"];
                groupCallVC.callType = CallTypeActive;
                groupCallVC.videoCall = NO;
                groupCallVC.chatRoom = self.chatRoomOnGoingCall;
                groupCallVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                groupCallVC.megaCallManager = ((AppDelegate *)UIApplication.sharedApplication.delegate).megaCallManager;
                groupCallVC.modalPresentationStyle = UIModalPresentationFullScreen;
                
                [self presentViewController:groupCallVC animated:YES completion:nil];
            } else {
                CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
                callVC.chatRoom = self.chatRoomOnGoingCall;
                callVC.videoCall = NO;
                callVC.callType = CallTypeActive;
                callVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                callVC.megaCallManager = ((AppDelegate *)UIApplication.sharedApplication.delegate).megaCallManager;
                callVC.modalPresentationStyle = UIModalPresentationFullScreen;
                
                [self presentViewController:callVC animated:YES completion:nil];
            }
        } else {
            [DevicePermissionsHelper alertAudioPermissionForIncomingCall:NO];
        }
    }];
}

- (IBAction)openArchivedChats:(id)sender {
    ChatRoomsViewController *archivedChatRooms = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatRoomsViewControllerID"];
    [self.navigationController pushViewController:archivedChatRooms animated:YES];
    archivedChatRooms.chatRoomsType = ChatRoomsTypeArchived;
}

- (void)blockCompletionsForCreateChatInContacts:(ContactsViewController *)contactsVC {
    ChatViewController *chatViewController = [ChatViewController.alloc init];
    
    contactsVC.userSelected = ^void(NSArray *users) {
        if (users.count == 1) {
            MEGAUser *user = users.firstObject;
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
            if (chatRoom) {
                chatViewController.chatRoom = chatRoom;
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self.navigationController pushViewController:chatViewController animated:YES];
                });
            } else {
                [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                    chatViewController.chatRoom = chatRoom;
                    [self.navigationController pushViewController:chatViewController animated:YES];
                }];
            }
        }
    };
    
    contactsVC.chatSelected = ^(uint64_t chatId) {
        chatViewController.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatId];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.navigationController pushViewController:chatViewController animated:YES];
        });
    };
    
    contactsVC.createGroupChat = ^void(NSArray *users, NSString *groupName, BOOL keyRotation, BOOL getChatLink) {
        if (keyRotation) {
            [MEGASdkManager.sharedMEGAChatSdk mnz_createChatRoomWithUsersArray:users title:groupName completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                chatViewController.chatRoom = chatRoom;
                [self.navigationController pushViewController:chatViewController animated:YES];
            }];
        } else {
            MEGAChatGenericRequestDelegate *createChatGroupRequestDelegate = [MEGAChatGenericRequestDelegate.alloc initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
                chatViewController.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:request.chatHandle];
                if (getChatLink) {
                    MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
                        if (!error.type) {
                            chatViewController.publicChatWithLinkCreated = YES;
                            chatViewController.publicChatLink = [NSURL URLWithString:request.text];
                            [self.navigationController pushViewController:chatViewController animated:YES];
                        }
                    }];
                    [MEGASdkManager.sharedMEGAChatSdk createChatLink:chatViewController.chatRoom.chatId delegate:delegate];
                } else {
                    [self.navigationController pushViewController:chatViewController animated:YES];
                }
            }];
            [MEGASdkManager.sharedMEGAChatSdk createPublicChatWithPeers:[MEGAChatPeerList mnz_standardPrivilegePeerListWithUsersArray:users] title:groupName delegate:createChatGroupRequestDelegate];
        }
    };
}

- (IBAction)openContactsOnMega:(id)sender {
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized && self.contactsOnMegaCount == 0) {
        InviteContactViewController *inviteContacts = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
        [self.navigationController pushViewController:inviteContacts animated:YES];
    } else {
        ContactsOnMegaViewController *contactsOnMega = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsOnMegaViewControllerID"];
        [self.navigationController pushViewController:contactsOnMega animated:YES];
    }
}

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.contactsMode = ContactsModeChatStartConversation;
    [self blockCompletionsForCreateChatInContacts:contactsVC];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)optionsTapped:(UIBarButtonItem *)sender {
    if (!MEGASdkManager.sharedMEGAChatSdk.presenceConfig) {
        return;
    }
    
    MEGAChatStatus myStatus = MEGASdkManager.sharedMEGAChatSdk.onlineStatus;
    NSString *chatStatusString = [NSString chatStatusString:myStatus];
    UIView *accessoryView = [UIView.alloc initWithFrame:CGRectMake(0.0f, 0.0f, 6.0f, 6.0f)];
    accessoryView.layer.cornerRadius = 3;
    accessoryView.backgroundColor = [UIColor mnz_colorForChatStatus:myStatus];
    
    ActionSheetAction *statusAction = [ActionSheetAction.alloc initWithTitle:AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)")
                                                                      detail:chatStatusString
                                                               accessoryView:accessoryView
                                                                       image:nil
                                                                       style:UIAlertActionStyleDefault
                                                               actionHandler:^{
        [self presentChangeOnlineStatusAlertController];
    }];
    
    BOOL isGlobalDNDEnabled = self.globalDNDNotificationControl.isGlobalDNDEnabled;
    NSString *dndString = isGlobalDNDEnabled ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil);
    
    ActionSheetAction *dndAction = [ActionSheetAction.alloc initWithTitle:AMLocalizedString(@"Do Not Disturb", @"Chat settings: This text appears with the Do Not Disturb switch")
                                                                      detail:dndString
                                                                       image:nil
                                                                       style:UIAlertActionStyleDefault
                                                               actionHandler:^{
        if (isGlobalDNDEnabled) {
            ChatSettingsTableViewController *chatSettingsVC = [[UIStoryboard storyboardWithName:@"ChatSettings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatSettingsTableViewControllerID"];
            [self presentViewController:chatSettingsVC animated:YES completion:nil];
        } else {
            [self.globalDNDNotificationControl turnOnDND:sender];
        }
    }];
    
    ActionSheetViewController *actionSheetVC = [ActionSheetViewController.alloc initWithActions:@[statusAction, dndAction] headerTitle:nil dismissCompletion:nil sender:sender];
    
    [self presentViewController:actionSheetVC animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault:
            return 4;
            
        case ChatRoomsTypeArchived:
            return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.chatRoomsType == ChatRoomsTypeArchived) {
        return [self numberOfChatRooms];
    }
    
    switch (section) {
        case 0:
            if (self.isArchivedChatsRowVisible > 0 && !self.searchController.isActive) {
                return 1;
            } else {
                return 0;
            }
        
        case 1:
            if ([self numberOfChatRooms] > 0 && !self.searchController.isActive) {
                return 1;
            } else {
                return 0;
            }
            
        case 2:
            return [self numberOfChatRooms];

        case 3:
            return self.searchController.isActive ? self.searchUsersWithoutChatArray.count : 0;
            
        default:
            return 0;
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if (@available(iOS 13.0, *)) {
        MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        ChatViewController *chatViewController = [ChatViewController.alloc init];
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
            
            if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section] || (self.tableView.numberOfSections == 2 && indexPath.section == 0)) {
                return nil;
            }
            
            chatViewController.previewMode = YES;
            chatViewController.chatRoom = chatRoom;
            
            return chatViewController;
            
        } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            NSMutableArray *menus = [NSMutableArray new];
            
            if (chatRoom.unreadCount != 0) {
                UIAction *markAsReadAction = [UIAction actionWithTitle:AMLocalizedString(@"Mark as Read",@"A button label. The button allows the user to mark a conversation as read.") image:[UIImage imageNamed:@"markUnread_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                            [chatViewController setLastMessageAsSeen];
                        }];
                [menus addObject:markAsReadAction];
            }
            BOOL muted = [self.chatNotificationControl isChatDNDEnabledWithChatId:chatListItem.chatId];
            if (muted) {
                UIAction *unmuteAction = [UIAction actionWithTitle:AMLocalizedString(@"unmute", @"A button label. The button allows the user to unmute a conversation") image:[UIImage imageNamed:@"mutedChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self.chatNotificationControl turnOffDNDWithChatId:chatListItem.chatId];
                }];
                [menus addObject:unmuteAction];
            } else {
                UIAction *muteAction = [UIAction actionWithTitle:AMLocalizedString(@"mute", @"A button label. The button allows the user to mute a conversation") image:[UIImage imageNamed:@"mutedChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self.chatNotificationControl turnOnDNDWithChatId:chatListItem.chatId sender:[tableView cellForRowAtIndexPath:indexPath]];

                }];
                [menus addObject:muteAction];
            }
            

            UIAction *infoAction = [UIAction actionWithTitle:AMLocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context. ") image:[UIImage imageNamed:@"info_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [self presentGroupOrContactDetailsForChatListItem:chatListItem];
            }];
            [menus addObject:infoAction];

            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault: {
                    UIAction *archiveChatAction = [UIAction actionWithTitle:AMLocalizedString(@"archiveChat", @"Title of button to archive chats.") image:[UIImage imageNamed:@"archiveChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:YES];
                        
                    }];
                    [menus addObject:archiveChatAction];

                    
                    break;
                }
                case ChatRoomsTypeArchived:{
                    UIAction *archiveChatAction = [UIAction actionWithTitle:AMLocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") image:[UIImage imageNamed:@"unArchiveChat"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        [[MEGASdkManager sharedMEGAChatSdk] archiveChat:chatListItem.chatId archive:NO];
                        
                    }];
                    
                    [menus addObject:archiveChatAction];

                    break;
                }
            }
            
            return [UIMenu menuWithTitle:@"" children:menus];
        }];
        return configuration;
        
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (indexPath.section == 0) {
                return [self archivedChatsCellForIndexPath:indexPath];
            } else if (indexPath.section == 1) {
                return [self contactsOnMegaCellForIndexPath:indexPath];
            } else if (indexPath.section == 2) {
                return [self chatRoomCellForIndexPath:indexPath];
            } else if (indexPath.section == 3) {
                return [self userCellForIndexPath:indexPath];
            }
        }
            
        case ChatRoomsTypeArchived:
            return [self archivedChatRoomCellForIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (indexPath.section == 0) {
                [self openArchivedChats:self];
            } else if (indexPath.section == 1) {
                [self openContactsOnMega:self];
            } else if (indexPath.section == 2) {
                [self showChatRoomAtIndexPath:indexPath];
            } else if (indexPath.section == 3) {
                [self createChatRoomWithUserAtIndexPath:indexPath];
            }
            break;
        }
            
        case ChatRoomsTypeArchived: {
            [self showChatRoomAtIndexPath:indexPath];
            break;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (indexPath.section == 2) {
                return YES;
            } else {
                return NO;
            }
        }
            
        case ChatRoomsTypeArchived: {
            return YES;
        }
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];

    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            UITableViewRowAction *infoAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [self presentGroupOrContactDetailsForChatListItem:chatListItem];
            }];
            infoAction.backgroundColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
            
            UITableViewRowAction *archiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"archiveChat", @"Title of button to archive chats.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [[MEGASdkManager sharedMEGAChatSdk] archiveChat:chatListItem.chatId archive:YES];
            }];
            archiveAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];

            return @[archiveAction, infoAction];
        }
            
        case ChatRoomsTypeArchived: {
            UITableViewRowAction *unarchiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [[MEGASdkManager sharedMEGAChatSdk] archiveChat:chatListItem.chatId archive:NO];
            }];
            unarchiveAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
            
            return @[unarchiveAction];
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];

    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            UIContextualAction *archiveAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:YES];
            }];
            archiveAction.image = [UIImage imageNamed:@"archiveChat"];
            archiveAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
            
            UIContextualAction *infoAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [self presentGroupOrContactDetailsForChatListItem:chatListItem];
            }];
            infoAction.image = [UIImage imageNamed:@"moreSelected"];
            infoAction.backgroundColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
            
            return [UISwipeActionsConfiguration configurationWithActions:@[archiveAction, infoAction]];
        }
            
        case ChatRoomsTypeArchived: {
            UIContextualAction *unarchiveAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [MEGASdkManager.sharedMEGAChatSdk archiveChat:chatListItem.chatId archive:NO];
            }];
            unarchiveAction.image = [UIImage imageNamed:@"unArchiveChat"];
            unarchiveAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
            
            return [UISwipeActionsConfiguration configurationWithActions:@[unarchiveAction]];
        }
    }
}

#pragma clang diagnostic pop

#pragma mark - UIScrolViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.chatRoomsType == ChatRoomsTypeDefault && !self.searchController.isActive) {
        if (scrollView.contentOffset.y > 0 && self.isArchivedChatsRowVisible) {
            self.isScrollAtTop = NO;
            self.isArchivedChatsRowVisible = NO;
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
        if (self.isScrollAtTop && scrollView.contentOffset.y < 0 && !self.isArchivedChatsRowVisible && self.archivedChatListItemList.size != 0 && !self.searchController.active) {
            self.isArchivedChatsRowVisible = YES;
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {      // called when scroll view grinds to a halt
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        self.isScrollAtTop = scrollView.contentOffset.y > 0 ? NO : YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        if (scrollView.contentOffset.y > 0) {
            self.isScrollAtTop = NO;
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchChatListItemArray = nil;
    self.searchUsersWithoutChatArray = nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            self.searchChatListItemArray = self.chatListItemArray;
            self.searchUsersWithoutChatArray = self.usersWithoutChatArray;
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.searchString contains[c] %@", searchString];
            self.searchChatListItemArray = [[self.chatListItemArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];

            NSPredicate *fullnamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            NSPredicate *nicknamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_nickname contains[c] %@", searchString];
            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF.email contains[c] %@", searchString];
            NSPredicate *resultPredicateForUsers = [NSCompoundPredicate orPredicateWithSubpredicates:@[fullnamePredicate, nicknamePredicate, emailPredicate]];
            self.searchUsersWithoutChatArray = [[self.usersWithoutChatArray filteredArrayUsingPredicate:resultPredicateForUsers] mutableCopy];
        }
    }
    
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    CGPoint rowPoint = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rowPoint];
    if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section] || (self.tableView.numberOfSections == 2 && indexPath.section == 0)) {
        return nil;
    }
    
    previewingContext.sourceRect = [self.tableView convertRect:[self.tableView cellForRowAtIndexPath:indexPath].frame toView:self.view];
    
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
    
    ChatViewController *chatViewController = [ChatViewController.alloc init];
    chatViewController.previewMode = YES;
    chatViewController.chatRoom = chatRoom;
    
    return chatViewController;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    ChatViewController *chatViewController = (ChatViewController *)viewControllerToCommit;
    chatViewController.previewMode = NO;

    [self.navigationController pushViewController:chatViewController animated:YES];
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    
    // New chat 1on1 or group
    if (item.changes == 0) {
        [self insertRowByChatListItem:item];
    } else {
        NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(item.chatId)];
        
        if (!indexPath && [item hasChangedForType:MEGAChatListItemChangeTypeArchived]) {
            [self insertRowByChatListItem:item];
            self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
            if (self.isArchivedChatsRowVisible) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }
            return;
        }
        
        if (indexPath && self.chatListItemArray.count > 0) {
            [self.chatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
            ChatRoomCell *cell = (ChatRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            switch (item.changes) {
                case MEGAChatListItemChangeTypeOwnPrivilege:
                    break;
                    
                case MEGAChatListItemChangeTypeUnreadCount:
                    [cell updateUnreadCountChange:item.unreadCount];
                    break;
                    
                case MEGAChatListItemChangeTypeTitle:
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                    break;
                    
                case MEGAChatListItemChangeTypeClosed:
                case MEGAChatListItemChangeTypePreviewClosed:
                    [self deleteRowByChatId:item.chatId];
                    break;
                    
                case MEGAChatListItemChangeTypeLastMsg:
                case MEGAChatListItemChangeTypeLastTs:
                case MEGAChatListItemChangeTypeParticipants:
                    [cell updateLastMessageForChatListItem:item];
                    break;
                    
                case MEGAChatListItemChangeTypeArchived:
                    [self deleteRowByChatId:item.chatId];
                    self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                    if (self.isArchivedChatsRowVisible) {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    if (!self.archivedChatEmptyState.hidden) {
                        self.archivedChatEmptyStateCount.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
                    }
                    if (self.archivedChatListItemList.size == 0) {
                        self.archivedChatEmptyState.hidden = YES;
                    }
                    if (self.chatListItemArray.count == 0) {
                        if (@available(iOS 11.0, *)) {
                            self.navigationItem.searchController = nil;
                        } else {
                            self.tableView.tableHeaderView = nil;
                        }
                    }
                    break;
                    
                default:
                    break;
            }
        }
        
        if (item.changes == MEGAChatListItemChangeTypeLastTs) {
            if ([indexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]] != NSOrderedSame) {
                [self moveRowByChatListItem:item];
            }
        }
    }
}

- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress) {
        return;
    }
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    
    if (userHandle == api.myUserHandle) {
        [self customNavigationBarLabel];
    } else {
        uint64_t chatId = [api chatIdByUserHandle:userHandle];
        NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            ChatRoomCell *cell = (ChatRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForChatStatus:[MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:userHandle]];
        }
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (chatId == MEGAInvalidHandle && newState == MEGAChatConnectionOnline) {
        // Now it's safe to trigger a reordering of the list:
        [self reloadData];
    }
    [self customNavigationBarLabel];
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);

    switch (call.status) {
        case MEGAChatCallStatusUserNoPresent:
        case MEGAChatCallStatusInProgress: {
            NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(call.chatId)];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
            
        case MEGAChatConnectionInProgress:
            if (!self.chatRoomOnGoingCall) {
                self.chatRoomOnGoingCall = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
            }
            break;
            
        case MEGAChatCallStatusJoining:
            [self showTopBannerButton:call];
            [self configureTopBannerButtonForInProgressCall:call];
            break;
            
        case MEGAChatCallStatusReconnecting:
            self.reconnecting = YES;
            [self setTopBannerButtonTitle:AMLocalizedString(@"Reconnecting...", @"Title shown when the user lost the connection in a call, and the app will try to reconnect the user again.") color:UIColor.systemOrangeColor];
            break;
            
        case MEGAChatCallStatusDestroyed: {
            [self.timer invalidate];
            self.chatRoomOnGoingCall = nil;
            NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(call.chatId)];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
            
        case MEGAChatCallStatusTerminatingUserParticipation:
            [self hideTopBannerButton];
            break;
            
        default:
            break;
    }
}

@end
