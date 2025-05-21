#import "ArchivedChatRoomsViewController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "MEGALinkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "ChatRoomCell.h"
#import "ContactDetailsViewController.h"
#import "EmptyStateView.h"
#import "GroupChatDetailsViewController.h"
#import "TransfersWidgetViewController.h"
#import "NSArray+MNZCategory.h"

@import ChatRepo;
@import MEGAL10nObjc;
@import MEGAUIKit;

@interface ArchivedChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, MEGAChatDelegate, MEGAChatCallDelegate, UISearchControllerDelegate>

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) NSMutableArray *chatListItemArray;
@property (nonatomic, strong) NSMutableArray *searchChatListItemArray;
@property (nonatomic, strong) NSMutableDictionary *chatIdIndexPathDictionary;

@property (nonatomic, getter=isReconnecting) BOOL reconnecting;

@property (nonatomic) ChatNotificationControl *chatNotificationControl;

@end

@implementation ArchivedChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    
    [self customNavigationBarLabel];
    
    self.chatIdIndexPathDictionary = [[NSMutableDictionary alloc] init];
    self.chatListItemArray = [[NSMutableArray alloc] init];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    self.chatListItemList = [MEGAChatSdk.shared archivedChatListItems];
    self.navigationItem.rightBarButtonItems = @[];
    
    if (self.chatListItemList.size) {
        [self reorderList];
        
        [self updateChatIdIndexPathDictionary];
        [self configureSearchController];
    }
    
    [MEGAChatSdk.shared addChatDelegate:self];
    [MEGAChatSdk.shared addChatCallDelegate:self];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;

    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    if ([MEGAChatSdk.shared initState] == MEGAChatInitOnlineSession) {
        [self reloadData];
    }
    
    self.chatNotificationControl = [ChatNotificationControl.alloc initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self askNotificationPermissionsIfNeeded];
    self.navigationController.toolbarHidden = true;
    
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [MEGAChatSdk.shared removeChatDelegate:self];
    [MEGAChatSdk.shared removeChatCallDelegate:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar
           backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if (MEGAReachabilityManager.isReachable) {
        if (MEGAChatSdk.shared.initState == MEGAChatInitWaitingNewSession || MEGAChatSdk.shared.initState == MEGAChatInitNoCache) {
            return [UIImageView.alloc initWithImage:[UIImage megaImageWithNamed:@"chatListLoading"]];
        }
    }
    
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:@"" buttonTitle:[self buttonTitleForEmptyState]];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            text = LocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        text = LocalizedString(@"noArchivedChats", @"Title of empty state view for archived chats.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage megaImageWithNamed:@"searchEmptyState"];
            } else {
                return nil;
            }
        } else {
            if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
                return nil;
            } else {
                return [UIImage megaImageWithNamed:@"chatsArchivedEmptyState"];
            }
        }
    } else {
        return [UIImage megaImageWithNamed:@"noInternetEmptyState"];
    }
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.searchController.isActive) {
            return nil;
        }
    }
    
    return text;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationController.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)internetConnectionChanged {
    [self.tableView reloadData];
}

- (MEGAChatListItem *)chatListItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = nil;
    if (indexPath) {
        if (self.searchController.isActive) {
            chatListItem = [self.searchChatListItemArray objectOrNilAtIndex:indexPath.row];
        } else {
            chatListItem = [self.chatListItemArray objectOrNilAtIndex:indexPath.row];
        }
    }
    return chatListItem;
}

- (void)deleteRowByChatId:(uint64_t)chatId {
    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
    if (self.searchController.isActive) {
        [self.searchChatListItemArray removeObjectAtIndex:indexPath.row];
        for (MEGAChatListItem *chatListItem in [self.chatListItemArray mutableCopy]) {
            if (chatListItem.chatId == chatId) {
                [self.chatListItemArray removeObject:chatListItem];
            }
        }
    } else {
        [self.chatListItemArray removeObjectAtIndex:indexPath.row];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [self updateChatIdIndexPathDictionary];
}

- (void)insertRowByChatListItem:(MEGAChatListItem *)item {
    BOOL addingFirstChat = [self numberOfChatRooms] == 0;
    
    NSInteger section = 0;
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
    NSInteger section = 0;

    NSArray *tempArray = self.searchController.isActive ? self.searchChatListItemArray : self.chatListItemArray;
    for (MEGAChatListItem *item in tempArray) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [self.chatIdIndexPathDictionary setObject:indexPath forKey:@(item.chatId)];
        i++;
    }
}

- (void)presentGroupOrContactDetailsForChatListItem:(MEGAChatListItem *)chatListItem {
    if (chatListItem.isGroup) {
        if ([MEGALinkManager.joiningOrLeavingChatBase64Handles containsObject:[MEGASdk base64HandleForUserHandle:chatListItem.chatId]]) {
            return;
        }
        GroupChatDetailsViewController *groupChatDetailsVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupChatDetailsViewControllerID"];
        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatListItem.chatId];
        groupChatDetailsVC.chatRoom = chatRoom;
        [self.navigationController pushViewController:groupChatDetailsVC animated:YES];
    } else {
        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatListItem.chatId];
        NSString *peerEmail     = [MEGAChatSdk.shared contactEmailByHandle:[chatRoom peerHandleAtIndex:0]];
        uint64_t peerHandle     = [chatRoom peerHandleAtIndex:0];
        
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromChat;
        contactDetailsVC.userEmail          = peerEmail;
        contactDetailsVC.userHandle         = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

