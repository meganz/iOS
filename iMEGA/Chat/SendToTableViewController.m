
#import "SendToTableViewController.h"

#import "UIImage+GKContact.h"
#import "UIScrollView+EmptyDataSet.h"
#import "SVProgressHUD.h"

#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"

#import "ContactTableViewCell.h"
#import "ChatRoomCell.h"

@interface SendToTableViewController () <UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *sendBarButtonItem;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) NSMutableArray *usersAndGroupChatsMutableArray;
@property (nonatomic, strong) NSMutableArray *searchedUsersAndGroupChatsMutableArray;

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) NSMutableArray *groupChatsMutableArray;
@property (nonatomic, strong) NSMutableArray *searchedGroupChatsMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedGroupChatsMutableArray;

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersMutableArray;
@property (nonatomic, strong) NSMutableArray *searchedUsersMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersMutableArray;

@end

@implementation SendToTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
    self.sendBarButtonItem.title = AMLocalizedString(@"send", @"Label for any 'Send' button, link, text, title, etc. - (String as short as possible).");
    [self.sendBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.f]} forState:UIControlStateNormal];
    
    self.navigationItem.title = AMLocalizedString(@"selectDestination", @"Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.");
    
    UISearchController *searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    searchController.definesPresentationContext = YES;
    searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController = searchController;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    [self setGroupChats];
    
    [self setVisibleUsers];
    
    [self groupAndOrderUserAndGroupChats];
    
    [self.tableView setEditing:YES];
}

#pragma mark - Private

- (void)setGroupChats {
    _chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] activeChatListItems];
    _groupChatsMutableArray = [[NSMutableArray alloc] init];
    _selectedGroupChatsMutableArray = [[NSMutableArray alloc] init];
    if (self.chatListItemList.size) {
        for (NSUInteger i = 0; i < self.chatListItemList.size ; i++) {
            MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:i];
            if (chatListItem.isGroup) {
                [self.groupChatsMutableArray addObject:chatListItem];
            }
        }
    }
}

- (void)setVisibleUsers {
    _users = [[MEGASdkManager sharedMEGASdk] contacts];
    _visibleUsersMutableArray = [[NSMutableArray alloc] init];
    _selectedUsersMutableArray = [[NSMutableArray alloc] init];
    NSInteger count = self.users.size.integerValue;
    for (NSInteger i = 0; i < count; i++) {
        MEGAUser *user = [self.users userAtIndex:i];
        if (user.visibility == MEGAUserVisibilityVisible) {
            [self.visibleUsersMutableArray addObject:user];
        }
    }
}

- (void)groupAndOrderUserAndGroupChats {
    _usersAndGroupChatsMutableArray = [[NSMutableArray alloc] init];
    [self.usersAndGroupChatsMutableArray addObjectsFromArray:self.groupChatsMutableArray];
    [self.usersAndGroupChatsMutableArray addObjectsFromArray:self.visibleUsersMutableArray];
    self.usersAndGroupChatsMutableArray = [[self.usersAndGroupChatsMutableArray sortedArrayUsingComparator:[self comparatorToOrderUsersAndGroupChats]] mutableCopy];
}

- (NSComparator)comparatorToOrderUsersAndGroupChats {
    return ^NSComparisonResult(id a, id b) {
        NSString *first;
        NSString *second;
        if ([a isKindOfClass:MEGAChatListItem.class]) {
            if ([b isKindOfClass:MEGAChatListItem.class]) {
                MEGAChatListItem *chatListItem = a;
                MEGAChatListItem *chatListItem2 = b;
                first = chatListItem.title;
                second = chatListItem2.title;
            }
        }
        
        if ([a isKindOfClass:MEGAUser.class]) {
            if ([b isKindOfClass:MEGAUser.class]) {
                MEGAUser *user = a;
                MEGAUser *user2 = b;
                first = user.mnz_fullName;
                second = user2.mnz_fullName;
            }
        }
        
        if ([a isKindOfClass:MEGAChatListItem.class]) {
            if ([b isKindOfClass:MEGAUser.class]) {
                MEGAChatListItem *chatListItem = a;
                MEGAUser *user2 = b;
                first = chatListItem.title;
                second = user2.mnz_fullName;
            }
        }
        
        if ([a isKindOfClass:MEGAUser.class]) {
            if ([b isKindOfClass:MEGAChatListItem.class]) {
                MEGAUser *user = a;
                MEGAChatListItem *chatListItem2 = b;
                first = user.mnz_fullName;
                second = chatListItem2.title;
            }
        }
        
        return [first compare:second];
    };
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    NSInteger selectedItems = (self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count);
    if (selectedItems == 0) {
        navigationTitle = AMLocalizedString(@"selectDestination", @"Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.");
    } else {
        navigationTitle = [NSString stringWithFormat:AMLocalizedString(@"xSelected", @"Title shown when multiselection is enable in chat tabs, and the user has more than one item selected."), selectedItems];
    }
    
    self.navigationItem.title = navigationTitle;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    id itemAtIndex = nil;
    if (indexPath) {
        itemAtIndex = self.searchController.isActive ? [self.searchedUsersAndGroupChatsMutableArray objectAtIndex:indexPath.row] : [self.usersAndGroupChatsMutableArray objectAtIndex:indexPath.row];
        if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
            return (MEGAChatListItem *)itemAtIndex;
        } else if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
            return (MEGAUser *)itemAtIndex;
        }
    }
    
    return itemAtIndex;
}

