#import "ContactDetailsViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveContactRequestDelegate.h"
#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGAArchiveChatRequestDelegate.h"

#import "BrowserViewController.h"
#import "CloudDriveViewController.h"
#import "CustomActionViewController.h"
#import "ContactTableViewCell.h"
#import "CallViewController.h"
#import "GroupCallViewController.h"
#import "DevicePermissionsHelper.h"
#import "DisplayMode.h"
#import "GradientView.h"
#import "MessagesViewController.h"
#import "NodeInfoViewController.h"
#import "SharedItemsTableViewCell.h"
#import "VerifyCredentialsViewController.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGA-Swift.h"

typedef NS_ENUM(NSUInteger, ContactDetailsSection) {
    ContactDetailsSectionNicknameVerifyCredentials = 0,
    ContactDetailsSectionAddAndRemoveContact,
    ContactDetailsSectionSharedFolders,
    ContactDetailsSectionClearChatHistory,
    ContactDetailsSectionArchiveChat,
    ContactDetailsSectionAddParticipantToContact,
    ContactDetailsSectionRemoveParticipant,
    ContactDetailsSectionSetPermission
};

typedef NS_ENUM(NSUInteger, ContactDetailsRow) {
    ContactDetailsRowNickname = 0,
    ContactDetailsRowVerifyCredentials
};

@interface ContactDetailsViewController () <CustomActionViewControllerDelegate, MEGAChatDelegate, MEGAChatCallDelegate, MEGAGlobalDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameOrNicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionalNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet GradientView *gradientView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *videoCallButton;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *callLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *participantsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *participantsHeaderViewLabel;

@property (strong, nonatomic) MEGAUser *user;
@property (strong, nonatomic) MEGANodeList *incomingNodeListForUser;
@property (strong, nonatomic) MEGAChatRoom *chatRoom; // The chat room of the contact. Used for send a message or make a call

@property (strong, nonatomic) UIPanGestureRecognizer *panAvatar;
@property (assign, nonatomic) CGFloat avatarExpandedPosition;
@property (assign, nonatomic) CGFloat avatarCollapsedPosition;

@property (strong, nonatomic) NSString *userNickname;
@property (strong, nonatomic) NSArray<NSNumber *> *contactDetailsSections;
@property (strong, nonatomic, readonly) NSArray<NSNumber *> *rowsForNicknameAndVerify;

@end

@implementation ContactDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"";

    self.avatarExpandedPosition = self.view.frame.size.height * 0.5;
    self.avatarCollapsedPosition = self.view.frame.size.height * 0.3;
    self.avatarViewHeightConstraint.constant = self.avatarCollapsedPosition;
    
    self.user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.userEmail];
    [self.avatarImageView mnz_setImageAvatarOrColorForUserHandle:self.userHandle];
    self.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomByUser:self.userHandle];
    
    [self.backButton setImage:self.backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection forState:UIControlStateNormal];
    self.messageLabel.text = AMLocalizedString(@"Message", @"Label for any ‘Message’ button, link, text, title, etc. - (String as short as possible).").lowercaseString;
    self.callLabel.text = AMLocalizedString(@"Call", @"Title of the button in the contact info screen to start an audio call").lowercaseString;
    self.videoLabel.text = AMLocalizedString(@"Video", @"Title of the button in the contact info screen to start a video call").lowercaseString;
        
    self.userNickname = self.user.mnz_nickname;
    
    if (self.userName.length == 0) {
        self.userName = self.user.mnz_fullName;
    }
    
    [self configureShadowInLayer:self.nameOrNicknameLabel.layer];
    [self configureShadowInLayer:self.optionalNameLabel.layer];
    [self updateUserDetails];
    
    self.emailLabel.text = self.userEmail;
    [self configureShadowInLayer:self.emailLabel.layer];
    
    MEGAChatStatus userStatus = [MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:self.user.handle];
    if (userStatus != MEGAChatStatusInvalid) {
        if (userStatus < MEGAChatStatusOnline) {
            [MEGASdkManager.sharedMEGAChatSdk requestLastGreen:self.user.handle];
        }
        self.statusLabel.text = [NSString chatStatusString:userStatus];
        [self configureShadowInLayer:self.statusLabel.layer];
        
        self.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:self.user.handle]];
        [self configureShadowInLayer:self.onlineStatusView.layer];
        self.onlineStatusView.layer.borderWidth = 1;
        self.onlineStatusView.layer.borderColor = UIColor.whiteColor.CGColor;
    } else {
        self.statusLabel.hidden = YES;
        self.onlineStatusView.hidden = YES;
    }
    
    self.incomingNodeListForUser = [[MEGASdkManager sharedMEGASdk] inSharesForUser:self.user];
    
    if (@available(iOS 11.0, *)) {
        self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [self updateCallButtonsState];
    
    [self configureGestures];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
    
    // Creates a glitch in the animation when the view controller is presented.
    // So do not remove it if the view controller is presented
    if (self.presentedViewController == nil) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIDevice.currentDevice.iPhone4X || UIDevice.currentDevice.iPhone5X) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.avatarExpandedPosition = self.view.frame.size.height * 0.5;
        self.avatarCollapsedPosition = self.view.frame.size.height * 0.3;
        self.avatarViewHeightConstraint.constant = self.avatarCollapsedPosition;
        self.gradientView.alpha = 1.0f;
    } completion:nil];
}

