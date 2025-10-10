#import "SendToViewController.h"

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"

#import "UIImageView+MNZCategory.h"

#import "EmptyStateView.h"
#import "Helper.h"
#import "MEGAChatAttachNodeRequestDelegate.h"
#import "MEGAChatAttachVoiceClipRequestDelegate.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGAUser+MNZCategory.h"

#import "ContactTableViewCell.h"
#import "ChatRoomCell.h"
#import "ItemListViewController.h"
#import "NSString+MNZCategory.h"
@import ChatRepo;
@import DZNEmptyDataSet;
@import MEGAUIKit;
#import "LocalizationHelper.h"

@interface SendToViewController () <UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UISearchControllerDelegate, ItemListViewControllerDelegate, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendBarButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemListViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *itemListView;
@property (weak, nonatomic) IBOutlet UIView *searchView;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) NSMutableArray *searchedUsersAndGroupChatsMutableArray;

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) NSMutableArray *recentsMutableArray;
@property (nonatomic, strong) NSMutableArray *searchedGroupChatsMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedGroupChatsMutableArray;

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersMutableArray;
@property (nonatomic, strong) NSMutableArray *searchedUsersMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersMutableArray;

@property (nonatomic) NSUInteger pendingAttachNodeOperations;

@property (strong, nonatomic) ItemListViewController *itemListVC;

@property (nonatomic) NSUInteger pendingForwardOperations;
@property (nonatomic) NSMutableArray<NSNumber *> *chatIdNumbers;
@property (nonatomic) NSMutableArray<MEGAChatMessage *> *sentMessages;

@property (nonatomic) UIPanGestureRecognizer *panOnTable;

@end

@implementation SendToViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    switch (self.sendMode) {
        case SendModeCloud:
        case SendModeForward:
        case SendModeFileAndFolderLink:
        case SendModeText:
            self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
            break;
            
        case SendModeShareExtension:
            self.navigationItem.leftBarButtonItem = nil;
            break;
    }
    
    self.sendBarButtonItem.title = LocalizedString(@"send", @"Label for any 'Send' button, link, text, title, etc. - (String as short as possible).");
    [self.sendBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [self.sendBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightSemibold]} forState:UIControlStateDisabled];

    self.navigationItem.title = LocalizedString(@"selectDestination", @"Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.");
    
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self searchControllerDelegate:self];
    self.searchController.definesPresentationContext = YES;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    [self.searchView addSubview:self.searchController.searchBar];
    
    [self setGroupChatsAndRecents];
    [self setVisibleUsers];
    [self groupAndOrderUserAndGroupChats];
    [self sortAndFilterRecents];
    
    [self.tableView setEditing:YES];
    
    self.panOnTable = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(shouldDismissSearchController)];
    self.panOnTable.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"GenericHeaderFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"GenericHeaderFooterViewID"];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.presentationController.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Public
- (NSUInteger)selectedChatCount {
    return self.selectedUsersMutableArray.count + self.selectedGroupChatsMutableArray.count;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = self.tableView.backgroundColor = [UIColor pageBackgroundColor];
    self.searchView.backgroundColor = [UIColor surface1Background];
}

- (void)setGroupChatsAndRecents {
    self.chatListItemList = [MEGAChatSdk.shared activeChatListItems];
    self.groupChatsMutableArray = [[NSMutableArray alloc] init];
    self.selectedGroupChatsMutableArray = [[NSMutableArray alloc] init];
    if (self.chatListItemList.size) {
        for (NSUInteger i = 0; i < self.chatListItemList.size ; i++) {
            MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:i];
            if (chatListItem.ownPrivilege >= MEGAChatRoomPrivilegeStandard) {
                if (chatListItem.isGroup) {
                    [self.groupChatsMutableArray addObject:chatListItem];
                }
            }
        }
        [self addNoteToSelfIfNeeded];
    }
}