- (void)updateMainSearchArray {
    _searchedUsersAndGroupChatsMutableArray = [[NSMutableArray alloc] init];
    [self.searchedUsersAndGroupChatsMutableArray addObjectsFromArray:self.searchedGroupChatsMutableArray];
    [self.searchedUsersAndGroupChatsMutableArray addObjectsFromArray:self.searchedUsersMutableArray];
    self.searchedUsersAndGroupChatsMutableArray = [[self.searchedUsersAndGroupChatsMutableArray sortedArrayUsingComparator:[self comparatorToOrderUsersAndGroupChats]] mutableCopy];
}

- (void)showSuccessMessage {
    NSString *status;
    if (self.nodes.count == 1) {
        if ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) == 1) {
            status = AMLocalizedString(@"fileSentToChat", @"Toast text upon sending a single file to chat");
        } else {
            status = [NSString stringWithFormat:AMLocalizedString(@"fileSentToXChats", @"Success message when the attachment has been sent to a many chats"), (self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) ];
        }
    } else {
        if ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) == 1) {
            status = AMLocalizedString(@"filesSentToChat", @"Toast text upon sending multiple files to chat");
        } else {
            status = [NSString stringWithFormat:AMLocalizedString(@"xfilesSentSuccesfully", @"success message when sending multiple files. Please do not modify the %d placeholder."), self.nodes.count];
        }
    }
    
    [SVProgressHUD showSuccessWithStatus:status];
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendAction:(UIBarButtonItem *)sender {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"chatIsDisabled", @"Title show when you enter on the chat tab and the chat is disabled")];
        return;
    }
    
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        for (MEGANode *node in self.nodes) {
            for (MEGAChatListItem *chatListItem in self.selectedGroupChatsMutableArray) {
                [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatListItem.chatId node:node.handle];
            }
            
            for (MEGAUser *user in self.selectedUsersMutableArray) {
                MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
                if (chatRoom) {
                    [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatRoom.chatId node:node.handle];
                } else {
                    MEGALogDebug(@"There is not a chat with %@, create the chat and attach", user.email);
                    MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
                    [peerList addPeerWithHandle:user.handle privilege:MEGAChatRoomPrivilegeStandard];
                    MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                        [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatRoom.chatId node:node.handle];
                    }];
                    [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
                }
            }
        }
        
        [self showSuccessMessage];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchedGroupChatsMutableArray = nil;
    self.searchedUsersMutableArray = nil;
    self.searchedUsersAndGroupChatsMutableArray = nil;
    
    [self updateNavigationBarTitle];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            self.searchedGroupChatsMutableArray = self.groupChatsMutableArray;
            self.searchedUsersMutableArray = self.visibleUsersMutableArray;
            
            [self updateMainSearchArray];
        } else {
            NSPredicate *chatPredicate = [NSPredicate predicateWithFormat:@"SELF.title contains[c] %@", searchString];
            self.searchedGroupChatsMutableArray = [[self.groupChatsMutableArray filteredArrayUsingPredicate:chatPredicate] mutableCopy];
            
            NSPredicate *usersPredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            self.searchedUsersMutableArray = [[self.visibleUsersMutableArray filteredArrayUsingPredicate:usersPredicate] mutableCopy];
            
            [self updateMainSearchArray];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        id itemAtIndex = [self itemAtIndexPath:indexPath];
        if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
            ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
            
            MEGAChatListItem *chatListItem = itemAtIndex;
            
            cell.onlineStatusView.hidden = YES;
            UIImage *avatar = [UIImage imageForName:chatListItem.title.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(cell.avatarImageView.frame.size.width/2.0f)]];
            
            cell.avatarImageView.image = avatar;
            
            cell.chatTitle.text = chatListItem.title;
            
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
            NSString *participants = AMLocalizedString(@"participants", @"Label to describe the section where you can see the participants of a group chat");
            NSString *xParticipants = [NSString stringWithFormat:@"%lu %@", (unsigned long)chatRoom.peerCount, participants];
            cell.chatLastMessage.text = xParticipants;
            cell.chatLastTime.hidden = YES;
            
            if (@available(iOS 11.0, *)) {
                cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
            }
            
            for (MEGAChatListItem *tempChatListItem in self.selectedGroupChatsMutableArray) {
                if (tempChatListItem.chatId == chatListItem.chatId) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            
            return cell;
        } else if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
            ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
            
            MEGAUser *user = itemAtIndex;
            NSString *userName = user.mnz_fullName;
            
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:user.handle]];
            cell.nameLabel.text = userName ? userName : user.email;
            cell.shareLabel.text = user.email;
            
            [cell.avatarImageView mnz_setImageForUserHandle:user.handle];
            
            if (@available(iOS 11.0, *)) {
                cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
            }
            
            for (MEGAUser *tempUser in self.selectedUsersMutableArray) {
                if ([tempUser.email isEqualToString:user.email]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            
            return cell;
        }
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //TODO: Frequents
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0:
            numberOfRows = self.searchController.isActive ? self.searchedUsersAndGroupChatsMutableArray.count : self.usersAndGroupChatsMutableArray.count;
            break;
            
        default:
            break;
    }
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
    self.searchController.searchBar.userInteractionEnabled = self.searchController.isActive ? YES : (numberOfRows > 0);
    
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleForHeader;
    switch (section) {
        case 0:
            titleForHeader = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section");
            break;
            
        default:
            break;
    }
    
    if (self.searchController.isActive) {
        if (self.searchedUsersAndGroupChatsMutableArray.count == 0) {
            titleForHeader = nil;
        }
    } else {
        if (self.usersAndGroupChatsMutableArray.count == 0) {
            titleForHeader = nil;
        }
    }
    
    return titleForHeader.uppercaseString;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            id itemAtIndex = [self itemAtIndexPath:indexPath];
            if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
                MEGAChatListItem *chatListItem = itemAtIndex;
                [self.selectedGroupChatsMutableArray addObject:chatListItem];
            } else if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
                MEGAUser *user = itemAtIndex;
                [self.selectedUsersMutableArray addObject:user];
            }
            break;
        }
            
        default:
            break;
    }
    
    [self updateNavigationBarTitle];
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            id itemAtIndex = [self itemAtIndexPath:indexPath];
            if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
                MEGAChatListItem *chatListItem = itemAtIndex;
                NSMutableArray *tempSelectedGroupChatsMutableArray = self.selectedGroupChatsMutableArray.copy;
                for (MEGAChatListItem *tempChatListItem in tempSelectedGroupChatsMutableArray) {
                    if (tempChatListItem.chatId == chatListItem.chatId) {
                        [self.selectedGroupChatsMutableArray removeObject:tempChatListItem];
                    }
                }
            } else if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
                MEGAUser *user = itemAtIndex;
                NSMutableArray *tempSelectedUsersMutableArray = self.selectedUsersMutableArray.copy;
                for (MEGAUser *tempUser in tempSelectedUsersMutableArray) {
                    if ([tempUser.email isEqualToString:user.email]) {
                        [self.selectedUsersMutableArray removeObject:tempUser];
                    }
                }
            }
            break;
        }
            
        default:
            break;
    }
    
    [self updateNavigationBarTitle];
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length) {
            text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        text = AMLocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:UIColor.mnz_black333333};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image = nil;
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length) {
            image = [UIImage imageNamed:@"emptySearch"];
        }
    } else {
        image = [UIImage imageNamed:@"emptyContacts"];
    }
    
    return image;
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

@end
