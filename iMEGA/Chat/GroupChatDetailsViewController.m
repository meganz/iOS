#import "GroupChatDetailsViewController.h"
#import "ChatRoomsViewController.h"

#import "UIImage+GKContact.h"

#import "UIImageView+MNZCategory.h"
#import "MEGAReachabilityManager.h"

#import "GroupChatDetailsViewTableViewCell.h"
#import "ContactTableViewCell.h"

@interface GroupChatDetailsViewController () <MEGAChatRequestDelegate, MEGAChatRoomDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *participantsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *participantsHeaderViewLabel;

@property (strong, nonatomic) NSMutableArray *participantsMutableArray;

@property (nonatomic, assign) BOOL openChatRoom;

@end

@implementation GroupChatDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"groupInfo", @"Title of section where you can see the chat group information and the options that you can do with it. Like 'Notifications' or 'Leave Group' and also the participants of the group");
    
    self.nameLabel.text = self.chatRoom.title;
    
    CGSize avatarSize = self.avatarImageView.frame.size;
    UIImage *avatarImage = [UIImage imageForName:self.chatRoom.title.uppercaseString size:avatarSize backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(avatarSize.width/2.0f)]];
    self.avatarImageView.image = avatarImage;
    self.emailLabel.text = AMLocalizedString(@"groupChat", @"Label title for a group chat");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2] class] != [ChatRoomsViewController class]) {
        [[MEGASdkManager sharedMEGAChatSdk] addChatRoomDelegate:self.chatRoom.chatId delegate:self];
        self.openChatRoom = NO;
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] openChatRoom:self.chatRoom.chatId delegate:self];
        self.openChatRoom = YES;
    }
    
    [self setParticipants];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.openChatRoom) {
        [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:self.chatRoom.chatId delegate:self];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] removeChatRoomDelegate:self];
    }
}

- (BOOL)hidesBottomBarWhenPushed {
    return YES;
}

#pragma mark - Private

- (void)setParticipants {
    self.participantsMutableArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < self.chatRoom.peerCount; i++) {
        uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:i];
        if ([self.chatRoom peerPrivilegeByHandle:peerHandle] > MEGAChatRoomPrivilegeRm) {
            [self.participantsMutableArray addObject:[NSNumber numberWithUnsignedLongLong:peerHandle]];
        }
    }
    
    uint64_t myHandle = [[MEGASdkManager sharedMEGAChatSdk] myUserHandle];
    [self.participantsMutableArray addObject:[NSNumber numberWithUnsignedLongLong:myHandle]];
}

- (void)alertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UITextField *textField = alertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        BOOL enableRightButton = NO;
        if ((textField.text.length > 0) && ![textField.text isEqualToString:self.chatRoom.title] && ![[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] && ([textField.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 31)) {
            enableRightButton = YES;
        }
        rightButtonAction.enabled = enableRightButton;
    }
}

- (void)showClearChatHistoryAlert {
    UIAlertController *clearChatHistoryAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.") message:AMLocalizedString(@"clearTheFullMessageHistory", @"A confirmation message for a user to confirm that they want to clear the history of a chat.") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"continue", @"'Next' button in a dialog") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[MEGASdkManager sharedMEGAChatSdk] clearChatHistory:self.chatRoom.chatId delegate:self];
    }];
    
    [clearChatHistoryAlertController addAction:cancelAction];
    [clearChatHistoryAlertController addAction:continueAction];
    
    [self presentViewController:clearChatHistoryAlertController animated:YES completion:nil];
}