- (void)setVisibleUsers {
    self.users = [MEGASdk.shared contacts];
    self.visibleUsersMutableArray = [[NSMutableArray alloc] init];
    self.selectedUsersMutableArray = [[NSMutableArray alloc] init];
    NSInteger count = self.users.size;
    for (NSInteger i = 0; i < count; i++) {
        MEGAUser *user = [self.users userAtIndex:i];
        if (user.visibility == MEGAUserVisibilityVisible) {
            [self.visibleUsersMutableArray addObject:user];
        }
    }
}

- (void)groupAndOrderUserAndGroupChats {
    self.usersAndGroupChatsMutableArray = [[NSMutableArray alloc] init];
    [self.usersAndGroupChatsMutableArray addObjectsFromArray:self.groupChatsMutableArray];
    [self.usersAndGroupChatsMutableArray addObjectsFromArray:self.visibleUsersMutableArray];
    self.usersAndGroupChatsMutableArray = [[self.usersAndGroupChatsMutableArray sortedArrayUsingComparator:[self comparatorToOrderUsersAndGroupChats]] mutableCopy];
    if ([self isNoteToSelfAvailable]) {
        [self placeNoteToSelfChatAtTop];
    }
}

- (NSComparator)comparatorToOrderUsersAndGroupChats {
    return ^NSComparisonResult(id a, id b) {
        NSString *first;
        NSString *second;
        
        if ([a isKindOfClass:MEGAChatListItem.class]) {
            MEGAChatListItem *chatListItem = a;
            first = chatListItem.title;
        } else if ([a isKindOfClass:MEGAUser.class]) {
            first = ((MEGAUser *)a).mnz_displayName;
        }
        
        if ([b isKindOfClass:MEGAChatListItem.class]) {
            MEGAChatListItem *chatListItem = b;
            second = chatListItem.title;
        } else {
            second = ((MEGAUser *)b).mnz_displayName;
        }
        
        return [first compare:second options:NSCaseInsensitiveSearch];
    };
}

- (void)sortAndFilterRecents {
    self.recentsMutableArray = [MEGAChatSdk.shared recentChatsWithMax:5].mutableCopy;
    for (NSUInteger i = 0; i < self.recentsMutableArray.count; i++) {
        MEGAChatListItem *chatListItem = [self.recentsMutableArray objectAtIndex:i];
        if (!chatListItem.isGroup) {
            for (MEGAUser *user in self.visibleUsersMutableArray) {
                if (user.handle == chatListItem.peerHandle) {
                    [self.recentsMutableArray replaceObjectAtIndex:i withObject:user];
                    break;
                }
            }
        }
    }
    [self.usersAndGroupChatsMutableArray removeObjectsInArray:self.recentsMutableArray];
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    NSInteger selectedItems = (self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count);
    if (selectedItems == 0) {
        navigationTitle = LocalizedString(@"selectDestination", @"Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.");
    } else {
        navigationTitle = (selectedItems == 1) ? LocalizedString(@"1 selected", @"Title shown when multiselection is enabled and only one item has been selected.") : [NSString stringWithFormat:LocalizedString(@"xSelected", @"Title shown when multiselection is enabled and the user has more than one item selected."), selectedItems];
    }
    
    self.navigationItem.title = navigationTitle;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    
    id itemAtIndex = nil;
    
    if (self.searchController.isActive) {
        itemAtIndex = [self.searchedUsersAndGroupChatsMutableArray objectAtIndex:indexPath.row];
    } else if (indexPath.section == 0) {
        itemAtIndex = [self.recentsMutableArray objectAtIndex:indexPath.row];
    } else {
        itemAtIndex = [self.usersAndGroupChatsMutableArray objectAtIndex:indexPath.row];
    }
    
    return itemAtIndex;
}

