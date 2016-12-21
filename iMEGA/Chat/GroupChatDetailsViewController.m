#import "GroupChatDetailsViewController.h"

#import "UIImage+GKContact.h"

#import "UIImageView+MNZCategory.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGAParticipant.h"
#import "MEGAReachabilityManager.h"

#import "GroupChatDetailsViewTableViewCell.h"
#import "ContactTableViewCell.h"

@interface GroupChatDetailsViewController () <MEGAChatRequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *participantsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *participantsHeaderViewLabel;

@property (strong, nonatomic) NSMutableArray *participantsMutableArray;

@end

@implementation GroupChatDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"groupInfo", @"Title of section where you can see the chat group information and the options that you can do with it. Like 'Notifications' or 'Leave Group' and also the participants of the group");
    
    self.nameLabel.text = self.chatRoom.title;
    
    CGSize avatarSize = self.avatarImageView.frame.size;
    UIImage *avatarImage = [UIImage imageForName:self.chatRoom.title.uppercaseString size:avatarSize backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont fontWithName:@"SFUIText-Light" size:(avatarSize.width/2)]];
    self.avatarImageView.image = avatarImage;
    self.emailLabel.text = AMLocalizedString(@"groupChat", @"Label title for a group chat");
    
    [self setParticipants];
}

#pragma mark - Private

- (void)setParticipants {
    self.participantsMutableArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < self.chatRoom.peerCount; i++) {
        NSString *peerFirstname = [self.chatRoom peerFirstnameAtIndex:i];
        NSString *peerLastname = [self.chatRoom peerLastnameAtIndex:i];
        NSString *peerName = [NSString stringWithFormat:@"%@ %@", peerFirstname, peerLastname];
        uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:i];
        NSString *peerEmail = [[MEGASdkManager sharedMEGAChatSdk] userEmailByUserHandle:peerHandle];
        MEGAChatRoomPrivilege peerChatRoomPrivilege = [self.chatRoom peerPrivilegeAtIndex:i];
        
        MEGAParticipant *participant = [[MEGAParticipant alloc] initWithName:peerName email:peerEmail handle:peerHandle chatRoomPrivilege:peerChatRoomPrivilege];
        [self.participantsMutableArray addObject:participant];
    }
    
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    NSString *myName = myUser.mnz_fullName;
    NSString *myEmail = [[MEGASdkManager sharedMEGASdk] myEmail];
    uint64_t myHandle = myUser.handle;
    MEGAChatRoomPrivilege myChatRoomPrivilege = self.chatRoom.ownPrivilege;
    MEGAParticipant *participant = [[MEGAParticipant alloc] initWithName:myName email:myEmail handle:myHandle chatRoomPrivilege:myChatRoomPrivilege];
    [self.participantsMutableArray addObject:participant];
}

- (void)alertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UITextField *textField = alertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        BOOL enableRightButton = NO;
        if ((textField.text.length > 0) && ![textField.text isEqualToString:self.chatRoom.title] && ![[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] && (textField.text.length < 31)) {
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
        [[MEGASdkManager sharedMEGAChatSdk] clearChatHistory:self.chatRoom.chatId];
    }];
    
    [clearChatHistoryAlertController addAction:cancelAction];
    [clearChatHistoryAlertController addAction:continueAction];
    
    [self presentViewController:clearChatHistoryAlertController animated:YES completion:nil];
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
                    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:17.0], NSForegroundColorAttributeName:[UIColor mnz_redD90007]};
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
                        NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:17.0], NSForegroundColorAttributeName:[UIColor mnz_redD90007]};
                        cell.nameLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
                        break;
                    }
                }
                break;
            }
        }
    } else if (indexPath.section == 1) {
        MEGAParticipant *participant = [self.participantsMutableArray objectAtIndex:indexPath.row];
        BOOL isNameEmpty = [[participant.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
        if (isNameEmpty) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantEmailTypeID" forIndexPath:indexPath];
        } else {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantTypeID" forIndexPath:indexPath];
            cell.nameLabel.text = participant.name;
        }
        
        if ([participant.email isEqualToString:[[MEGASdkManager sharedMEGASdk] myEmail]]) {
            [cell.leftImageView mnz_setImageForUserHandle:[[MEGASdkManager sharedMEGASdk] myUser].handle];
        } else {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:participant.email];
            if (user) {
                [cell.leftImageView mnz_setImageForUserHandle:user.handle];
            } else {
                [cell.leftImageView mnz_setImageForParticipant:participant];
            }
        }
        
        cell.emailLabel.text = participant.email;
        
        UIImage *permissionsImage;
        switch (participant.chatRoomPrivilege) {
            case MEGAChatRoomPrivilegeUnknown:
                permissionsImage = [UIImage imageNamed:@"permissions"];
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
                permissionsImage = [UIImage imageNamed:@"fullAccessPermissions"];
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
                
            case 2: { //Change Group Avatar
                //TODO: Not available yet
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
        
            case 3: //Clear Chat History
                [self showClearChatHistoryAlert];
                break;
                
            case 4: //Leave chat
                [[MEGASdkManager sharedMEGAChatSdk] leaveChat:self.chatRoom.chatId delegate:self];
                break;
        }
    } else if (indexPath.section == 1) {
        //TODO: Push contact details / Manage chat permissions on the row button
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TODO" message:@"Not implemented yet" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    if (error.type) {
        return;
    }
    
    switch (request.type) {
        case MEGAChatRequestTypeRemoveFromChatRoom: {
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
            
        case MEGAChatRequestTypeEditChatRoomName: {
            NSString *newChatRoomName = request.text;
            self.title = newChatRoomName;
            self.nameLabel.text = newChatRoomName;
            break;
        }
            
        default:
            break;
    }
}

@end
