#import "ChatRoomsViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIApplication+MNZCategory.h"

#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGAChatChangeGroupNameRequestDelegate.h"
#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UITableView+MNZCategory.h"
#import "UIViewController+MNZCategory.h"

#import "CallViewController.h"
#import "ChatRoomCell.h"
#import "ChatSettingsTableViewController.h"
#import "ContactDetailsViewController.h"
#import "ContactsViewController.h"
#import "GroupCallViewController.h"
#import "GroupChatDetailsViewController.h"
#import "MainTabBarController.h"
#import "MessagesViewController.h"

@interface ChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAChatDelegate, UIScrollViewDelegate, MEGAChatCallDelegate, UISearchControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIView *archivedChatEmptyState;
@property (weak, nonatomic) IBOutlet UILabel *archivedChatEmptyStateTitle;
@property (weak, nonatomic) IBOutlet UILabel *archivedChatEmptyStateCount;

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

@property (weak, nonatomic) IBOutlet UIButton *activeCallButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activeCallTopConstraint;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (strong, nonatomic) MEGAChatRoom *chatRoomOnGoingCall;

@end

@implementation ChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.delegate = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    [self customNavigationBarLabel];
    
    self.chatIdIndexPathDictionary = [[NSMutableDictionary alloc] init];
    self.chatListItemArray = [[NSMutableArray alloc] init];
    
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self configPreviewingRegistration];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    self.tabBarController.tabBar.hidden = NO;
    
    [self customNavigationBarLabel];
    
    MEGAUserList *users = [[MEGASdkManager sharedMEGASdk] contacts];
    self.usersWithoutChatArray = [[NSMutableArray alloc] init];
    NSInteger count = users.size.integerValue;
    for (NSInteger i = 0; i < count; i++) {
        MEGAUser *user = [users userAtIndex:i];
        if (![[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle] && user.visibility == MEGAUserVisibilityVisible) {
            [self.usersWithoutChatArray addObject:user];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        
        switch (self.chatRoomsType) {
            case ChatRoomsTypeDefault:
                self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] chatListItems];
                self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                self.addBarButtonItem.enabled = [MEGAReachabilityManager isReachable];
                break;
                
            case ChatRoomsTypeArchived:
                self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                self.navigationItem.rightBarButtonItem = nil;
                break;
        }


        if (self.chatListItemList.size) {
            [self reorderList];
            
            [self updateChatIdIndexPathDictionary];
            
            if (!self.tableView.tableHeaderView) {
                self.tableView.tableHeaderView = self.searchController.searchBar;
            }
        } else {
            self.tableView.tableHeaderView = nil;
        }
        
    } else {
        self.addBarButtonItem.enabled = NO;
        self.tableView.tableHeaderView = nil;
    }
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    if (self.chatRoomOnGoingCall) {
        self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([DevicePermissionsHelper shouldAskForNotificationsPermissions]) {
        [DevicePermissionsHelper modalNotificationsPermission];
    }
    
    self.chatRoomOnGoingCall = nil;
    MEGAHandleList *chatRoomIDsWithCallInProgress = [MEGASdkManager.sharedMEGAChatSdk chatCallsWithState:MEGAChatCallStatusInProgress];
    if ((chatRoomIDsWithCallInProgress.size > 0) && MEGAReachabilityManager.isReachable) {
        self.chatRoomOnGoingCall = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:[chatRoomIDsWithCallInProgress megaHandleAtIndex:0]];
        
        if (self.activeCallTopConstraint.constant == -44) {
            MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:self.chatRoomOnGoingCall.chatId];
            [self showActiveCallButton:call];
        }
        
        if (!self.chatRoomOnGoingCall && self.activeCallTopConstraint.constant == 0) {
            [self hideActiveCallButton];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.chatListItemArray removeAllObjects];
    [self.chatIdIndexPathDictionary removeAllObjects];
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
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

