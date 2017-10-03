#import "ChatRoomsViewController.h"

#import "DateTools.h"
#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSMutableAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "ChatRoomCell.h"
#import "ChatSettingsTableViewController.h"
#import "ContactDetailsViewController.h"
#import "ContactsViewController.h"
#import "GroupChatDetailsViewController.h"
#import "MessagesViewController.h"

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
    
    // No search results controller to display the search results in the current view
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.barTintColor = [UIColor colorWithWhite:235.0f / 255.0f alpha:1.0f];
    self.searchController.searchBar.translucent = YES;
    [self.searchController.searchBar sizeToFit];
    
    UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
    searchTextField.font = [UIFont mnz_SFUIRegularWithSize:14.0f];
    searchTextField.textColor = [UIColor mnz_gray999999];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    [self customNavigationBarLabel];
    
    _chatIdIndexPathDictionary = [[NSMutableDictionary alloc] init];
    _chatListItemArray = [[NSMutableArray alloc] init];
    
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backBarButton;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    self.tabBarController.tabBar.hidden = NO;
    
    [self customNavigationBarLabel];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] activeChatListItems];
        for (NSUInteger i = 0; i < self.chatListItemList.size ; i++) {
            MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:i];
            [self.chatListItemArray addObject:chatListItem];
        }
        
        self.addBarButtonItem.enabled = [MEGAReachabilityManager isReachable];
        if (!self.tableView.tableHeaderView) {
            self.tableView.tableHeaderView = self.searchController.searchBar;
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
        
        [self updateChatIdIndexPathDictionary];
        
        [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    } else {
        self.addBarButtonItem.enabled = NO;
        self.tableView.tableHeaderView = nil;
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
    
    [self.chatListItemArray removeAllObjects];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (self.searchController.isActive ) {
        if (self.searchController.searchBar.text.length > 0) {
            text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            if ([MEGAReachabilityManager isReachable]) {
                text = AMLocalizedString(@"chatIsDisabled", @"Title show when you enter on the chat tab and the chat is disabled");
            } else {
                text = AMLocalizedString(@"noInternetConnection",  @"Text shown on the app when you don't have connection to the internet or when you have lost it");
            }
        } else {
            return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"noConversations", @"Empty Conversations section") sectionTitle:AMLocalizedString(@"conversations", @"Conversations section")];
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
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
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:20.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]};
    
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

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            if ([[MEGASdkManager sharedMEGAChatSdk] initState] == MEGAChatInitWaitingNewSession || [[MEGASdkManager sharedMEGAChatSdk] initState] == MEGAChatInitNoCache) {
                UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [indicator startAnimating];
                return indicator;
            }
        }
    }
    return nil;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        ChatSettingsTableViewController *chatSettingsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatSettingsTableViewControllerID"];
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

- (void)updateCell:(ChatRoomCell *)cell forUnreadCountChange:(NSInteger)unreadCount {
    if (unreadCount != 0) {
        if (cell.unreadView.hidden) {
            cell.chatTitle.font = [UIFont mnz_SFUIMediumWithSize:15.0f];
            cell.chatTitle.textColor = [UIColor mnz_black333333];
            cell.chatLastMessage.font = [UIFont mnz_SFUIMediumWithSize:12.0f];
            cell.chatLastMessage.textColor = [UIColor mnz_black333333];
            cell.chatLastTime.font = [UIFont mnz_SFUIMediumWithSize:10.0f];
            cell.chatLastTime.textColor = [UIColor mnz_black333333];
            
            cell.unreadView.hidden = NO;
            cell.unreadView.clipsToBounds = YES;
        }
        
        cell.unreadCount.text = [NSString stringWithFormat:@"%ld", ABS(unreadCount)];
    } else {
        cell.chatTitle.font = [UIFont mnz_SFUIRegularWithSize:15.0f];
        cell.chatTitle.textColor = [UIColor mnz_gray666666];
        cell.chatLastMessage.font = [UIFont mnz_SFUIRegularWithSize:12.0f];
        cell.chatLastMessage.textColor = [UIColor mnz_gray666666];
        cell.chatLastTime.font = [UIFont mnz_SFUIRegularWithSize:10.0f];
        cell.chatLastTime.textColor = [UIColor mnz_gray666666];
        
        cell.unreadView.hidden = YES;
        cell.unreadCount.text = nil;
    }
}