- (void)updateMainSearchArray {
    self.searchedUsersAndGroupChatsMutableArray = [[NSMutableArray alloc] init];
    [self.searchedUsersAndGroupChatsMutableArray addObjectsFromArray:self.searchedGroupChatsMutableArray];
    [self.searchedUsersAndGroupChatsMutableArray addObjectsFromArray:self.searchedUsersMutableArray];
    self.searchedUsersAndGroupChatsMutableArray = [[self.searchedUsersAndGroupChatsMutableArray sortedArrayUsingComparator:[self comparatorToOrderUsersAndGroupChats]] mutableCopy];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self.tableView addGestureRecognizer:self.panOnTable];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self shouldDismissSearchController];
    [self.tableView removeGestureRecognizer:self.panOnTable];
}

- (void)shouldDismissSearchController {
    switch (self.sendMode) {
        case SendModeCloud:
        case SendModeShareExtension:
            if (self.searchController.isActive) {
                [self.searchController.searchBar resignFirstResponder];
            }
            break;
            
        default:
            break;
    }
}

- (void)addItemToList:(ItemListModel *)item {
    if (self.childViewControllers.count) {
        [self.itemListVC addItem:item];
    } else {
        [UIView animateWithDuration:.25 animations:^{
            self.itemListViewHeightConstraint.constant = 110;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            ItemListViewController *usersList = [[UIStoryboard storyboardWithName:@"ItemListViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"ItemListViewControllerID"];
            self.itemListVC = usersList;
            self.itemListVC.itemListDelegate = self;
            [self addChildViewController:usersList];
            usersList.view.frame = self.itemListView.bounds;
            [self.itemListView addSubview:usersList.view];
            [usersList didMoveToParentViewController:self];
            [self.itemListVC addItem:item];
        }];
    }
}

- (void)removeUsersListSubview {
    ItemListViewController *usersList = self.childViewControllers.lastObject;
    [usersList willMoveToParentViewController:nil];
    [usersList.view removeFromSuperview];
    [usersList removeFromParentViewController];
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:.25 animations:^ {
        self.itemListViewHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];
    }];
}

- (void)completeForwardingMessage:(MEGAChatMessage *)message toChat:(uint64_t)chatId {
    @synchronized(self.sentMessages) {
        if (message && chatId == self.sourceChatId && message.type != MEGAChatMessageTypeAttachment && message.type != MEGAChatMessageTypeVoiceClip) {
            [self.sentMessages addObject:message];
        }
        
        if (--self.pendingForwardOperations == 0) {
            self.completion(self.chatIdNumbers, self.sentMessages);
        }
    }
}

