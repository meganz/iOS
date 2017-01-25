#import "ChatRoomsViewController.h"

#import "MEGASdkManager.h"
#import "ChatRoomCell.h"
#import "MessagesViewController.h"
#import "ContactsViewController.h"
#import "MEGANavigationController.h"
#import "ContactDetailsViewController.h"
#import "ChatSettingsTableViewController.h"
#import "MEGAReachabilityManager.h"
#import "GroupChatDetailsViewController.h"

#import "DateTools.h"
#import "UIImage+GKContact.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "UIImageView+MNZCategory.h"
#import "NSMutableAttributedString+MNZCategory.h"

@interface ChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAChatRequestDelegate, MEGAChatDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) NSMutableArray *chatListItemArray;
@property (nonatomic, strong) NSMutableArray *searchChatListItemArray;
@property (nonatomic, strong) NSMutableDictionary *chatIdIndexPathDictionary;

@property (strong, nonatomic) UISearchController *searchController;
@end

@implementation ChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.estimatedRowHeight = 64.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // No search results controller to display the search results in the current view
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.barTintColor = [UIColor colorWithWhite:235.0f / 255.0f alpha:1.0f];
    self.searchController.searchBar.translucent = YES;
    [self.searchController.searchBar sizeToFit];
    
    UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
    searchTextField.font = [UIFont fontWithName:@"SFUIText-Light" size:14.0];
    searchTextField.textColor = [UIColor mnz_gray999999];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    self.title = AMLocalizedString(@"chat", @"Chat section header");
    _chatIdIndexPathDictionary = [[NSMutableDictionary alloc] init];
    _chatListItemArray = [[NSMutableArray alloc] init];
    
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    self.tabBarController.tabBar.hidden = NO;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
  
        self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] activeChatListItems];
        for (NSUInteger i = 0; i < self.chatListItemList.size ; i++) {
            MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:i];
            [self.chatListItemArray addObject:chatListItem];
        }
        
        self.addBarButtonItem.enabled = YES;
        if (!self.tableView.tableHeaderView) {
            self.tableView.tableHeaderView = self.searchController.searchBar;
        }
        
        self.chatListItemArray = [[self.chatListItemArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first  = [[(MEGAChatListItem *)a lastMessage] timestamp];
            NSDate *second = [[(MEGAChatListItem *)b lastMessage] timestamp];
            
            if (!first) {
                first = [NSDate dateWithTimeIntervalSince1970:0];
            }
            if (!second) {
                second = [NSDate dateWithTimeIntervalSince1970:0];
            }
            
            return [second compare:first];
        }] mutableCopy];
        
        [self updateChatIdIndexPathDictionary];
    } else {
        self.addBarButtonItem.enabled = NO;
        self.tableView.tableHeaderView = nil;
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [self.chatListItemArray removeAllObjects];    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = [[NSString alloc] init];
    if (self.searchController.isActive ) {
        if (self.searchController.searchBar.text.length > 0) {
            text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            text = AMLocalizedString(@"chatIsDisabled", @"Title show when you enter on the chat tab and the chat is disabled");
        } else {
            return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"noConversations", @"Empty Conversations section") sectionTitle:AMLocalizedString(@"conversations", @"Conversations section")];
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}


- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        // TODO: We need change this image with a custom image provided by design team
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"emptySearch"];
            } else {
                return nil;
            }
        } else {
            return [UIImage imageNamed:@"emptyContacts"];
        }
    } else {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            text = AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled");
        } else if (!self.searchController.isActive) {
            text = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:20.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIEdgeInsets capInsets = [Helper capInsetsForEmptyStateButton];
    UIEdgeInsets rectInsets = [Helper rectInsetsForEmptyStateButton];
    
    return [[[UIImage imageNamed:@"buttonBorder"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:self.searchController.isActive];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        ChatSettingsTableViewController *chatSettingsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatSettingsTableViewControllerID"];
        [chatSettingsTVC enableChatWithSession];
        [self.navigationController pushViewController:chatSettingsTVC animated:YES];
    } else {
        [self addTapped:(UIBarButtonItem *)button];
    }
}

#pragma mark - Private

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    self.addBarButtonItem.enabled = boolValue;
    
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
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
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
    if (self.searchController.isActive) {
        [self.searchChatListItemArray removeObjectAtIndex:indexPath.row];
        [self.searchChatListItemArray insertObject:item atIndex:0];
    } else {
        [self.chatListItemArray removeObjectAtIndex:indexPath.row];
        [self.chatListItemArray insertObject:item atIndex:0];
    }
    
    [self updateChatIdIndexPathDictionary];
    
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)updateChatIdIndexPathDictionary {
    [self.chatIdIndexPathDictionary removeAllObjects];
    NSInteger i = 0;
    NSArray *tempArray = self.searchController.isActive ? self.searchChatListItemArray : self.chatListItemArray;
    for (MEGAChatListItem *item in tempArray) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [self.chatIdIndexPathDictionary setObject:indexPath forKey:@(item.chatId)];
        i++;
    }
}