#pragma mark - Private - Table view cells

- (ContactTableViewCell *)cellForNicknameWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = [UIImage imageNamed:@"setNickname"];
    
    cell.nameLabel.text = self.userNickname.length == 0 ?
    AMLocalizedString(@"Set Nickname", @"Contact details screen: Set the alias(nickname) for a user") :
    AMLocalizedString(@"Edit Nickname", @"Contact details screen: Edit the alias(nickname) for a user");
    
    cell.nameLabel.textColor = UIColor.mnz_black333333;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (ContactTableViewCell *)cellForVerifyCredentialsWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsPermissionsTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = [UIImage imageNamed:@"verifyCredentials"];
    cell.nameLabel.text = AMLocalizedString(@"verifyCredentials", @"Title for a section on the fingerprint warning dialog. Below it is a button which will allow the user to verify their contact's fingerprint credentials.");
    cell.nameLabel.textColor = UIColor.mnz_black333333;
    cell.permissionsLabel.text = [MEGASdkManager.sharedMEGASdk areCredentialsVerifiedOfUser:self.user] ? AMLocalizedString(@"verified", @"Button title") : @"";
    
    return cell;
}

- (ContactTableViewCell *)cellForAddAndRemoveContactWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
    if (self.user.visibility == MEGAUserVisibilityVisible) { //Remove Contact
        cell.avatarImageView.image = [UIImage imageNamed:@"delete"];
        cell.nameLabel.text = AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts");
        cell.nameLabel.textColor = UIColor.mnz_redMain;
    } else { //Add contact
        cell.avatarImageView.image = [UIImage imageNamed:@"add"];
        cell.avatarImageView.tintColor = UIColor.mnz_gray777777;
        cell.nameLabel.text = AMLocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email");
    }
    
    return cell;
}

- (ContactTableViewCell *)cellForSharedFoldersWithIndexPath:(NSIndexPath *)indexPath  {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsSharedFolderTypeID" forIndexPath:indexPath];
    MEGANode *node = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
    cell.avatarImageView.image = [Helper incomingFolderImage];
    cell.nameLabel.text = node.name;
    cell.shareLabel.text = [Helper filesAndFoldersInFolderNode:node api:MEGASdkManager.sharedMEGASdk];
    MEGAShareType shareType = [MEGASdkManager.sharedMEGASdk accessLevelForNode:node];
    cell.permissionsImageView.image = [Helper permissionsButtonImageForShareType:shareType];
    
    if (self.contactDetailsMode == ContactDetailsModeFromChat) {
        cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = MEGAReachabilityManager.isReachable;
    }
    
    return cell;
}

- (ContactTableViewCell *)cellForClearChatHistoryWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = [UIImage imageNamed:@"clearChatHistory"];
    cell.nameLabel.text = AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.");
    cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = self.user.visibility == MEGAUserVisibilityVisible && MEGAReachabilityManager.isReachable && [MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.chatRoom.chatId] == MEGAChatConnectionOnline;
    
    return cell;
}

- (ContactTableViewCell *)cellForArchiveChatWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = self.chatRoom.isArchived ? [UIImage imageNamed:@"unArchiveChat"] : [UIImage imageNamed:@"archiveChat_gray"];
    cell.nameLabel.text = self.chatRoom.isArchived ? AMLocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") : AMLocalizedString(@"archiveChat", @"Title of button to archive chats.");
    cell.nameLabel.textColor = self.chatRoom.isArchived ? UIColor.mnz_redMain : UIColor.mnz_black333333;
    cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = MEGAReachabilityManager.isReachable && [MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.chatRoom.chatId] == MEGAChatConnectionOnline;
    
    return cell;
}