- (void)forwardMessages {
    for (MEGAChatMessage *message in self.messages) {
        switch (message.type) {
            case MEGAChatMessageTypeNormal:
            case MEGAChatMessageTypeContainsMeta: {
                for (NSNumber *chatIdNumber in self.chatIdNumbers) {
                    uint64_t chatId = chatIdNumber.unsignedLongLongValue;
                    MEGAChatMessage *newMessage;
                    if (message.containsMeta.type == MEGAChatContainsMetaTypeGeolocation) {
                        newMessage = [MEGAChatSdk.shared sendGeolocationToChat:chatId longitude:message.containsMeta.geolocation.longitude latitude:message.containsMeta.geolocation.latitude image:message.containsMeta.geolocation.image];
                    } else if (message.containsMeta.type == MEGAChatContainsMetaTypeGiphy) {
                        newMessage = [MEGAChatSdk.shared sendGiphyToChat:chatId srcMp4:message.containsMeta.giphy.mp4Src srcWebp:message.containsMeta.giphy.webpSrc sizeMp4:message.containsMeta.giphy.mp4Size sizeWebp:message.containsMeta.giphy.webpSize width:message.containsMeta.giphy.width height:message.containsMeta.giphy.height title:message.containsMeta.giphy.title];
                    } else {
                        newMessage = [MEGAChatSdk.shared sendMessageToChat:chatId message:message.content];
                    }
                    [self completeForwardingMessage:newMessage toChat:chatId];
                }
                
                break;
            }
            case MEGAChatMessageTypeContact: {
                for (NSNumber *chatIdNumber in self.chatIdNumbers) {
                    uint64_t chatId = chatIdNumber.unsignedLongLongValue;
                    MEGAChatMessage *newMessage = [MEGAChatSdk.shared forwardContactFromChat:self.sourceChatId messageId:message.messageId targetChatId:chatId];
                    [self completeForwardingMessage:newMessage toChat:chatId];
                }
                
                break;
            }
                
            case MEGAChatMessageTypeAttachment:
            case MEGAChatMessageTypeVoiceClip: {
                MEGANode *node = [message.nodeList mnz_nodesArrayFromNodeList].firstObject;
                [Helper importNode:node toShareWithCompletion:^(MEGANode *node) {
                    [self attachNode:node.handle asVoiceClip:message.type == MEGAChatMessageTypeVoiceClip];
                }];
                
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)attachNode:(uint64_t)handle asVoiceClip:(BOOL)asVoiceClip {
    void (^completion)(MEGAChatRequest *request, MEGAChatError *error) = ^(MEGAChatRequest *request, MEGAChatError *error) {
        [self completeForwardingMessage:request.chatMessage toChat:request.chatHandle];
    };
    
    MEGAChatBaseRequestDelegate *delegate;
    if (asVoiceClip) {
        delegate = [[MEGAChatAttachVoiceClipRequestDelegate alloc] initWithCompletion:completion];
    } else {
        delegate = [[MEGAChatAttachNodeRequestDelegate alloc] initWithCompletion:completion];
    }
    
    for (NSNumber *chatIdNumber in self.chatIdNumbers) {
        uint64_t chatId = chatIdNumber.unsignedLongLongValue;
        if (asVoiceClip) {
            [MEGAChatSdk.shared attachVoiceMessageToChat:chatId node:handle delegate:delegate];
        } else {
            [MEGAChatSdk.shared attachNodeToChat:chatId node:handle delegate:delegate];
        }
    }
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    [self.sendToChatActivityDelegate sendToViewController:self didFinishActivity:NO];

    // SendToViewController is being shown by both with modal presentation and navigation push.
    // When we cancel we'll try to pop first, if the popping succeeds it means that `self` was pushed to a navigation
    // stack, otherwise we dismiss it.
    if (![self.navigationController popViewControllerAnimated:YES]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)sendAction:(UIBarButtonItem *)sender {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (self.sendMode) {
            case SendModeCloud: {
                self.pendingAttachNodeOperations = (self.nodes.count * self.selectedGroupChatsMutableArray.count) + (self.nodes.count * self.selectedUsersMutableArray.count);
                
                MEGAChatAttachNodeRequestDelegate *chatAttachNodeRequestDelegate = [[MEGAChatAttachNodeRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
                    if (--self.pendingAttachNodeOperations == 0) {
                        [self showSuccessMessage];
                    }
                }];
                
                for (MEGANode *node in self.nodes) {
                    for (MEGAChatListItem *chatListItem in self.selectedGroupChatsMutableArray) {
                        [Helper importNode:node toShareWithCompletion:^(MEGANode *node) {
                            [MEGAChatSdk.shared attachNodeToChat:chatListItem.chatId node:node.handle delegate:chatAttachNodeRequestDelegate];
                        }];
                    }
                    
                    for (MEGAUser *user in self.selectedUsersMutableArray) {
                        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomByUser:user.handle];
                        if (chatRoom) {
                            [Helper importNode:node toShareWithCompletion:^(MEGANode *node) {
                                [MEGAChatSdk.shared attachNodeToChat:chatRoom.chatId node:node.handle delegate:chatAttachNodeRequestDelegate];
                            }];
                        } else {
                            MEGALogDebug(@"There is not a chat with %@, create the chat and attach", user.email);
                            [MEGAChatSdk.shared mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                                [Helper importNode:node toShareWithCompletion:^(MEGANode *node) {
                                    [MEGAChatSdk.shared attachNodeToChat:chatRoom.chatId node:node.handle delegate:chatAttachNodeRequestDelegate];
                                }];
                            }];
                        }
                    }
                }
                
                [self.sendToChatActivityDelegate sendToViewController:self didFinishActivity:YES];

                [self dismissViewControllerAnimated:YES completion:nil];
                
                break;
            }
                
            case SendModeShareExtension:
            case SendModeFileAndFolderLink:
                [self.sendToViewControllerDelegate sendToViewController:self toChats:self.selectedGroupChatsMutableArray andUsers:self.selectedUsersMutableArray];
                break;
                
            case SendModeForward: {
                [self dismissViewControllerAnimated:YES completion:^{
                    NSUInteger destinationCount = self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count;
                    self.pendingForwardOperations = self.messages.count * destinationCount;
                    self.sentMessages = [[NSMutableArray<MEGAChatMessage *> alloc] initWithCapacity:self.messages.count];
                    self.chatIdNumbers = [[NSMutableArray<NSNumber *> alloc] init];
                    for (MEGAChatListItem *chatListItem in self.selectedGroupChatsMutableArray) {
                        @synchronized(self.chatIdNumbers) {
                            [self.chatIdNumbers addObject:@(chatListItem.chatId)];
                            if (self.chatIdNumbers.count == destinationCount) {
                                [self forwardMessages];
                            }
                        }
                    }
                    for (MEGAUser *user in self.selectedUsersMutableArray) {
                        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomByUser:user.handle];
                        if (chatRoom) {
                            @synchronized(self.chatIdNumbers) {
                                [self.chatIdNumbers addObject:@(chatRoom.chatId)];
                                if (self.chatIdNumbers.count == destinationCount) {
                                    [self forwardMessages];
                                }
                            }
                        } else {
                            MEGALogDebug(@"There is not a chat with %@, create the chat and attach", user.email);
                            [MEGAChatSdk.shared mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                                @synchronized(self.chatIdNumbers) {
                                    [self.chatIdNumbers addObject:@(chatRoom.chatId)];
                                    if (self.chatIdNumbers.count == destinationCount) {
                                        [self forwardMessages];
                                    }
                                }
                            }];
                        }
                    }
                }];
                
                break;
            }
                
            case SendModeText: {
                for (MEGAChatListItem *chatListItem in self.selectedGroupChatsMutableArray) {
                    [MEGAChatSdk.shared sendMessageToChat:chatListItem.chatId message:[self.sendToChatActivityDelegate textToSend]];
                }
                
                for (MEGAUser *user in self.selectedUsersMutableArray) {
                    MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomByUser:user.handle];
                    if (chatRoom) {
                        [MEGAChatSdk.shared sendMessageToChat:chatRoom.chatId message:[self.sendToChatActivityDelegate textToSend]];
                    } else {
                        [MEGAChatSdk.shared mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                            [MEGAChatSdk.shared sendMessageToChat:chatRoom.chatId message:[self.sendToChatActivityDelegate textToSend]];
                        }];
                    }
                }
                
                [self showSuccessMessage];
                [self.sendToChatActivityDelegate sendToViewController:self didFinishActivity:YES];

                break;
            }
        }
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
            
            NSPredicate *fullnamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            NSPredicate *nicknamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_nickname contains[c] %@", searchString];
            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF.email contains[c] %@", searchString];
            NSPredicate *usersPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[fullnamePredicate, nicknamePredicate, emailPredicate]];
            
            self.searchedUsersMutableArray = [[self.visibleUsersMutableArray filteredArrayUsingPredicate:usersPredicate] mutableCopy];
            
            [self updateMainSearchArray];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id itemAtIndex = [self itemAtIndexPath:indexPath];
    
    if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
        MEGAChatListItem *chatListItem = itemAtIndex;
        ChatRoomCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
        
        cell.onlineStatusView.hidden = YES;

        [cell configureAvatar:chatListItem];
        
        cell.chatTitle.text = chatListItem.chatTitle;
        
        if (chatListItem.isNoteToSelf) {
            cell.chatLastMessage.hidden = YES;
        } else {
            MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatListItem.chatId];
            cell.chatLastMessage.text = [chatRoom participantsNamesWithMe:YES];
        }
        cell.chatLastTime.hidden = YES;
        
        for (MEGAChatListItem *tempChatListItem in self.selectedGroupChatsMutableArray) {
            if (tempChatListItem.chatId == chatListItem.chatId) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        cell.privateChatImageView.hidden = chatListItem.publicChat || chatListItem.isNoteToSelf;
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
        
        return cell;
    }
    
    if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
        MEGAUser *user = itemAtIndex;
        ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
        
        UIColor *color = [UIColor colorWithChatStatus: [MEGAChatSdk.shared userOnlineStatus:user.handle]];
        
        if (color) {
            cell.onlineStatusView.backgroundColor = color;
            cell.onlineStatusView.hidden = NO;
        } else {
            cell.onlineStatusView.hidden = YES;
        }
        
        cell.nameLabel.text = user.mnz_displayName;
        cell.shareLabel.text = user.email;
        
        [cell.avatarImageView mnz_setImageForUserHandle:user.handle];
        
        cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
        
        for (MEGAUser *tempUser in self.selectedUsersMutableArray) {
            if ([tempUser.email isEqualToString:user.email]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
        
        return cell;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.searchController.isActive ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0:
            numberOfRows = self.searchController.isActive ? self.searchedUsersAndGroupChatsMutableArray.count : self.recentsMutableArray.count;
            break;
            
        case 1:
            numberOfRows = self.usersAndGroupChatsMutableArray.count;
            break;
            
        default:
            break;
    }
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
    self.searchController.searchBar.userInteractionEnabled = self.searchController.isActive ? YES : (numberOfRows > 0);
    
    return numberOfRows;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.usersAndGroupChatsMutableArray.count == 0) {
        return nil;
    }
    if (self.searchController.isActive && self.searchedUsersAndGroupChatsMutableArray.count == 0) {
        return nil;
    }
    if (!self.searchController.isActive && section == 0 && self.recentsMutableArray.count == 0) {
        return nil;
    }
    
    GenericHeaderFooterView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    headerView.titleLabel.font = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleFootnote weight:UIFontWeightMedium];
    switch (section) {
        case 0: {
            [headerView configureWithTitle:self.searchController.isActive ? LocalizedString(@"My chats", @"Column header of my contacts/chats at copy dialog") : LocalizedString(@"Recents", @"Title for the recents section") topDistance:17.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:YES];
            
            return headerView;
        }
            
        case 1: {
            [headerView configureWithTitle:LocalizedString(@"My chats", @"Column header of my contacts/chats at copy dialog") topDistance:10.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:YES];
            return headerView;
        }
            
        default:
            return nil;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id itemAtIndex = [self itemAtIndexPath:indexPath];
    if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
        MEGAChatListItem *chatListItem = itemAtIndex;
        [self.selectedGroupChatsMutableArray addObject:chatListItem];
        if (indexPath.section == 0) {
            [self syncSelectionStateFor:1 dataSourceArray:[self.usersAndGroupChatsMutableArray copy] item:chatListItem isSelected:YES];
        } else {
            [self syncSelectionStateFor:0 dataSourceArray:[self.recentsMutableArray copy] item:chatListItem isSelected:YES];
        }
        [self addItemToList:[[ItemListModel alloc] initWithChat:chatListItem]];
    } else if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
        MEGAUser *user = itemAtIndex;
        [self.selectedUsersMutableArray addObject:user];
        [self addItemToList:[[ItemListModel alloc] initWithUser:user]];
    }
    
    if (self.searchController.searchBar.isFirstResponder) {
        self.searchController.searchBar.text = @"";
    }
    
    [self updateNavigationBarTitle];
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    id itemAtIndex = [self itemAtIndexPath:indexPath];
    if ([itemAtIndex isKindOfClass:MEGAChatListItem.class]) {
        MEGAChatListItem *chatListItem = itemAtIndex;
        NSMutableArray *tempSelectedGroupChatsMutableArray = self.selectedGroupChatsMutableArray.copy;
        for (MEGAChatListItem *tempChatListItem in tempSelectedGroupChatsMutableArray) {
            if (tempChatListItem.chatId == chatListItem.chatId) {
                [self.selectedGroupChatsMutableArray removeObject:tempChatListItem];
            }
        }
        if (indexPath.section == 0) {
            [self syncSelectionStateFor:1 dataSourceArray:[self.usersAndGroupChatsMutableArray copy] item:chatListItem isSelected:NO];
        } else {
            [self syncSelectionStateFor:0 dataSourceArray:[self.recentsMutableArray copy] item:chatListItem isSelected:NO];
        }
        if (self.itemListVC) {
            [self.itemListVC removeItem:[[ItemListModel alloc] initWithChat:chatListItem]];
        }
    } else if ([itemAtIndex isKindOfClass:MEGAUser.class]) {
        MEGAUser *user = itemAtIndex;
        NSMutableArray *tempSelectedUsersMutableArray = self.selectedUsersMutableArray.copy;
        for (MEGAUser *tempUser in tempSelectedUsersMutableArray) {
            if ([tempUser.email isEqualToString:user.email]) {
                [self.selectedUsersMutableArray removeObject:tempUser];
            }
        }
        if (self.itemListVC) {
            [self.itemListVC removeItem:[[ItemListModel alloc] initWithUser:user]];
        }
    }
    
    if (self.searchController.searchBar.isFirstResponder) {
        self.searchController.searchBar.text = @"";
    }
    
    if ((self.selectedUsersMutableArray.count + self.selectedGroupChatsMutableArray.count) == 0 && self.itemListVC) {
        [self removeUsersListSubview];
    }
    
    [self updateNavigationBarTitle];
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:nil buttonTitle:nil];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length) {
            text = LocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        text = LocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image = nil;
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length) {
            image = [UIImage megaImageWithNamed:@"searchEmptyState"];
        }
    } else {
        image = [UIImage megaImageWithNamed:@"contactsEmptyState"];
    }
    
    return image;
}