- (void)dealloc {
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            if ([MEGAReachabilityManager isReachable]) {
                text = AMLocalizedString(@"chatIsDisabled", @"Title show when you enter on the chat tab and the chat is disabled");
            } else {
                text = AMLocalizedString(@"noInternetConnection",  @"Text shown on the app when you don't have connection to the internet or when you have lost it");
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
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper titleAttributesForEmptyState]];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";

    if (self.searchController.isActive) {
        text = @"";
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault:
                    text = AMLocalizedString(@"Start chatting securely with your contacts using end-to-end encryption", @"Empty Conversations description");
                    break;
                    
                case ChatRoomsTypeArchived:
                    break;
            }
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote], NSForegroundColorAttributeName:UIColor.mnz_gray777777};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"searchEmptyState"];
            } else {
                return nil;
            }
        } else {
            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault:
                    return [UIImage imageNamed:@"chatEmptyState"];
                    
                case ChatRoomsTypeArchived:
                    return [UIImage imageNamed:@"chatsArchivedEmptyState"];
            }
        }
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            text = AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled");
        } else if (!self.searchController.isActive) {
            switch (self.chatRoomsType) {
                case ChatRoomsTypeDefault:
                    text = AMLocalizedString(@"New Chat Link", @"Text button for init a group chat with link.");
                    break;
                case ChatRoomsTypeArchived:
                    return nil;
            }
        }
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper buttonTextAttributesForEmptyState]];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIEdgeInsets capInsets = [Helper capInsetsForEmptyStateButton];
    UIEdgeInsets rectInsets = [Helper rectInsetsForEmptyStateButton];
    
    return [[[UIImage imageNamed:@"emptyStateButton"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return UIColor.whiteColor;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:self.searchController.isActive];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    UIImageView *skeletonImageView = nil;
    
    if ([MEGAReachabilityManager isReachable]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            if ([[MEGASdkManager sharedMEGAChatSdk] initState] == MEGAChatInitWaitingNewSession || [[MEGASdkManager sharedMEGAChatSdk] initState] == MEGAChatInitNoCache) {
                skeletonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatListLoading"]];
            }
        }
    }
    
    return skeletonImageView;
}

#pragma mark - DZNEmptyDataSetDelegate

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        ChatSettingsTableViewController *chatSettingsTVC = [[UIStoryboard storyboardWithName:@"ChatSettings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatSettingsTableViewControllerID"];
        [self.navigationController pushViewController:chatSettingsTVC animated:YES];
    } else {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
        [navigationController addLeftCancelButton];
        ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
        contactsVC.contactsMode = ContactsModeChatNamingGroup;
        contactsVC.getChatLinkEnabled = YES;
        [self blockCompletionsForCreateChatInContacts:contactsVC];

        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)emptyDataSetWillAppear:(UIScrollView *)scrollView {
    if (!self.searchController.active) {
        self.searchController.searchBar.hidden = YES;
        if (self.archivedChatListItemList.size) {
            self.archivedChatEmptyStateTitle.text = AMLocalizedString(@"archivedChats", @"Title of archived chats button");
            self.archivedChatEmptyStateCount.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
            self.archivedChatEmptyState.hidden = NO;
        }
    }
}

- (void)emptyDataSetWillDisappear:(UIScrollView *)scrollView {
    if (!self.searchController.active) {
        self.searchController.searchBar.hidden = NO;
        if (!self.archivedChatEmptyState.hidden) {
            self.archivedChatEmptyState.hidden  = YES;
        }
    }
}

#pragma mark - Private

- (void)openChatRoomWithID:(uint64_t)chatID {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        UIViewController *currentVC = self.navigationController.viewControllers[1];
        if ([currentVC isKindOfClass:MessagesViewController.class]) {
            MessagesViewController *currentMessagesVC = (MessagesViewController *)currentVC;
            if (currentMessagesVC.chatRoom.chatId == chatID) {
                if (viewControllers.count != 2) {
                    [self.navigationController popToViewController:currentMessagesVC animated:YES];
                }
                return;
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:currentMessagesVC.chatRoom.chatId delegate:currentMessagesVC];
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
        }
    }
    
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatID];
    
    [self updateBackBarButtonItem:messagesVC.chatRoom.unreadCount];
    
    [self.navigationController pushViewController:messagesVC animated:YES];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
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
    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray removeObjectAtIndex:indexPath.row];
    } else {
        [self.chatListItemArray removeObjectAtIndex:indexPath.row];
    }
    [self updateChatIdIndexPathDictionary];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)insertRowByChatListItem:(MEGAChatListItem *)item {
    NSInteger section = self.isArchivedChatsRowVisible ? 1 : 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray insertObject:item atIndex:indexPath.row];
    } else {
        [self.chatListItemArray insertObject:item atIndex:indexPath.row];
    }
    [self updateChatIdIndexPathDictionary];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
    NSInteger section = self.isArchivedChatsRowVisible ? 1 : 0;
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
                label.userInteractionEnabled = YES;
                label.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomTitleDidTap)]];
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

- (void)chatRoomTitleDidTap {
    if ([[MEGASdkManager sharedMEGAChatSdk] presenceConfig] != nil) {
        [self presentChangeOnlineStatusAlertController];
    }
}