#pragma mark - IBActions

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"startConversation", @"start a chat/conversation") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
        ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
        contactsVC.contactsMode = ContactsChatStartConversation;
        contactsVC.userSelected =^void(NSArray *users) {
            if (users.count == 1) {
                MEGAUser *user = [users objectAtIndex:0];
                MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
                if (chatRoom) {
                    MEGALogInfo(@"%@", chatRoom);
                    NSInteger i = 0;
                    for (i = 0; i < self.chatListItemArray.count; i++){
                        if (chatRoom.chatId == [[self.chatListItemArray objectAtIndex:i] chatId]) {
                            break;
                        }
                    }
                    
                    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
                    messagesVC.chatRoom                = chatRoom;
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [self.navigationController pushViewController:messagesVC animated:YES];
                    });
                } else {
                    MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
                    [peerList addPeerWithHandle:user.handle privilege:2];
                    
                    [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:self];
                }
            } else {
                MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
                
                for (NSInteger i = 0; i < users.count; i++) {
                    MEGAUser *user = [users objectAtIndex:i];
                    [peerList addPeerWithHandle:user.handle privilege:2];
                }
                
                [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:YES peers:peerList delegate:self];
            }
        };
        
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }]];
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
        popoverPresentationController.barButtonItem = self.addBarButtonItem;
        popoverPresentationController.sourceView = self.view;
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberOfRows = 0;
    if (self.searchController.isActive) {
        numberOfRows = self.searchChatListItemArray.count;
    } else {
        numberOfRows = self.chatListItemArray.count;
    }
    
    if (numberOfRows == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    
    MEGALogInfo(@"%@", chatListItem);
    
    cell.chatTitle.text = chatListItem.title;
    
    if (chatListItem.lastMessage.isManagementMessage) {
        //TODO: After #5744 is resolved, show the last text message content
        cell.chatLastMessage.text = @"Management Message";
    } else {
        cell.chatLastMessage.text = chatListItem.lastMessage.content;
    }
    cell.chatLastTime.text = chatListItem.lastMessage.timestamp.shortTimeAgoSinceNow;
    if (chatListItem.isGroup) {
        cell.onlineStatusView.hidden = YES;
        UIImage *avatar = [UIImage imageForName:chatListItem.title.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont fontWithName:@"SFUIText-Light" size:(cell.avatarImageView.frame.size.width/2)]];
        
        cell.avatarImageView.image = avatar;
    } else {
        [cell.avatarImageView mnz_setImageForUserHandle:chatListItem.peerHandle];
        if (chatListItem.onlineStatus > MEGAChatStatusOffline) {
            cell.onlineStatusView.backgroundColor = [UIColor mnz_green13E03C];
        } else  {
            cell.onlineStatusView.backgroundColor = [UIColor mnz_gray666666];
        }
        cell.onlineStatusView.hidden             = NO;
        cell.onlineStatusView.layer.cornerRadius = cell.onlineStatusView.frame.size.width / 2;
    }
    
    if (chatListItem.unreadCount != 0) {
        cell.unreadCount.hidden             = NO;
        cell.unreadCount.layer.cornerRadius = 6.0f;
        cell.unreadCount.clipsToBounds      = YES;
        cell.unreadCount.text               = [NSString stringWithFormat:@"%ld", ABS(chatListItem.unreadCount)];
    } else {
        cell.unreadCount.hidden = YES;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    MEGAChatRoom *chatRoom         = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
    
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom                = chatRoom;
    
    [self.navigationController pushViewController:messagesVC animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {    
    MEGAChatListItem *chatListItem = [self chatListItemAtIndexPath:indexPath];
    
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.tableView setEditing:NO];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"mute", @"A button label. The button allows the user to mute a conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
                contactDetailsVC.chatId             = chatRoom.chatId;
                contactDetailsVC.userEmail          = peerEmail;
                contactDetailsVC.userName           = peerName;
                contactDetailsVC.userHandle         = peerHandle;
                [self.navigationController pushViewController:contactDetailsVC animated:YES];
            }
            
        }]];
        
        if ([[UIDevice currentDevice] iPadDevice]) {
            alertController.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
            CGRect moreRect = [self.tableView rectForRowAtIndexPath:indexPath];
            popoverPresentationController.sourceRect = moreRect;
            popoverPresentationController.sourceView = self.tableView;
        }
        [self presentViewController:alertController animated:YES completion:nil];
    }];
    moreAction.backgroundColor = [UIColor mnz_grayCCCCCC];
    
    UITableViewRowAction *deleteAction = nil;
    
    if (chatListItem.isGroup) {
        deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"leave", @"A button label. The button allows the user to leave the conversation.")  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"youWillNoLongerHaveAccessToThisConversation", @"Alert text that explains what means confirming the action 'Leave'") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.tableView setEditing:NO];
            }]];
            
            [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] leaveChat:chatListItem.chatId delegate:self];
                [self.tableView setEditing:NO];
            }]];
            
            if ([[UIDevice currentDevice] iPadDevice]) {
                leaveAlertController.modalPresentationStyle = UIModalPresentationPopover;
                UIPopoverPresentationController *popoverPresentationController = [leaveAlertController popoverPresentationController];
                CGRect deleteRect = [self.tableView rectForRowAtIndexPath:indexPath];
                popoverPresentationController.sourceRect = deleteRect;
                popoverPresentationController.sourceView = self.view;
            }
            [self presentViewController:leaveAlertController animated:YES completion:nil];
        }];
    } else {
        deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"close", @"A button label. The button allows the user to close the conversation.")  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
             [self presentViewController:alertController animated:YES completion:nil];
        }];
    }
    deleteAction.backgroundColor = [UIColor mnz_redFF333A];
    
    return @[deleteAction, moreAction];
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
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.title contains[c] %@", searchString];
            self.searchChatListItemArray = [[self.chatListItemArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
        }
    }
    
    [self updateChatIdIndexPathDictionary];
    [self.tableView reloadData];
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    MEGALogInfo(@"onChatRequestFinish request: %@ \nerror: %@", request, error);
    if (error.type) return;
    
    switch (request.type) {
        case MEGAChatRequestTypeCreateChatRoom: {
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:request.chatHandle];
            
            MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
            messagesVC.chatRoom                = chatRoom;
            
            [self.navigationController pushViewController:messagesVC animated:YES];
            
            break;
        }
            
        case MEGAChatRequestTypeRemoveFromChatRoom: {
            [self deleteRowByChatId:request.chatHandle];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    
    // New chat 1on1 or group
    if (item.changes == 0) {
        [self insertRowByChatListItem:item];
    } else {
        NSIndexPath *indexPath = [self.chatIdIndexPathDictionary objectForKey:@(item.chatId)];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            ChatRoomCell *cell = (ChatRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            switch (item.changes) {
                case MEGAChatListItemChangeTypeStatus:
                    if (item.onlineStatus == 0) {
                        cell.onlineStatusView.backgroundColor = [UIColor mnz_gray666666];
                    } else if (item.onlineStatus == 3) {
                        cell.onlineStatusView.backgroundColor = [UIColor mnz_green13E03C];
                    }
                    break;
                    
                case MEGAChatListItemChangeTypeVisibility:
                    break;
                    
                case MEGAChatListItemChangeTypeUnreadCount:
                    if (cell.unreadCount.hidden && item.unreadCount != 0) {
                        cell.unreadCount.hidden             = NO;
                        cell.unreadCount.layer.cornerRadius = 6.0f;
                        cell.unreadCount.clipsToBounds      = YES;
                    }
                    cell.unreadCount.text = [NSString stringWithFormat:@"%ld", ABS(item.unreadCount)];
                    break;
                    
                case MEGAChatListItemChangeTypeParticipants:
                    break;
                    
                case MEGAChatListItemChangeTypeTitle:
                    cell.chatTitle.text = item.title;
                    break;
                    
                case MEGAChatListItemChangeTypeClosed: {
                    [self deleteRowByChatId:item.chatId];
                    break;
                }
                    
                case MEGAChatListItemChangeTypeLastMsg: {
                    if (item.lastMessage.isManagementMessage) {
                        //TODO: After #5744 is resolved, show the last text message content
                        cell.chatLastMessage.text = @"Management Message";
                    } else {
                        cell.chatLastMessage.text = item.lastMessage.content;
                    }
                    cell.chatLastTime.text = item.lastMessage.timestamp.shortTimeAgoSinceNow;
                    break;
                }
                    
                default:
                    break;
            }
        }
        
        if (item.changes == MEGAChatListItemChangeTypeLastMsg) {
            if ([indexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]] != NSOrderedSame) {
                [self moveRowByChatListItem:item];
            }
        }
    }
}

@end