- (ContactTableViewCell *)cellForAddParticipantAsContactWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = [UIImage imageNamed:@"add"];
    cell.avatarImageView.tintColor = UIColor.mnz_gray777777;
    cell.nameLabel.text = AMLocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email");
    cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = MEGAReachabilityManager.isReachable;
    
    return cell;
}

- (ContactTableViewCell *)cellForSetPermissionWithIndexPath:(NSIndexPath *)indexPath  {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsPermissionsTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = [UIImage imageNamed:@"readWritePermissions"];
    cell.nameLabel.text = AMLocalizedString(@"permissions", @"Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder");
    MEGAChatRoomPrivilege privilege = [self.groupChatRoom peerPrivilegeByHandle:self.userHandle];
    switch (privilege) {
        case MEGAChatRoomPrivilegeUnknown:
        case MEGAChatRoomPrivilegeRm:
            break;
            
        case MEGAChatRoomPrivilegeRo:
            cell.permissionsLabel.text = AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
            break;
            
        case MEGAChatRoomPrivilegeStandard:
            cell.permissionsLabel.text = AMLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.");
            break;
            
        case MEGAChatRoomPrivilegeModerator:
            cell.permissionsLabel.text = AMLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat.");
            break;
    }
    
    cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = MEGAReachabilityManager.isReachable && [MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.groupChatRoom.chatId] == MEGAChatConnectionOnline;
    
    return cell;
}

- (ContactTableViewCell *)cellForRemoveParticipantWithIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
    cell.avatarImageView.image = [UIImage imageNamed:@"delete"];
    cell.nameLabel.text = AMLocalizedString(@"removeParticipant", @"A button title which removes a participant from a chat.");
    cell.nameLabel.textColor = UIColor.mnz_redMain;
    cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = MEGAReachabilityManager.isReachable && [MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.groupChatRoom.chatId] == MEGAChatConnectionOnline;
    
    return cell;
}

#pragma mark - Private - Others

- (void)showClearChatHistoryAlert {
    UIAlertController *clearChatHistoryAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.") message:AMLocalizedString(@"clearTheFullMessageHistory", @"A confirmation message for a user to confirm that they want to clear the history of a chat.") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"continue", @"'Next' button in a dialog") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [MEGASdkManager.sharedMEGAChatSdk clearChatHistory:self.chatRoom.chatId];
    }];
    
    [clearChatHistoryAlertController addAction:cancelAction];
    [clearChatHistoryAlertController addAction:continueAction];
    
    [self presentViewController:clearChatHistoryAlertController animated:YES completion:nil];
}

- (void)showArchiveChatAlertAtIndexPath {
    NSString *title = self.chatRoom.isArchived ? AMLocalizedString(@"unarchiveChatMessage", @"Confirmation message for user to confirm it will unarchive an archived chat.") : AMLocalizedString(@"archiveChatMessage", @"Confirmation message on archive chat dialog for user to confirm.");
    UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MEGAArchiveChatRequestDelegate *archiveChatRequesDelegate = [[MEGAArchiveChatRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
            if (chatRoom.isArchived) {
                [self.navigationController setNavigationBarHidden:NO animated:NO];
                if (self.navigationController.childViewControllers.count >= 3) {
                    NSUInteger MessagesVCIndex = self.navigationController.childViewControllers.count - 2;
                    [MEGASdkManager.sharedMEGAChatSdk closeChatRoom:chatRoom.chatId delegate:self.navigationController.childViewControllers[MessagesVCIndex]];
                }
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else {
                self.chatRoom = chatRoom;
                [self.tableView reloadData];
            }
        }];
        [MEGASdkManager.sharedMEGAChatSdk archiveChat:self.chatRoom.chatId archive:!self.chatRoom.isArchived delegate:archiveChatRequesDelegate];
    }]];
    
    [self presentViewController:leaveAlertController animated:YES completion:nil];
}