- (void)reloadData {
    self.chatListItemList = [MEGAChatSdk.shared archivedChatListItems];
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
    MEGAChatRoom *chatRoom         = [MEGAChatSdk.shared chatRoomForChatId:chatListItem.chatId];
    
    if (chatRoom != nil) {
        [[ChatContentRouter.alloc initWithChatRoom:chatRoom
                                         presenter:self.navigationController
                                        publicLink:nil
                    showShareLinkViewAfterOpenChat:NO
                           chatContentRoutingStyle:ChatContentRoutingStylePush
         ] start];
    }
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

- (BOOL)isUserContactsSectionVisible {
    return [self numberOfChatRooms] > 0;
}

- (void)configureSearchController {
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame));
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfChatRooms];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
        MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatListItem.chatId];

        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
            // This is the view controller that will be presented by long pressing the cell.
            // It is a UIKit feature that breaks the router navigation, as it needs the ChatViewController object.
            // The router exposes it in order to keep the feature, but *@objc static func chatViewController(for chatRoom: MEGAChatRoom) -> ChatViewController?* should be removed once ArchivedChatRoomsViewController is refactored into SwiftUI.
            ChatViewController *chatViewController = [ChatContentRouter chatViewControllerFor:chatRoom];
            chatViewController.previewMode = YES;
            return chatViewController;
            
        } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            NSMutableArray *menus = [NSMutableArray new];
            
            if (chatRoom.unreadCount != 0) {
                UIAction *markAsReadAction = [UIAction actionWithTitle:LocalizedString(@"Mark as Read",@"A button label. The button allows the user to mark a conversation as read.") image:[UIImage megaImageWithNamed:@"markUnread_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [MEGAChatSdk.shared setMessageSeenForChat:chatListItem.chatId messageId:chatListItem.lastMessageId];
                }];
                [menus addObject:markAsReadAction];
            }
            
            BOOL muted = [self.chatNotificationControl isChatDNDEnabledWithChatId:chatListItem.chatId];
            if (muted) {
                UIAction *unmuteAction = [UIAction actionWithTitle:LocalizedString(@"unmute", @"A button label. The button allows the user to unmute a conversation") image:[UIImage megaImageWithNamed:@"mutedChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self.chatNotificationControl turnOffDNDWithChatId:chatListItem.chatId];
                }];
                [menus addObject:unmuteAction];
            } else {
                UIAction *muteAction = [UIAction actionWithTitle:LocalizedString(@"mute", @"A button label. The button allows the user to mute a conversation") image:[UIImage megaImageWithNamed:@"mutedChat_menu"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self.chatNotificationControl turnOnDNDWithChatId:chatListItem.chatId isChatTypeMeeting:chatListItem.isMeeting sender:[tableView cellForRowAtIndexPath:indexPath]];
                }];
                [menus addObject:muteAction];
            }

            UIAction *infoAction = [UIAction actionWithTitle:LocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context. ") image:[UIImage megaImageWithNamed:@"info"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [self presentGroupOrContactDetailsForChatListItem:chatListItem];
            }];
            [menus addObject:infoAction];
            
            UIAction *archiveChatAction = [UIAction actionWithTitle:LocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") image:[UIImage megaImageWithNamed:@"unArchiveChat"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [MEGAChatSdk.shared archiveChat:chatListItem.chatId archive:NO];
            }];
            [menus addObject:archiveChatAction];
            return [UIMenu menuWithTitle:@"" children:menus];
        }];
        return configuration;
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    ChatViewController *previewViewController = (ChatViewController *)animator.previewViewController;
    [animator addCompletion:^{
        [self.navigationController pushViewController:previewViewController animated:NO];
        previewViewController.previewMode = NO;
        [previewViewController update];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self archivedChatRoomCellForIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showChatRoomAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    
    UIContextualAction *unarchiveAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [MEGAChatSdk.shared archiveChat:chatListItem.chatId archive:NO];
    }];
    unarchiveAction.image = [UIImage megaImageWithNamed:@"unArchiveChat"];
    unarchiveAction.backgroundColor = [UIColor supportSuccessColor];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[unarchiveAction]];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchChatListItemArray = nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            self.searchChatListItemArray = self.chatListItemArray;
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.searchString contains[c] %@", searchString];
            self.searchChatListItemArray = [[self.chatListItemArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
        }
    }
    
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    // New chat 1on1 or group
    if (item.changes == 0) {
        [self insertRowByChatListItem:item];
    } else {
        NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(item.chatId)];
        
        if (!indexPath && [item hasChangedForType:MEGAChatListItemChangeTypeArchived]) {
            [self insertRowByChatListItem:item];
            return;
        }
        
        if (indexPath && self.chatListItemArray.count > 0) {
            if (self.searchController.isActive) {
                [self.searchChatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
            } else {
                [self.chatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
            }
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
                    self.chatListItemList = [MEGAChatSdk.shared archivedChatListItems];
                    if (self.chatListItemArray.count == 0) {
                        self.navigationItem.searchController = nil;
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
    uint64_t chatId = [api chatIdByUserHandle:userHandle];
    NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(chatId)];
    if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
        ChatRoomCell *cell = (ChatRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.onlineStatusView.backgroundColor = [UIColor colorWithChatStatus:[MEGAChatSdk.shared userOnlineStatus:userHandle]];
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (chatId == MEGAInvalidHandle && newState == MEGAChatConnectionOnline) {
        // Now it's safe to trigger a reordering of the list:
        [self reloadData];
    }
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);

    switch (call.status) {
        case MEGAChatCallStatusDestroyed:
        case MEGAChatCallStatusTerminatingUserParticipation:
        case MEGAChatCallStatusUserNoPresent: {
            NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(call.chatId)];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
            
        default:
            break;
    }
}

@end