#pragma mark - ItemListViewControllerDelegate

- (void)removeSelectedItem:(id)item {
    if ([[item class] isEqual:MEGAUser.class]) {
        [self.selectedUsersMutableArray removeObject:item];
    } else {
        [self.selectedGroupChatsMutableArray removeObject:item];
    }
    
    NSUInteger indexOfObject;
    if (self.searchController.isActive) {
        indexOfObject = [self.searchedUsersAndGroupChatsMutableArray indexOfObject:item];
        if (indexOfObject != NSNotFound) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfObject inSection:0] animated:YES];
        }
    } else {
        [self syncSelectionStateFor:0 dataSourceArray:[self.recentsMutableArray copy] item:item isSelected:NO];
        [self syncSelectionStateFor:1 dataSourceArray:[self.usersAndGroupChatsMutableArray copy] item:item isSelected:NO];
    }
    
    if ((self.selectedUsersMutableArray.count + self.selectedGroupChatsMutableArray.count) == 0 && self.itemListVC) {
        [self removeUsersListSubview];
    }
    
    [self updateNavigationBarTitle];
    
    self.sendBarButtonItem.enabled = ((self.selectedGroupChatsMutableArray.count + self.selectedUsersMutableArray.count) > 0);
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    return self.selectedUsersMutableArray.count == 0 && self.selectedGroupChatsMutableArray.count == 0;
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    if (self.cancelBarButtonItem == nil) {
        return;
    }
    
    UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:self.cancelBarButtonItem withConfirmAction:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:confirmDismissAlert animated:YES completion:nil];
}

@end