- (void)showPermissionAlertWithSourceView:(UIView *)sourceView {
    MEGAChatGenericRequestDelegate *delegate = [MEGAChatGenericRequestDelegate.alloc initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
        if (error.type) {
            [SVProgressHUD showErrorWithStatus:error.name];
        } else {
            self.groupChatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:request.chatHandle];
            [self.tableView reloadData];
        }
    }];
    
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil];
    [cancelAlertAction mnz_setTitleTextColor:UIColor.mnz_redMain];
    [permissionsAlertController addAction:cancelAlertAction];
    
    UIAlertAction *moderatorAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdkManager.sharedMEGAChatSdk updateChatPermissions:self.groupChatRoom.chatId userHandle:self.userHandle privilege:MEGAChatRoomPrivilegeModerator delegate:delegate];
    }];
    [moderatorAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [permissionsAlertController addAction:moderatorAlertAction];
    
    UIAlertAction *standartAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdkManager.sharedMEGAChatSdk updateChatPermissions:self.groupChatRoom.chatId userHandle:self.userHandle privilege:MEGAChatRoomPrivilegeStandard delegate:delegate];
    }];
    [standartAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [permissionsAlertController addAction:standartAlertAction];
    
    UIAlertAction *readOnlyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdkManager.sharedMEGAChatSdk updateChatPermissions:self.groupChatRoom.chatId userHandle:self.userHandle privilege:MEGAChatRoomPrivilegeRo delegate:delegate];
    }];
    [readOnlyAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [permissionsAlertController addAction:readOnlyAlertAction];
    
    if (permissionsAlertController.actions.count > 1) {
        if (UIDevice.currentDevice.iPadDevice) {
            permissionsAlertController.modalPresentationStyle = UIModalPresentationPopover;
            permissionsAlertController.popoverPresentationController.sourceRect = sourceView.frame;
            permissionsAlertController.popoverPresentationController.sourceView = sourceView;
        }
        
        [self presentViewController:permissionsAlertController animated:YES completion:nil];
    }
}

- (void)removeParticipantFromGroup {
    MEGAChatGenericRequestDelegate *delegate = [MEGAChatGenericRequestDelegate.alloc initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
        if (error.type) {
            [SVProgressHUD showErrorWithStatus:error.name];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
    
    [MEGASdkManager.sharedMEGAChatSdk removeFromChat:self.groupChatRoom.chatId userHandle:self.userHandle delegate:delegate];
}

- (void)addParticipantToContact {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [MEGAInviteContactRequestDelegate.alloc initWithNumberOfRequests:1];
        [MEGASdkManager.sharedMEGASdk inviteContactWithEmail:self.userEmail message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
    }
}
- (void)showRemoveContactAlert {
    
    NSString *message = [NSString stringWithFormat:AMLocalizedString(@"removeUserMessage", nil), self.userEmail];
    
    UIAlertController *removeContactAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        MEGARemoveContactRequestDelegate *removeContactRequestDelegate = [[MEGARemoveContactRequestDelegate alloc] initWithNumberOfRequests:1 completion:^{
            //TODO: Close chat room because the contact was removed
            
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [[MEGASdkManager sharedMEGASdk] removeContactUser:self.user delegate:removeContactRequestDelegate];
    }];
    
    [removeContactAlertController addAction:cancelAction];
    [removeContactAlertController addAction:okAction];
    
    [self presentViewController:removeContactAlertController animated:YES completion:nil];
}

- (void)sendInviteContact {
    MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
    [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:self.userEmail message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
}

- (void)pushVerifyCredentialsViewController {
    VerifyCredentialsViewController *verifyCredentialsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"VerifyCredentialsViewControllerID"];
    verifyCredentialsVC.user = self.user;
    verifyCredentialsVC.userName = self.userName;
    [self.navigationController pushViewController:verifyCredentialsVC animated:YES];
}

- (void)openChatRoomWithChatId:(uint64_t)chatId {
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom                = self.chatRoom;
    [self.navigationController pushViewController:messagesVC animated:YES];
}

- (void)sendMessageToContact {
    if (self.contactDetailsMode == ContactDetailsModeDefault || self.contactDetailsMode == ContactDetailsModeFromGroupChat) {
        if (self.chatRoom) {
            [self openChatRoomWithChatId:self.chatRoom.chatId];
        } else {
            MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
            [peerList addPeerWithHandle:self.userHandle privilege:MEGAChatRoomPrivilegeStandard];
            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                self.chatRoom = chatRoom;
                [self openChatRoomWithChatId:chatRoom.chatId];
            }];
            [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
        }
    } else {
        NSUInteger viewControllersCount = self.navigationController.viewControllers.count;
        UIViewController *previousViewController = viewControllersCount >= 2 ? self.navigationController.viewControllers[viewControllersCount - 2] : nil;
        if (previousViewController && [previousViewController isKindOfClass:MessagesViewController.class]) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self openChatRoomWithChatId:self.chatRoom.chatId];
        }
    }
}