- (void)updateCell:(ChatRoomCell *)cell forChatListItem:(MEGAChatListItem *)item {
    switch (item.lastMessageType) {
        case MEGAChatMessageTypeInvalid: {
            cell.chatLastMessage.text = AMLocalizedString(@"noConversationHistory", @"Information if there are no history messages in current chat conversation");
            cell.chatLastTime.hidden = YES;
            break;
        }
            
        case MEGAChatMessageTypeAttachment: {
            NSString *lastMessageString = item.lastMessage;
            NSArray *componentsArray = [lastMessageString componentsSeparatedByString:@"\x01"];
            if (componentsArray.count == 1) {
                NSString *attachedFileString = AMLocalizedString(@"attachedFile", @"A message appearing in the chat summary window when the most recent action performed by a user was attaching a file. Please keep %s as it will be replaced at runtime with the name of the attached file.");
                lastMessageString = [attachedFileString stringByReplacingOccurrencesOfString:@"%s" withString:lastMessageString];
            } else {
                lastMessageString = AMLocalizedString(@"attachedXFiles", @"A summary message when a user has attached many files at once into the chat. Please keep %s as it will be replaced at runtime with the number of files.");
                lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%lu", componentsArray.count]];
            }
            cell.chatLastMessage.text = lastMessageString;
            cell.chatLastTime.text = item.lastMessageDate.shortTimeAgoSinceNow;
            cell.chatLastTime.hidden = NO;
            break;
        }
            
        case MEGAChatMessageTypeContact: {
            NSString *lastMessageString = item.lastMessage;
            NSArray *componentsArray = [lastMessageString componentsSeparatedByString:@"\x01"];
            if (componentsArray.count == 1) {
                NSString *sentContactString = AMLocalizedString(@"sentContact", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
                lastMessageString = [sentContactString stringByReplacingOccurrencesOfString:@"%s" withString:lastMessageString];
            } else {
                lastMessageString = AMLocalizedString(@"sentXContacts", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
                lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%lu", componentsArray.count]];
            }
            cell.chatLastMessage.text = lastMessageString;
            cell.chatLastTime.text = item.lastMessageDate.shortTimeAgoSinceNow;
            cell.chatLastTime.hidden = NO;
            break;
        }
            
        default: {
            cell.chatLastMessage.text = item.lastMessage;
            cell.chatLastTime.text = item.lastMessageDate.shortTimeAgoSinceNow;
            cell.chatLastTime.hidden = NO;
            break;
        }
    }
}

- (void)customNavigationBarLabel {
    NSString *onlineStatusString = [NSString chatStatusString:[[MEGASdkManager sharedMEGAChatSdk] onlineStatus]];
    if (onlineStatusString) {
        UILabel *label = [Helper customNavigationBarLabelWithTitle:AMLocalizedString(@"chat", @"Chat section header") subtitle:onlineStatusString];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        label.userInteractionEnabled = YES;
        label.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomTitleDidTap)]];
        [self.navigationItem setTitleView:label];
    } else {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = AMLocalizedString(@"chat", @"Chat section header");
    }
}

- (void)chatRoomTitleDidTap {
    if ([[MEGASdkManager sharedMEGAChatSdk] presenceConfig] != nil) {
        [self presentChangeOnlineStatusAlertController];
    }
}

- (void)presentChangeOnlineStatusAlertController {
    UIAlertController *changeOnlineStatusAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [changeOnlineStatusAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    MEGAChatStatus onlineStatus = [[MEGASdkManager sharedMEGAChatSdk] onlineStatus];
    if (MEGAChatStatusOnline != onlineStatus) {
        UIAlertAction *onlineAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"online", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusOnline];
        }];
        [onlineAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
        [changeOnlineStatusAlertController addAction:onlineAlertAction];
    }
    
    if (MEGAChatStatusAway != onlineStatus) {
        UIAlertAction *awayAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"away", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusAway];
        }];
        [awayAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
        [changeOnlineStatusAlertController addAction:awayAlertAction];
    }
    
    if (MEGAChatStatusBusy != onlineStatus) {
        UIAlertAction *busyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"busy", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusBusy];
        }];
        [busyAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
        [changeOnlineStatusAlertController addAction:busyAlertAction];
    }
    
    if (MEGAChatStatusOffline != onlineStatus) {
        UIAlertAction *offlineAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"offline", @"Title of the Offline section") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeToOnlineStatus:MEGAChatStatusOffline];
        }];
        [offlineAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
        [changeOnlineStatusAlertController addAction:offlineAlertAction];
    }
    
    changeOnlineStatusAlertController.modalPresentationStyle = UIModalPresentationPopover;
    changeOnlineStatusAlertController.popoverPresentationController.sourceView = self.view;
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
        contactDetailsVC.chatId             = chatRoom.chatId;
        contactDetailsVC.userEmail          = peerEmail;
        contactDetailsVC.userName           = peerName;
        contactDetailsVC.userHandle         = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