- (void)showLeaveChatAlertAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"youWillNoLongerHaveAccessToThisConversation", @"Alert text that explains what means confirming the action 'Leave'") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[MEGASdkManager sharedMEGAChatSdk] leaveChat:self.chatRoom.chatId];
    }]];
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        leaveAlertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = [leaveAlertController popoverPresentationController];
        CGRect deleteRect = [self.tableView rectForRowAtIndexPath:indexPath];
        popoverPresentationController.sourceRect = deleteRect;
        popoverPresentationController.sourceView = self.tableView;
    }
    [self presentViewController:leaveAlertController animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)notificationsSwitchValueChanged:(UISwitch *)sender {
    //TODO: Enable/disable notifications
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TO-DO" message:@"🔜🤓💻📱" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    
    switch (self.chatRoom.ownPrivilege) {
        case MEGAChatRoomPrivilegeUnknown:
        case MEGAChatRoomPrivilegeRm:
        case MEGAChatRoomPrivilegeRo:
        case MEGAChatRoomPrivilegeStandard:
        case MEGAChatRoomPrivilegeModerator:
            numberOfSections = 2;
            break;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (section == 0) {
        switch (self.chatRoom.ownPrivilege) {
            case MEGAChatRoomPrivilegeUnknown:
            case MEGAChatRoomPrivilegeRm:
            case MEGAChatRoomPrivilegeRo:
            case MEGAChatRoomPrivilegeStandard:
                numberOfRows = 2;
                break;
                
            case MEGAChatRoomPrivilegeModerator:
                numberOfRows = 5;
                break;
        }
    } else if (section == 1) {
        numberOfRows = self.participantsMutableArray.count;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupChatDetailsViewTableViewCell *cell;
    if (indexPath.section == 0) {
        switch (self.chatRoom.ownPrivilege) {
            case MEGAChatRoomPrivilegeUnknown:
            case MEGAChatRoomPrivilegeRm:
            case MEGAChatRoomPrivilegeRo:
            case MEGAChatRoomPrivilegeStandard: {
                if (indexPath.row == 0) {
                    cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsNotificationsTypeID" forIndexPath:indexPath];
                    cell.nameLabel.text = AMLocalizedString(@"notifications", nil);
                } else if (indexPath.row == 1) {
                    cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsLeaveGroupTypeID" forIndexPath:indexPath];
                    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]};
                    cell.nameLabel.attributedText = [[NSAttributedString alloc] initWithString:AMLocalizedString(@"leaveGroup", @"") attributes:attributes];
                }
                break;
            }
                
            case MEGAChatRoomPrivilegeModerator: {
                switch (indexPath.row) {
                    case 0: {
                        cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsNotificationsTypeID" forIndexPath:indexPath];
                        cell.nameLabel.text = AMLocalizedString(@"notifications", nil);
                        break;
                    }
                        
                    case 1:
                    case 2: {
                        cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsLeaveGroupTypeID" forIndexPath:indexPath];
                        NSString *text;
                        if (indexPath.row == 1) {
                            text = AMLocalizedString(@"renameGroup", @"The title of a menu button which allows users to rename a group chat.");
                        } else if (indexPath.row == 2) {
                            text = AMLocalizedString(@"changeGroupAvatar", @"Title of the action that allows you to change the avatar of a group chat.");
                        }
                        cell.nameLabel.text = text;
                        break;
                    }
                        
                    case 3:
                    case 4: {
                        cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsLeaveGroupTypeID" forIndexPath:indexPath];
                        NSString *text;
                        if (indexPath.row == 3) {
                            text = AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.");
                        } else if (indexPath.row == 4) {
                            text = AMLocalizedString(@"leaveGroup", @"Button title that allows the user to leave a group chat.");
                        }
                        NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]};
                        cell.nameLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
                        break;
                    }
                }
                break;
            }
        }
    } else if (indexPath.section == 1) {
        uint64_t handle = [[self.participantsMutableArray objectAtIndex:indexPath.row] unsignedLongLongValue];
        NSString *peerFullname = [[NSString alloc] init];
        NSString *peerEmail = [[NSString alloc] init];
        MEGAChatRoomPrivilege privilege;
        if (handle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
            NSString *myFullname = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
            peerFullname = [NSString stringWithFormat:@"%@ (%@)", myFullname, AMLocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.")];
            peerEmail = [[MEGASdkManager sharedMEGAChatSdk] myEmail];
            privilege = self.chatRoom.ownPrivilege;
        } else {
            peerFullname = [self.chatRoom peerFullnameByHandle:handle];
            peerEmail = [self.chatRoom peerEmailByHandle:handle];
            privilege = [self.chatRoom peerPrivilegeAtIndex:indexPath.row];
        }
        BOOL isNameEmpty = [[peerFullname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
        if (isNameEmpty) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantEmailTypeID" forIndexPath:indexPath];
        } else {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantTypeID" forIndexPath:indexPath];
            cell.nameLabel.text = peerFullname;
        }
        
        [cell.leftImageView mnz_setImageForUserHandle:handle];
        cell.onlineStatusView.layer.cornerRadius = (cell.onlineStatusView.frame.size.width / 2);
        cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:handle]];
        
        cell.emailLabel.text = peerEmail;
        
        UIImage *permissionsImage = nil;
        switch (privilege) {
            case MEGAChatRoomPrivilegeUnknown:                
                break;
                
            case MEGAChatRoomPrivilegeRm:
                permissionsImage = [UIImage imageNamed:@"cancelIcon"];
                break;
                
            case MEGAChatRoomPrivilegeRo:
                permissionsImage = [UIImage imageNamed:@"readPermissions"];
                break;
                
            case MEGAChatRoomPrivilegeStandard:
                permissionsImage = [UIImage imageNamed:@"readWritePermissions"];
                break;
                
            case MEGAChatRoomPrivilegeModerator:
                permissionsImage = [UIImage imageNamed:@"permissions"];
                break;
        }
        cell.rightImageView.image = permissionsImage;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        self.participantsHeaderViewLabel.text = [AMLocalizedString(@"participants", @"Label to describe the section where you can see the participants of a group chat") uppercaseString];
        return self.participantsHeaderView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat heightForHeader = 0.0f;
    if (section == 1) {
        heightForHeader = 23.0f;
    }
    
    return heightForHeader;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: //Notifications
                //TODO: Enable/disable notifications for this chat
                break;
                
            case 1: { //Rename Group
                
                switch (self.chatRoom.ownPrivilege) {
                    case MEGAChatRoomPrivilegeUnknown:
                    case MEGAChatRoomPrivilegeRm:
                    case MEGAChatRoomPrivilegeRo:
                    case MEGAChatRoomPrivilegeStandard: {
                        [self showLeaveChatAlertAtIndexPath:indexPath];
                        break;
                    }
                        
                    case MEGAChatRoomPrivilegeModerator: {
                        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                            UIAlertController *renameGroupAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"renameGroup", @"The title of a menu button which allows users to rename a group chat.") message:AMLocalizedString(@"renameNodeMessage", @"Hint text to suggest that the user have to write the new name for the file or folder") preferredStyle:UIAlertControllerStyleAlert];
                            
                            [renameGroupAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                textField.text = self.chatRoom.title;
                                [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                            }];
                            
                            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                                [self dismissViewControllerAnimated:YES completion:nil];
                            }];
                            
                            UIAlertAction *renameAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                UITextField *textField = [[renameGroupAlertController textFields] firstObject];
                                NSString *newGroupName = textField.text;
                                [[MEGASdkManager sharedMEGAChatSdk] setChatTitle:self.chatRoom.chatId title:newGroupName delegate:self];
                            }];
                            
                            [renameGroupAlertController addAction:cancelAction];
                            [renameGroupAlertController addAction:renameAction];
                            
                            renameAction.enabled = NO;
                            
                            [self presentViewController:renameGroupAlertController animated:YES completion:nil];
                        }
                        break;
                    }
                }
                break;
            }
                
            case 2: { //Change Group Avatar
                //TODO: Change Group Avatar
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TO-DO" message:@"🔜🤓💻📱" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
        
            case 3: //Clear Chat History
                [self showClearChatHistoryAlert];
                break;
                
            case 4: //Leave chat
                [self showLeaveChatAlertAtIndexPath:indexPath];
                break;
        }
    } else if (indexPath.section == 1) {
        if (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator && (indexPath.row != (self.participantsMutableArray.count - 1))) {
            uint64_t userHandle = [[self.participantsMutableArray objectAtIndex:indexPath.row] unsignedLongLongValue];
            
            UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [cancelAlertAction setValue:[UIColor mnz_redD90007] forKey:@"titleTextColor"];
            [permissionsAlertController addAction:cancelAlertAction];
            
            UIAlertAction *moderatorAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] updateChatPermissions:self.chatRoom.chatId userHandle:userHandle privilege:MEGAChatRoomPrivilegeModerator delegate:self];
            }];
            [moderatorAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
            [permissionsAlertController addAction:moderatorAlertAction];
            
            UIAlertAction *standartAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] updateChatPermissions:self.chatRoom.chatId userHandle:userHandle privilege:MEGAChatRoomPrivilegeStandard delegate:self];
            }];
            [standartAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
            [permissionsAlertController addAction:standartAlertAction];
            
            UIAlertAction *readOnlyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] updateChatPermissions:self.chatRoom.chatId userHandle:userHandle privilege:MEGAChatRoomPrivilegeRo delegate:self];
            }];
            [readOnlyAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
            [permissionsAlertController addAction:readOnlyAlertAction];
            
            UIAlertAction *removeParticipantAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"removeParticipant", @"A button title which removes a participant from a chat.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGAChatSdk] removeFromChat:self.chatRoom.chatId userHandle:userHandle delegate:self];
            }];
            [permissionsAlertController addAction:removeParticipantAlertAction];
            
            if ([[UIDevice currentDevice] iPadDevice]) {
                permissionsAlertController.modalPresentationStyle = UIModalPresentationPopover;
                UIPopoverPresentationController *popoverPresentationController = [permissionsAlertController popoverPresentationController];
                GroupChatDetailsViewTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                popoverPresentationController.sourceRect = cell.contentView.frame;
                popoverPresentationController.sourceView = cell.contentView;
            }
            [self presentViewController:permissionsAlertController animated:YES completion:nil];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    switch (request.type) {            
        case MEGAChatRequestTypeUpdatePeerPermissions: {
            if (error.type) {
                //TODO: Manage errors of update peer permissions request 
                return;
            }
            break;
        }
            
        default:
            break;
    }
}



- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    MEGALogInfo(@"onChatRoomUpdate %@", chat);
    self.chatRoom = chat;
    switch (chat.changes) {
        case MEGAChatRoomChangeTypeStatus:
            break;
            
        case MEGAChatRoomChangeTypeUnreadCount:
            break;
            
        case MEGAChatRoomChangeTypeParticipans:
            // TODO: Test when the megachat-native (#6108) bug will be fixed
            [self setParticipants];
            [self.tableView reloadData];
            break;
            
        case MEGAChatRoomChangeTypeTitle:
            self.nameLabel.text = chat.title;
            break;
            
        case MEGAChatRoomChangeTypeUserTyping:
            break;
            
        case MEGAChatRoomChangeTypeClosed:
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
            
        default:
            break;
    }
}

@end