- (void)collapseAvatarView {
    [UIView animateWithDuration:.3 animations:^{
        self.avatarViewHeightConstraint.constant = self.avatarCollapsedPosition;
        self.gradientView.alpha = 1;
        [self.view layoutIfNeeded];
    }];
}

- (void)expandAvatarView {
    [UIView animateWithDuration:.3 animations:^{
        self.avatarViewHeightConstraint.constant = self.avatarExpandedPosition;
        self.gradientView.alpha = 0;
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)isSharedFolderSection:(NSInteger)section {
    return (self.contactDetailsSections.count > section
            && self.contactDetailsSections[section].intValue == ContactDetailsSectionSharedFolders);
}

- (void)openSharedFolderAtIndexPath:(NSIndexPath *)indexPath {
    CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
    MEGANode *incomingNode = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
    cloudDriveVC.parentNode = incomingNode;
    cloudDriveVC.displayMode = DisplayModeCloudDrive;
    [self.navigationController pushViewController:cloudDriveVC animated:YES];
}

- (void)performCallWithVideo:(BOOL)video {
    if (self.chatRoom) {
        [self openCallViewWithVideo:video active:NO];
    } else {
        MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
        [peerList addPeerWithHandle:self.userHandle privilege:MEGAChatRoomPrivilegeStandard];
        MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
            self.chatRoom = chatRoom;
            [self openCallViewWithVideo:video active:NO];
        }];
        [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
    }
}

- (void)openCallViewWithVideo:(BOOL)videoCall active:(BOOL)active {
    if ([[UIDevice currentDevice] orientation] != UIInterfaceOrientationPortrait) {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }

    CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
    callVC.chatRoom = self.chatRoom;
    callVC.videoCall = videoCall;
    callVC.callType = active ? CallTypeActive : CallTypeOutgoing;
    callVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    callVC.megaCallManager = ((AppDelegate *)UIApplication.sharedApplication.delegate).megaCallManager;
    [self presentViewController:callVC animated:YES completion:nil];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.avatarImageView];
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (translation.y < 0 && self.avatarViewHeightConstraint.constant > self.avatarCollapsedPosition) {
            self.avatarViewHeightConstraint.constant += translation.y;
        }
        
        if (translation.y > 0 && self.avatarViewHeightConstraint.constant < self.avatarExpandedPosition) {
            self.avatarViewHeightConstraint.constant += translation.y;
        }
        
        float alpha = ((self.avatarViewHeightConstraint.constant - self.avatarExpandedPosition) / (self.avatarCollapsedPosition - self.avatarExpandedPosition));
        self.gradientView.alpha = alpha;
        
        [recognizer setTranslation:CGPointZero inView:self.avatarImageView];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded ) {
        CGPoint velocity = [recognizer velocityInView:self.avatarImageView];
        if (velocity.y != 0) {
            if (velocity.y < 0 && self.avatarViewHeightConstraint.constant > self.avatarCollapsedPosition) {
                [self collapseAvatarView];
            } else if (velocity.y > 0 && self.avatarViewHeightConstraint.constant < self.avatarExpandedPosition) {
                [self expandAvatarView];
            }
        } else {
            if (((self.avatarViewHeightConstraint.constant - self.avatarExpandedPosition) / (self.avatarCollapsedPosition - self.avatarExpandedPosition)) > 0.5) {
                [self collapseAvatarView];
            } else {
                [self expandAvatarView];
            }
        }
    }
}

- (void)internetConnectionChanged {
    [self updateCallButtonsState];
    [self.tableView reloadData];
}

- (void)updateCallButtonsState {
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.userEmail];
    if (!user || user.visibility != MEGAUserVisibilityVisible) {
        self.messageButton.enabled = self.callButton.enabled = self.videoCallButton.enabled = NO;
        return;
    }
    
    if (self.chatRoom) {
        if (self.chatRoom.ownPrivilege < MEGAChatRoomPrivilegeStandard) {
            self.messageButton.enabled = self.callButton.enabled = self.videoCallButton.enabled = NO;
            return;
        }
        MEGAChatConnection chatConnection = [MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.chatRoom.chatId];
        if (chatConnection != MEGAChatConnectionOnline) {
            self.callButton.enabled = self.videoCallButton.enabled = NO;
            return;
        }
    }
    
    if (!MEGAReachabilityManager.isReachable) {
        self.callButton.enabled = self.videoCallButton.enabled = NO;
        return;
    }
    
    if (MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
        self.callButton.enabled = self.videoCallButton.enabled = NO;
        return;
    }
    
    self.callButton.enabled = self.videoCallButton.enabled = YES;
}