#pragma mark - IBActions

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.contactsMode = ContactsModeChatStartConversation;
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
    [self updateCell:cell forChatListItem:chatListItem];
    
    if (chatListItem.isGroup) {
        cell.onlineStatusView.hidden = YES;
        UIImage *avatar = [UIImage imageForName:chatListItem.title.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(cell.avatarImageView.frame.size.width/2.0f)]];
        
        cell.avatarImageView.image = avatar;
    } else {
        [cell.avatarImageView mnz_setImageForUserHandle:chatListItem.peerHandle];
        cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:chatListItem.peerHandle]];
        cell.onlineStatusView.hidden             = NO;
    }
    
    [self updateCell:cell forUnreadCountChange:chatListItem.unreadCount];
    
    cell.separatorInset = UIEdgeInsetsMake(0.0, 57.0, 0.0, 0.0);
    
    return cell;
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
    
    //TODO: While the "More" action only shows "Info" on a UIAlertController with UIAlertControllerStyleActionSheet style, it will replaced by the "Info" action itself
    UITableViewRowAction *infoAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self presentGroupOrContactDetailsForChatListItem:chatListItem];
    }];
    infoAction.backgroundColor = [UIColor mnz_grayCCCCCC];
    
    UITableViewRowAction *deleteAction = nil;
    if (chatListItem.isGroup) {
        deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"leave", @"A button label. The button allows the user to leave the conversation.")  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"youWillNoLongerHaveAccessToThisConversation", @"Alert text that explains what means confirming the action 'Leave'") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.tableView setEditing:NO];
            }]];
            
            [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] leaveChat:chatListItem.chatId];
                [self.tableView setEditing:NO];
            }]];
            
            leaveAlertController.modalPresentationStyle = UIModalPresentationPopover;
            CGRect deleteRect = [self.tableView rectForRowAtIndexPath:indexPath];
            leaveAlertController.popoverPresentationController.sourceRect = deleteRect;
            leaveAlertController.popoverPresentationController.sourceView = self.view;
            
            [self presentViewController:leaveAlertController animated:YES completion:nil];
        }];
    } else {
        deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"close", @"A button label. The button allows the user to close the conversation.")  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            //TODO: When possible, allow deleting a 1on1 conversation.
        }];
    }
    deleteAction.backgroundColor = [UIColor mnz_redFF333A];
    
    return chatListItem.isGroup ? @[deleteAction, infoAction] : @[infoAction];
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
                case MEGAChatListItemChangeTypeOwnPrivilege:
                    break;
                    
                case MEGAChatListItemChangeTypeUnreadCount:
                    [self updateCell:cell forUnreadCountChange:item.unreadCount];
                    break;
                    
                case MEGAChatListItemChangeTypeParticipants:
                    break;
                    
                case MEGAChatListItemChangeTypeTitle:
                    [self.chatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
                    cell.chatTitle.text = item.title;
                    break;
                    
                case MEGAChatListItemChangeTypeClosed:
                    [self deleteRowByChatId:item.chatId];
                    break;
                    
                case MEGAChatListItemChangeTypeLastMsg:
                case MEGAChatListItemChangeTypeLastTs:
                   if (!self.chatListItemArray || !self.chatListItemArray.count ) {
                       [self.chatListItemArray addObject:(item)];
                    }
                   else{
                       [self.chatListItemArray replaceObjectAtIndex:indexPath.row withObject:item];
                   }
                    [self updateCell:cell forChatListItem:item];
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

@end