- (void)presentChangeOnlineStatusAlertController {
    UIAlertController *changeOnlineStatusAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [changeOnlineStatusAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    MEGAChatStatus onlineStatus = [[MEGASdkManager sharedMEGAChatSdk] onlineStatus];
    if (MEGAChatStatusOnline != onlineStatus) {
        UIAlertAction *onlineAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"online", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusOnline];
        }];
        [onlineAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
        [changeOnlineStatusAlertController addAction:onlineAlertAction];
    }
    
    if (MEGAChatStatusAway != onlineStatus) {
        UIAlertAction *awayAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"away", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusAway];
        }];
        [awayAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
        [changeOnlineStatusAlertController addAction:awayAlertAction];
    }
    
    if (MEGAChatStatusBusy != onlineStatus) {
        UIAlertAction *busyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"busy", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusBusy];
        }];
        [busyAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
        [changeOnlineStatusAlertController addAction:busyAlertAction];
    }
    
    if (MEGAChatStatusOffline != onlineStatus) {
        UIAlertAction *offlineAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"offline", @"Title of the Offline section") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusOffline];
        }];
        [offlineAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
        [changeOnlineStatusAlertController addAction:offlineAlertAction];
    }
    
    changeOnlineStatusAlertController.modalPresentationStyle = UIModalPresentationPopover;
    changeOnlineStatusAlertController.popoverPresentationController.sourceView = self.view.superview;
    changeOnlineStatusAlertController.popoverPresentationController.sourceRect = self.navigationController.navigationBar.frame;
    
    [self presentViewController:changeOnlineStatusAlertController animated:YES completion:nil];
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
        GroupChatDetailsViewController *groupChatDetailsVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupChatDetailsViewControllerID"];
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        groupChatDetailsVC.chatRoom = chatRoom;
        [self.navigationController pushViewController:groupChatDetailsVC animated:YES];
    } else {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
        NSString *peerEmail     = [[MEGASdkManager sharedMEGAChatSdk] contacEmailByHandle:[chatRoom peerHandleAtIndex:0]];
        NSString *peerFirstname = [chatRoom peerFirstnameAtIndex:0];
        NSString *peerLastname  = [chatRoom peerLastnameAtIndex:0];
        NSString *peerName      = [NSString stringWithFormat:@"%@ %@", peerFirstname, peerLastname];
        uint64_t peerHandle     = [chatRoom peerHandleAtIndex:0];
        
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromChat;
        contactDetailsVC.userEmail          = peerEmail;
        contactDetailsVC.userName           = peerName;
        contactDetailsVC.userHandle         = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

- (void)reorderList {
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

- (void)showChatRoomAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    MEGAChatRoom *chatRoom         = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
    
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom                = chatRoom;
    
    [self updateBackBarButtonItem:chatRoom.unreadCount];
    
    [self.navigationController pushViewController:messagesVC animated:YES];
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
    [cell configureCellForChatListItem:chatListItem];
    return cell;
}

- (UITableViewCell *)userCellForIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    MEGAUser *user = [self.searchUsersWithoutChatArray objectAtIndex:indexPath.row];
    [cell configureCellForUser:user];
    return cell;
}