- (void)configureGestures {
    if (!self.panAvatar) {
        NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:[MEGASdk base64HandleForUserHandle:self.userHandle]];
        
        if ([NSFileManager.defaultManager fileExistsAtPath:avatarFilePath]) {
            self.panAvatar = [UIPanGestureRecognizer.alloc initWithTarget:self action:@selector(handlePan:)];
            [self.avatarImageView addGestureRecognizer:self.panAvatar];
        }
    }
    
    if (self.navigationController != nil) {
        [self.avatarImageView.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIPanGestureRecognizer class]]) {
                [obj requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
            }
        }];
    }
}

- (void)showNickNameViewContoller {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Contacts" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"AddNickNameNavigationControllerID"];
    
    NicknameViewController *nicknameViewController = navigationController.viewControllers.firstObject;
    
    nicknameViewController.user = self.user;
    nicknameViewController.nickname = self.userNickname;
    
    __weak typeof(self) weakself = self;
    nicknameViewController.nicknameChangedHandler = ^(NSString * _Nonnull nickname) {
        weakself.userNickname = nickname;
        [weakself updateUserDetails];
        [weakself.tableView reloadData];
    };
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)updateUserDetails {
    BOOL isNicknamePresent = self.userNickname.length > 0;
    self.nameOrNicknameLabel.text = isNicknamePresent ? self.userNickname : self.userName;
    self.optionalNameLabel.text = isNicknamePresent ? self.userName : nil;
}

- (void)configureShadowInLayer:(CALayer *)layer {
    layer.shadowOffset = CGSizeMake(0, 1);
    layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
    layer.shadowRadius = 2.0;
    layer.shadowOpacity = 1;
}

- (nullable NSArray<NSNumber *> *)sectionsForTableView {
    NSArray<NSNumber *> *sections = nil;
    switch (self.contactDetailsMode) {
        case ContactDetailsModeDefault:
            sections = self.sectionsForContactModeDefault;
            break;
          
        case ContactDetailsModeFromChat:
            sections = self.sectionsForContactFromChat;
            break;
            
        case ContactDetailsModeFromGroupChat:
            sections = self.sectionsForContactFromGroupChat;
            break;
            
        default:
            break;
    }
    
    return sections;
}

- (NSArray<NSNumber *> *)sectionsForContactModeDefault {
    return [self addSharedFoldersSectionIfNeededToSections:@[@(ContactDetailsSectionNicknameVerifyCredentials), @(ContactDetailsSectionAddAndRemoveContact)]];
}

- (NSArray<NSNumber *> *)sectionsForContactFromChat {
    if (self.shouldAllowToAddContact) {
        return [self addSharedFoldersSectionIfNeededToSections:@[@(ContactDetailsSectionClearChatHistory), @(ContactDetailsSectionArchiveChat)]];
    }
    
    return [self addSharedFoldersSectionIfNeededToSections:@[@(ContactDetailsSectionNicknameVerifyCredentials), @(ContactDetailsSectionClearChatHistory), @(ContactDetailsSectionArchiveChat)]];
}

- (NSArray<NSNumber *> *)sectionsForContactFromGroupChat {
    NSMutableArray *sections = NSMutableArray.new;
    
    if (self.shouldAllowToAddContact) { // User not in contact list
        [sections addObject:@(ContactDetailsSectionAddParticipantToContact)];
    } else { // user in contact list
        [sections addObject:@(ContactDetailsSectionNicknameVerifyCredentials)];
    }
    
    MEGAChatRoomPrivilege peerPrivilege = [self.groupChatRoom peerPrivilegeByHandle:self.userHandle];
    if (self.groupChatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator || peerPrivilege >= MEGAChatRoomPrivilegeRo) {
        [sections addObjectsFromArray:@[@(ContactDetailsSectionSetPermission), @(ContactDetailsSectionRemoveParticipant)]];
    }
    
    return [sections copy];
}

- (NSArray<NSNumber *> *)addSharedFoldersSectionIfNeededToSections:(NSArray<NSNumber *> *)inputSections {
    NSMutableArray *sections = NSMutableArray.new;
    [sections addObjectsFromArray:inputSections];
    
    if (self.incomingNodeListForUser.size.integerValue != 0) {
        [sections addObject:@(ContactDetailsSectionSharedFolders)];
    }
    
    return [sections copy];
}

