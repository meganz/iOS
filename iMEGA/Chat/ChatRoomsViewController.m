#import "ChatRoomsViewController.h"

#import "MEGASdkManager.h"
#import "ChatRoomCell.h"
#import "MessagesViewController.h"
#import "ContactsViewController.h"
#import "MEGANavigationController.h"
#import "ContactDetailsViewController.h"

#import "DateTools.h"
#import "UIImage+GKContact.h"
#import "UIImageView+MNZCategory.h"

@interface ChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, MEGAChatRequestDelegate, MEGAChatDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) MEGAChatListItemList *chatListItemList;
@property (nonatomic, strong) NSMutableDictionary *chatListItemIndexPathDictionary;

@end

@implementation ChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = AMLocalizedString(@"Chat", nil);
    self.chatListItemIndexPathDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    
    self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] chatListItems];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

#pragma mark - IBActions

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Start conversation", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
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
                    for (i = 0; i < self.chatListItemList.size; i++){
                        if (chatRoom.chatId == [[self.chatListItemList chatListItemAtIndex:i] chatId]) {
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
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatListItemList.size;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    
    MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:indexPath.row];
    [self.chatListItemIndexPathDictionary setObject:indexPath forKey:@(chatListItem.chatId)];
    MEGALogInfo(@"%@", chatListItem);
    
    cell.chatTitle.text = chatListItem.title;
    cell.chatLastMessage.text = chatListItem.lastMessage.content;
    cell.chatLastTime.text = chatListItem.lastMessage.timestamp.shortTimeAgoSinceNow;
    if (chatListItem.isGroup) {
        cell.onlineStatusView.hidden = YES;
        UIImage *avatar = [UIImage imageForName:chatListItem.title.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont fontWithName:@"SFUIText-Light" size:(cell.avatarImageView.frame.size.width/2)]];
        
        cell.avatarImageView.image = avatar;
    } else {
        [cell.avatarImageView mnz_setImageForUser:[[MEGASdkManager sharedMEGASdk] contactForEmail:[MEGASdk base64HandleForUserHandle:chatListItem.peerHandle]]];
        if (chatListItem.onlineStatus == 0) {
            cell.onlineStatusView.backgroundColor = [UIColor mnz_gray666666];
        } else if (chatListItem.onlineStatus == 3) {
            cell.onlineStatusView.backgroundColor = [UIColor mnz_green13E03C];
        }
        cell.onlineStatusView.hidden             = NO;
        cell.onlineStatusView.layer.cornerRadius = cell.onlineStatusView.frame.size.width / 2;
    }
    
    if (chatListItem.unreadCount != 0) {
        cell.unreadCount.hidden             = NO;
        cell.unreadCount.layer.cornerRadius = 6.0f;
        cell.unreadCount.clipsToBounds      = YES;
        cell.unreadCount.text               = [NSString stringWithFormat:@"%ld", (long)chatListItem.unreadCount];
    } else {
        cell.unreadCount.hidden = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:indexPath.row];
    [self.chatListItemIndexPathDictionary removeObjectForKey:@(chatListItem.chatId)];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:indexPath.row];
    MEGAChatRoom *chatRoom         = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
    
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom                = chatRoom;
    
    [self.navigationController pushViewController:messagesVC animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatListItem *chatListItem = [self.chatListItemList chatListItemAtIndex:indexPath.row];
    
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:AMLocalizedString(@"More", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.tableView setEditing:NO];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Mute", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Info", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (chatListItem.isGroup) {
                //TODO: details of a group
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            } else {
                MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatListItem.chatId];
                NSString *peerEmail     = [[MEGASdkManager sharedMEGAChatSdk] userEmailByUserHandle:[chatRoom peerHandleAtIndex:0]];
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
        
        [self presentViewController:alertController animated:YES completion:nil];
    }];
    moreAction.backgroundColor = [UIColor mnz_grayCCCCCC];
    
    UITableViewRowAction *deleteAction = nil;
    
    if (chatListItem.isGroup) {
        deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"Leave", nil)  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"Are you sure you want to leave this group chat?", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.tableView setEditing:NO];
            }]];
            
            [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] leaveChat:chatListItem.chatId delegate:self];
                [self.tableView setEditing:NO];
            }]];
            
            [self presentViewController:leaveAlertController animated:YES completion:nil];
        }];
    } else {
        deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:AMLocalizedString(@"Close", nil)  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
             [self presentViewController:alertController animated:YES completion:nil];
        }];
    }
    deleteAction.backgroundColor = [UIColor mnz_redFF333A];
    
    return @[deleteAction, moreAction];
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
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
//            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:request.chatHandle];
//            NSIndexPath *indexPath = [self.chatListItemIndexPathDictionary objectForKey:@(chatRoom.chatId)];
//            [self.tableView beginUpdates];
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//            [self.tableView endUpdates];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    MEGALogInfo(@"onChatRoomUpdate %@", chat);
    self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] chatListItems];
    [self.tableView reloadData];
}

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    MEGALogInfo(@"onChatListItemUpdate %@", item);
    self.chatListItemList = [[MEGASdkManager sharedMEGAChatSdk] chatListItems];
    if ([self.chatListItemIndexPathDictionary objectForKey:@(item.chatId)]) {
        NSIndexPath *indexPath = [self.chatListItemIndexPathDictionary objectForKey:@(item.chatId)];
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
                if (cell.unreadCount.hidden) {
                    cell.unreadCount.hidden             = NO;
                    cell.unreadCount.layer.cornerRadius = 6.0f;
                    cell.unreadCount.clipsToBounds      = YES;
                }
                cell.unreadCount.text = [NSString stringWithFormat:@"%ld", (long)item.unreadCount];
                break;
                
            case MEGAChatListItemChangeTypeParticipants:
                break;
                
            case MEGAChatListItemChangeTypeTitle:
                cell.chatTitle.text = item.title;
                break;
                
            case MEGAChatListItemChangeTypeClosed:
//TODO: Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid update: invalid number of rows in section 0.  The number of rows contained in an existing section after the update (15) must be equal to the number of rows contained in that section before the update (15), plus or minus the number of rows inserted or deleted from that section (0 inserted, 1 deleted) and plus or minus the number of rows moved into or out of that section (0 moved in, 0 moved out).'
//                [self.tableView beginUpdates];
//                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//                [self.chatListItemIndexPathDictionary removeObjectForKey:indexPath];
//                [self.tableView endUpdates];
                break;
                
            case MEGAChatListItemChangeTypeLastMsg:
                cell.chatLastMessage.text = item.lastMessage.content;
                cell.chatLastTime.text    = item.lastMessage.timestamp.shortTimeAgoSinceNow;
                break;
                
            default:
                break;
        }
    }
}

@end