- (void)showActiveCallButton:(MEGAChatCall *)call {
    self.initDuration = call.duration;
    self.baseDate = [NSDate date];
    [self updateDuration];
    self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.activeCallButton.hidden = NO;
    [UIView animateWithDuration:.5f animations:^ {
        self.activeCallTopConstraint.constant = 0;
        self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
        self.tableView.contentOffset = CGPointZero;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)updateDuration {
    NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
    [self.activeCallButton setTitle:[NSString stringWithFormat:AMLocalizedString(@"Touch to return to call %@", @"Message shown in a chat room for a group call in progress displaying the duration of the call"), [NSString mnz_stringFromTimeInterval:interval]] forState:UIControlStateNormal];
}

- (void)hideActiveCallButton {
    [UIView animateWithDuration:.5f animations:^ {
        self.activeCallTopConstraint.constant = -44;
        self.tableView.contentInset = UIEdgeInsetsZero;
        [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.activeCallButton.hidden = YES;
    }];
    [self.timer invalidate];
}

- (IBAction)joinActiveCall:(id)sender {
    [self.timer invalidate];
    if (self.chatRoomOnGoingCall.isGroup) {
        GroupCallViewController *groupCallVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupCallViewControllerID"];
        groupCallVC.callType = CallTypeActive;
        groupCallVC.videoCall = NO;
        groupCallVC.chatRoom = self.chatRoomOnGoingCall;
        groupCallVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if (@available(iOS 10.0, *)) {
            groupCallVC.megaCallManager = [(MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController megaCallManager];
        }
        [self presentViewController:groupCallVC animated:YES completion:nil];
    } else {
        CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
        callVC.chatRoom = self.chatRoomOnGoingCall;
        callVC.videoCall = NO;
        callVC.callType = CallTypeActive;
        callVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if (@available(iOS 10.0, *)) {
            callVC.megaCallManager = [(MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController megaCallManager];
        }
        [self presentViewController:callVC animated:YES completion:nil];
    }
}

- (IBAction)openArchivedChats:(id)sender {
    ChatRoomsViewController *archivedChatRooms = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatRoomsViewControllerID"];
    [self.navigationController pushViewController:archivedChatRooms animated:YES];
    archivedChatRooms.chatRoomsType = ChatRoomsTypeArchived;
}

- (void)blockCompletionsForCreateChatInContacts:(ContactsViewController *)contactsVC {
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    
    contactsVC.userSelected = ^void(NSArray *users) {
        if (users.count == 1) {
            MEGAUser *user = users.firstObject;
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
            if (chatRoom) {
                MEGALogInfo(@"%@", chatRoom);
                NSInteger i = 0;
                for (i = 0; i < self.chatListItemArray.count; i++){
                    if (chatRoom.chatId == [(MEGAChatRoom *)[self.chatListItemArray objectAtIndex:i] chatId]) {
                        break;
                    }
                }
                
                messagesVC.chatRoom = chatRoom;
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self.navigationController pushViewController:messagesVC animated:YES];
                });
            } else {
                MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
                [peerList addPeerWithHandle:user.handle privilege:2];
                MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                    messagesVC.chatRoom = chatRoom;
                    [self.navigationController pushViewController:messagesVC animated:YES];
                }];
                [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
            }
        }
    };
    
    contactsVC.createGroupChat = ^void(NSArray *users, NSString *groupName, BOOL keyRotation, BOOL getChatLink) {
        MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
        
        for (NSInteger i = 0; i < users.count; i++) {
            MEGAUser *user = [users objectAtIndex:i];
            [peerList addPeerWithHandle:user.handle privilege:2];
        }
        
        if (keyRotation) {
            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                messagesVC.chatRoom = chatRoom;
                [self.navigationController pushViewController:messagesVC animated:YES];                
            }];
            [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:YES peers:peerList title:groupName delegate:createChatGroupRequestDelegate];
        } else {
            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                messagesVC.chatRoom = chatRoom;
                if (getChatLink) {
                    MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
                        if (!error.type) {
                            messagesVC.publicChatWithLinkCreated = YES;
                            messagesVC.publicChatLink = [NSURL URLWithString:request.text];
                            [self.navigationController pushViewController:messagesVC animated:YES];
                        }
                    }];
                    [[MEGASdkManager sharedMEGAChatSdk] createChatLink:chatRoom.chatId delegate:delegate];
                } else {
                    [self.navigationController pushViewController:messagesVC animated:YES];
                }
            }];
            [[MEGASdkManager sharedMEGAChatSdk] createPublicChatWithPeers:peerList title:groupName delegate:createChatGroupRequestDelegate];
        }
    };
}