- (BOOL)shouldAllowToAddContact {
    MEGAUser *user = [MEGASdkManager.sharedMEGASdk contactForEmail:self.userEmail];
    return (user == nil || user.visibility != MEGAUserVisibilityVisible);
}

- (NSArray<NSNumber *> *)rowsForNicknameAndVerify {
    return @[@(ContactDetailsRowNickname), @(ContactDetailsRowVerifyCredentials)];
}

#pragma mark - IBActions

- (IBAction)notificationsSwitchValueChanged:(UISwitch *)sender {
    //TODO: Enable/disable notifications
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
    
    CustomActionViewController *actionController = [[CustomActionViewController alloc] init];
    actionController.node = node;
    actionController.displayMode = DisplayModeSharedItem;
    actionController.actionDelegate = self;
    actionController.incomingShareChildView = YES;
    if ([[UIDevice currentDevice] iPadDevice]) {
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        actionController.popoverPresentationController.delegate = actionController;
        actionController.popoverPresentationController.sourceView = sender;
        actionController.popoverPresentationController.sourceRect = CGRectMake(0, 0, sender.frame.size.width / 2, sender.frame.size.height / 2);
    } else {
        actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    
    [self presentViewController:actionController animated:YES completion:nil];
}

- (IBAction)backTouchUpInside:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)messageTouchUpInside:(id)sender {
    [self sendMessageToContact];
}

- (IBAction)startAudioVideoCallTouchUpInside:(UIButton *)sender {
    if (!MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
        [DevicePermissionsHelper audioPermissionModal:YES forIncomingCall:NO withCompletionHandler:^(BOOL granted) {
            if (granted) {
                if (sender.tag) {
                    [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                        if (granted) {
                            [self performCallWithVideo:sender.tag];
                        } else {
                            [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:nil];
                        }
                    }];
                } else {
                    [self performCallWithVideo:sender.tag];
                }
            } else {
                [DevicePermissionsHelper alertAudioPermissionForIncomingCall:NO];
            }
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    self.contactDetailsSections = self.sectionsForTableView;
    return self.contactDetailsSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowsInSection;
    if ([self isSharedFolderSection:section]) {
        rowsInSection = self.incomingNodeListForUser.size.integerValue;
    } else if (section == ContactDetailsSectionNicknameVerifyCredentials) {
        rowsInSection = self.rowsForNicknameAndVerify.count;
    } else {
        rowsInSection = 1;
    }
    return rowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell;
    
    switch (self.contactDetailsSections[indexPath.section].intValue) {
        case ContactDetailsSectionNicknameVerifyCredentials:
            switch (self.rowsForNicknameAndVerify[indexPath.row].intValue) {
                case ContactDetailsRowNickname:
                    cell = [self cellForNicknameWithIndexPath:indexPath];
                    break;
                    
                case ContactDetailsRowVerifyCredentials:
                    cell = [self cellForVerifyCredentialsWithIndexPath:indexPath];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case ContactDetailsSectionAddAndRemoveContact:
            cell = [self cellForAddAndRemoveContactWithIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionSharedFolders:
            cell = [self cellForSharedFoldersWithIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionClearChatHistory:
            cell = [self cellForClearChatHistoryWithIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionArchiveChat:
            cell = [self cellForArchiveChatWithIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionAddParticipantToContact:
            cell = [self cellForAddParticipantAsContactWithIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionSetPermission:
            cell = [self cellForSetPermissionWithIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionRemoveParticipant:
            cell = [self cellForRemoveParticipantWithIndexPath:indexPath];
            break;
            
        default:
            break;
    }
    
    if (self.contactDetailsMode == ContactDetailsModeDefault) {
        cell.userInteractionEnabled = cell.avatarImageView.userInteractionEnabled = cell.nameLabel.enabled = MEGAReachabilityManager.isReachable;
    }

    if (@available(iOS 11.0, *)) {
        cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self isSharedFolderSection:section]) {
        self.participantsHeaderViewLabel.text = [AMLocalizedString(@"sharedFolders", @"Title of the incoming shared folders of a user.") uppercaseString];
        return self.participantsHeaderView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 || [self isSharedFolderSection:section]) {
        return 24;
    }
    
        return 0.01f;
    }
    
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
        return 24.0f;
    }
    
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isSharedFolderSection:indexPath.section]) {
        return 60.0f;
    } else {
        return 44.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.contactDetailsSections[indexPath.section].intValue) {
        case ContactDetailsSectionNicknameVerifyCredentials:
            switch (self.rowsForNicknameAndVerify[indexPath.row].intValue) {
                case ContactDetailsRowNickname:
                    [self showNickNameViewContoller];
                    break;
                    
                case ContactDetailsRowVerifyCredentials:
                    [self pushVerifyCredentialsViewController];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case ContactDetailsSectionAddAndRemoveContact:
            if (self.user.visibility == MEGAUserVisibilityVisible) {
                [self showRemoveContactAlert];
            } else {
                [self sendInviteContact];
            }
            break;
            
        case ContactDetailsSectionSharedFolders: {
            [self openSharedFolderAtIndexPath:indexPath];
            break;
            
        case ContactDetailsSectionClearChatHistory:
            [self showClearChatHistoryAlert];
            break;
            
        case ContactDetailsSectionArchiveChat:
            [self showArchiveChatAlertAtIndexPath];
            break;
            
        case ContactDetailsSectionAddParticipantToContact:
            [self addParticipantToContact];
            break;
            
        case ContactDetailsSectionSetPermission:
            [self showPermissionAlertWithSourceView:[self.tableView cellForRowAtIndexPath:indexPath]];
            break;
            
        case ContactDetailsSectionRemoveParticipant:
            [self removeParticipantFromGroup];
            break;

        default:
            break;
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - CustomActionViewControllerDelegate

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node fromSender:(id)sender {
    switch (action) {
        case MegaNodeActionTypeDownload:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [node mnz_downloadNodeOverwriting:NO];
            break;
            
        case MegaNodeActionTypeCopy: {
            [node mnz_copyInViewController:self];
            break;
        }
            
        case MegaNodeActionTypeRename:
            [node mnz_renameNodeInViewController:self];
            break;
            
        case MegaNodeActionTypeFileInfo: {
            UINavigationController *nodeInfoNavigation = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"NodeInfoNavigationControllerID"];
            NodeInfoViewController *nodeInfoVC = nodeInfoNavigation.viewControllers.firstObject;
            nodeInfoVC.node = node;
            
            [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
            break;
        }
            
        case MegaNodeActionTypeLeaveSharing:
            [node mnz_leaveSharingInViewController:self];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress) {
        return;
    }
    
    if (userHandle == self.user.handle) {
        self.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:onlineStatus];
        self.statusLabel.text = [NSString chatStatusString:onlineStatus];
        if (onlineStatus < MEGAChatStatusOnline) {
            [MEGASdkManager.sharedMEGAChatSdk requestLastGreen:self.user.handle];
        }
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (self.chatRoom.chatId == chatId) {
        [self updateCallButtonsState];
        [self.tableView reloadData];
    } else if (self.groupChatRoom.chatId == chatId) {
        [self.tableView reloadData];
    }
}

- (void)onChatPresenceLastGreen:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle lastGreen:(NSInteger)lastGreen {
    if (userHandle == self.user.handle) {
        if (self.user.handle == userHandle) {
            MEGAChatStatus chatStatus = [[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:self.user.handle];
            if (chatStatus < MEGAChatStatusOnline) {
                self.statusLabel.text = [NSString mnz_lastGreenStringFromMinutes:lastGreen];
            }
        }
    }
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    if (call.status == MEGAChatCallStatusDestroyed) {
        [self updateCallButtonsState];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    BOOL shouldProcessOnNodesUpdate = NO;
    NSArray *incomingNodesForUserArray = self.incomingNodeListForUser.mnz_nodesArrayFromNodeList;
    NSArray *nodesUpdateArray = nodeList.mnz_nodesArrayFromNodeList;
    for (MEGANode *incomingNode in incomingNodesForUserArray) {
        for (MEGANode *nodeUpdated in nodesUpdateArray) {
            if (incomingNode.handle == nodeUpdated.handle) {
                shouldProcessOnNodesUpdate = YES;
                break;
            } else {
                if ([nodeUpdated hasChangedType:MEGANodeChangeTypeInShare] || (nodeUpdated.isFolder && [nodeUpdated hasChangedType:MEGANodeChangeTypeNew]) || [nodeUpdated hasChangedType:MEGANodeChangeTypeRemoved]) {
                    shouldProcessOnNodesUpdate = YES;
                    break;
                }
            }
        }
    }
    
    if (shouldProcessOnNodesUpdate) {
        self.incomingNodeListForUser = [[MEGASdkManager sharedMEGASdk] inSharesForUser:self.user];
        [self.tableView reloadData];
    }
}

@end