#pragma mark - IBActions

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.contactsMode = ContactsModeChatStartConversation;
    [self blockCompletionsForCreateChatInContacts:contactsVC];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isArchivedChatsRowVisible) {
        return 2;
    } else {
        if (self.searchController.isActive) {
            return 2;
        } else {
            return 1;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (self.isArchivedChatsRowVisible) {
        if (section == 0) {
            return 1;
        } else {
            return self.chatListItemArray.count;
        }
    } else {
        if (self.searchController.isActive) {
            if (section == 0) {
                return self.searchChatListItemArray.count;
            } else {
                return self.searchUsersWithoutChatArray.count;
            }
        } else {
            return self.chatListItemArray.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            if (self.isArchivedChatsRowVisible) {
                if (indexPath.section == 0) {
                    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"archivedChatsCell" forIndexPath:indexPath];
                    cell.avatarImageView.image = [UIImage imageNamed:@"archiveChat"];
                    cell.chatTitle.text = AMLocalizedString(@"archivedChats", @"Title of archived chats button");
                    cell.chatLastMessage.text = [NSString stringWithFormat:@"%tu", self.archivedChatListItemList.size];
                    return cell;
                } else {
                    return [self chatRoomCellForIndexPath:indexPath];
                }
            } else {
                if (indexPath.section == 0) {
                    return [self chatRoomCellForIndexPath:indexPath];
                } else {
                    return [self userCellForIndexPath:indexPath];
                }
            }
        }
            
        case ChatRoomsTypeArchived:
            return [self archivedChatRoomCellForIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isArchivedChatsRowVisible) {
        if (indexPath.section == 0) {
            [self openArchivedChats:self];
        } else {
            [self showChatRoomAtIndexPath:indexPath];
        }
    } else {
        if (indexPath.section == 0) {
            [self showChatRoomAtIndexPath:indexPath];
        } else {
            MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
            MEGAUser *user = [self.searchUsersWithoutChatArray objectAtIndex:indexPath.row];
            [peerList addPeerWithHandle:user.handle privilege:MEGAChatRoomPrivilegeStandard];
            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
                messagesVC.chatRoom = chatRoom;
                [self.navigationController pushViewController:messagesVC animated:YES];
            }];
            [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
            
            [self.searchUsersWithoutChatArray removeObject:user];
            [self.usersWithoutChatArray removeObject:user];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.isArchivedChatsRowVisible && indexPath.section == 0) || (self.searchController.isActive && indexPath.section == 1) ) {
        return NO;
    } else {
        return YES;
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];

    switch (self.chatRoomsType) {
        case ChatRoomsTypeDefault: {
            UITableViewRowAction *infoAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [self presentGroupOrContactDetailsForChatListItem:chatListItem];
            }];
            infoAction.backgroundColor = UIColor.mnz_grayCCCCCC;
            
            UITableViewRowAction *archiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"archiveChat", @"Title of button to archive chats.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [[MEGASdkManager sharedMEGAChatSdk] archiveChat:chatListItem.chatId archive:YES];
            }];
            archiveAction.backgroundColor = UIColor.mnz_green00BFA5;

            return @[archiveAction, infoAction];
        }
            
        case ChatRoomsTypeArchived: {
            UITableViewRowAction *unarchiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [[MEGASdkManager sharedMEGAChatSdk] archiveChat:chatListItem.chatId archive:NO];
            }];
            unarchiveAction.backgroundColor = UIColor.mnz_green00BFA5;
            
            return @[unarchiveAction];
        }
    }
}

#pragma mark - UIScrolViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.chatRoomsType == ChatRoomsTypeDefault) {
        if (scrollView.contentOffset.y > 0 && self.isArchivedChatsRowVisible) {
            self.isScrollAtTop = NO;
            self.isArchivedChatsRowVisible = NO;
            [self.tableView beginUpdates];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            [self updateChatIdIndexPathDictionary];
        }
        
        if (self.isScrollAtTop && scrollView.contentOffset.y < 0 && !self.isArchivedChatsRowVisible && self.archivedChatListItemList.size != 0 && !self.searchController.active) {
            self.isArchivedChatsRowVisible = YES;
            [self.tableView beginUpdates];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView endUpdates];
            [self updateChatIdIndexPathDictionary];
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
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.title contains[c] %@", searchString];
            self.searchChatListItemArray = [[self.chatListItemArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
            NSPredicate *resultPredicateForUsers = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            self.searchUsersWithoutChatArray = [[self.usersWithoutChatArray filteredArrayUsingPredicate:resultPredicateForUsers] mutableCopy];
        }
    }
    
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    if (self.isArchivedChatsRowVisible) {
        self.isArchivedChatsRowVisible = NO;
        [self.tableView mnz_performBatchUpdates:^{
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        } completion:nil];
    }
    if (UIDevice.currentDevice.iPhoneDevice && UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
        [Helper resetSearchControllerFrame:searchController];
    }
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
    
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom = chatRoom;
    
    return messagesVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
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
                    
                case MEGAChatListItemChangeTypeParticipants:
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
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:userHandle]];
        }
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    // INVALID_HANDLE = ~(uint64_t)0
    if (chatId == ~(uint64_t)0 && newState == MEGAChatConnectionOnline) {
        self.chatListItemArray = [NSMutableArray new];

        switch (self.chatRoomsType) {
            case ChatRoomsTypeDefault:
                self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] chatListItems];
                self.archivedChatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                break;
                
            case ChatRoomsTypeArchived:
                self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] archivedChatListItems];
                break;
        }
        
        // Now it's safe to trigger a reordering of the list:
        [self reorderList];
        [self.tableView reloadData];
    }
    [self customNavigationBarLabel];
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (call.chatId == self.chatRoomOnGoingCall.chatId) {
        if (call.status == MEGAChatCallStatusTerminatingUserParticipation) {
            self.chatRoomOnGoingCall = nil;
            [self hideActiveCallButton];
        }
    }

    switch (call.status) {
        case MEGAChatCallStatusUserNoPresent:
        case MEGAChatCallStatusInProgress: {
            NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(call.chatId)];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
            break;
            
        default:
            break;
    }
}

@end
