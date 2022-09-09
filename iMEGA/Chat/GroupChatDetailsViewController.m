#import "GroupChatDetailsViewController.h"

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "ChatRoomsViewController.h"
#import "ContactsViewController.h"
#import "ContactDetailsViewController.h"
#import "CustomModalAlertViewController.h"
#import "GroupChatDetailsViewTableViewCell.h"

#import "MEGAInviteContactRequestDelegate.h"
#import "MEGALinkManager.h"
#import "MEGANavigationController.h"
#import "MEGASdkManager.h"
#import "MEGAGlobalDelegate.h"
#import "MEGAArchiveChatRequestDelegate.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"

@interface GroupChatDetailsViewController () <MEGAChatRequestDelegate, MEGAChatDelegate, MEGAGlobalDelegate, PushNotificationControlProtocol, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *groupInfoView;
@property (weak, nonatomic) IBOutlet MegaAvatarView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;
@property (weak, nonatomic) IBOutlet UIView *groupInfoBottomSeparatorView;

@property (strong, nonatomic) NSMutableArray<NSNumber *> *participantsMutableArray;
@property (nonatomic) NSMutableDictionary<NSString *, NSIndexPath *> *indexPathsMutableDictionary;
@property (nonatomic) NSMutableSet<NSNumber *> *requestedParticipantsMutableSet;
@property (atomic) NSUInteger pendingCellsToLoadAfterThreshold;

@end

@implementation GroupChatDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"info", @"A button label. The button allows the user to get more info of the current context");
    self.requestedParticipantsMutableSet = NSMutableSet.new;
    self.chatNotificationControl = [ChatNotificationControl.alloc initWithDelegate:self];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"GenericHeaderFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"GenericHeaderFooterViewID"];

    [self updateAppearance];
    [self populateSections];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [MEGASdkManager.sharedMEGAChatSdk addChatRequestDelegate:self];
    [self addChatCallDelegate];
    [self addChatRoomDelegate];
    
    [self updateHeadingView];
    [self setParticipants];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
    [MEGASdkManager.sharedMEGAChatSdk removeChatRequestDelegate:self];
    [self removeChatCallDelegate];
    [self removeChatRoomDelegate];
}

- (BOOL)hidesBottomBarWhenPushed {
    return YES;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

- (void)reloadData {
    [self populateSections];
    [self.tableView reloadData];
}

#pragma mark - Private

- (void)populateSections {
    NSMutableArray *sections = NSMutableArray.new;
    [sections addObjectsFromArray:@[
        @(GroupChatDetailsSectionChatNotifications),
        @(GroupChatDetailsSectionAllowNonHostToAddParticipants),
        @(GroupChatDetailsSectionRenameGroup),
        @(GroupChatDetailsSectionSharedFiles),
        @(GroupChatDetailsSectionGetChatLink),
        @(GroupChatDetailsSectionManageChatHistory),
        @(GroupChatDetailsSectionArchiveChat),
        @(GroupChatDetailsSectionLeaveGroup)
    ]];
    
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:self.chatRoom.chatId];
    if (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator
        && (call.status == MEGAChatCallStatusInProgress || call.status == MEGAChatCallStatusUserNoPresent)) {
        [sections addObject:@(GroupChatDetailsSectionEndCallForAll)];
    }
    
    [sections addObjectsFromArray:@[
        @(GroupChatDetailsSectionEncryptedKeyRotation),
        @(GroupChatDetailsSectionObservers),
        @(GroupChatDetailsSectionParticipants)
    ]];
    
    self.groupDetailsSections = sections;
}

- (void)updateAppearance {
    self.view.backgroundColor = self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.groupInfoView.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    self.participantsLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    self.groupInfoBottomSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

- (void)updateHeadingView {
    self.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:self.chatRoom.chatId];
    self.nameLabel.text = self.chatRoom.chatTitle;
    
    [self.avatarView setupFor:self.chatRoom];
    
    if (self.chatRoom.ownPrivilege < MEGAChatRoomPrivilegeRo) {
        self.participantsLabel.text = NSLocalizedString(@"Inactive chat", @"Subtitle of chat screen when the chat is inactive");
    } else {
        NSInteger peers = self.chatRoom.peerCount + (!self.chatRoom.isPreview ? 1 : 0);
        self.participantsLabel.text = (peers == 1) ? [NSString stringWithFormat:NSLocalizedString(@"%d participant", @"Singular of participant. 1 participant"), 1] : [NSString stringWithFormat:NSLocalizedString(@"%d participants", @"Singular of participant. 1 participant"), (int)peers];
    }
}

- (void)setParticipants {
    self.participantsMutableArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < self.chatRoom.peerCount; i++) {
        uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:i];
        if ([self.chatRoom peerPrivilegeByHandle:peerHandle] > MEGAChatRoomPrivilegeRm) {
            [self.participantsMutableArray addObject:[NSNumber numberWithUnsignedLongLong:peerHandle]];
        }
    }
    
    if (!self.chatRoom.isPreview) {
        uint64_t myHandle = [[MEGASdkManager sharedMEGAChatSdk] myUserHandle];
        [self.participantsMutableArray addObject:[NSNumber numberWithUnsignedLongLong:myHandle]];
    }
    
    self.indexPathsMutableDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.participantsMutableArray.count];
}

- (void)loadVisibleParticipants {
    NSUInteger participantsToLoad = self.tableView.indexPathsForVisibleRows.count;
    NSMutableArray<NSNumber *> *usersHandles = [NSMutableArray.alloc initWithCapacity:participantsToLoad];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        if (indexPath.row >= self.participantsMutableArray.count) {
            continue;
        }
        NSNumber *handle = [self.participantsMutableArray objectAtIndex:indexPath.row];
        if (![MEGASdkManager.sharedMEGAChatSdk userFullnameFromCacheByUserHandle:handle.unsignedLongLongValue] && ![self.requestedParticipantsMutableSet containsObject:handle]) {
            [usersHandles addObject:handle];
            [self.requestedParticipantsMutableSet addObject:handle];
        }
    }
    if (usersHandles.count) {
        [MEGASdkManager.sharedMEGAChatSdk loadUserAttributesForChatId:self.chatRoom.chatId usersHandles:usersHandles delegate:self];
    }
}

- (void)loadVisibleParticipantsIfNeeded {
    if (--self.pendingCellsToLoadAfterThreshold == 0) {
        [self loadVisibleParticipants];
    }
}

- (void)alertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if ([alertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        BOOL enableRightButton = NO;
        if ((textField.text.length > 0) && ![textField.text isEqualToString:self.chatRoom.title] && ![[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] && ([textField.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 31)) {
            enableRightButton = YES;
        }
        rightButtonAction.enabled = enableRightButton;
    }
}

- (void)showArchiveChatAlert {
    NSString *title = self.chatRoom.isArchived ? NSLocalizedString(@"unarchiveChatMessage", @"Confirmation message for user to confirm it will unarchive an archived chat.") : NSLocalizedString(@"archiveChatMessage", @"Confirmation message on archive chat dialog for user to confirm.");
    UIAlertController *archiveAlertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [archiveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [archiveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MEGAArchiveChatRequestDelegate *archiveChatRequesDelegate = [[MEGAArchiveChatRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
            if (chatRoom.isArchived) {
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
        [[MEGASdkManager sharedMEGAChatSdk] archiveChat:self.chatRoom.chatId archive:!self.chatRoom.isArchived delegate:archiveChatRequesDelegate];
    }]];
    
    [self presentViewController:archiveAlertController animated:YES completion:nil];
}

- (void)showLeaveChatAlert {
    UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"youWillNoLongerHaveAccessToThisConversation", @"Alert text that explains what means confirming the action 'Leave'") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [leaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [leaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MEGAChatGenericRequestDelegate *delegate = [MEGAChatGenericRequestDelegate.alloc initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
            if (!error.type) {
                [MEGALinkManager.joiningOrLeavingChatBase64Handles removeObject:[MEGASdk base64HandleForUserHandle:self.chatRoom.chatId]];
            }
        }];
        [MEGASdkManager.sharedMEGAChatSdk leaveChat:self.chatRoom.chatId delegate:delegate];
        [MEGALinkManager.joiningOrLeavingChatBase64Handles addObject:[MEGASdk base64HandleForUserHandle:self.chatRoom.chatId]];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [self presentViewController:leaveAlertController animated:YES completion:nil];
}

- (void)renameChatGroup {
    UIAlertController *renameGroupAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"renameGroup", @"The title of a menu button which allows users to rename a group chat.") message:NSLocalizedString(@"renameNodeMessage", @"Hint text to suggest that the user have to write the new name for the file or folder") preferredStyle:UIAlertControllerStyleAlert];
    
    [renameGroupAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.chatRoom.title;
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return ((textField.text.length > 0) && ![textField.text isEqualToString:self.chatRoom.title] && ![[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] && ([textField.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 31));
        };
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        UITextField *textField = [[renameGroupAlertController textFields] firstObject];
        NSString *newGroupName = textField.text;
        [[MEGASdkManager sharedMEGAChatSdk] setChatTitle:self.chatRoom.chatId title:newGroupName delegate:self];
    }];
    
    [renameGroupAlertController addAction:cancelAction];
    [renameGroupAlertController addAction:renameAction];
    
    renameAction.enabled = NO;
    
    [self presentViewController:renameGroupAlertController animated:YES completion:nil];
}

- (void)presentNoChatLinkAvailable {
    NSString *descriptionText = nil;
    if (self.chatRoom.isMeeting) {
        descriptionText = NSLocalizedString(@"meetings.sharelink.Error", @"");
    } else {
        descriptionText = NSLocalizedString(@"No chat link available.", @"In some cases, a user may try to get the link for a chat room, but if such is not set by an operator - it would say \"not link available\" and not auto create it.");
    }
    
    CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
    customModalAlertVC.image = [UIImage imageNamed:@"chatLinkCreation"];
    customModalAlertVC.viewTitle = self.chatRoom.title;
    customModalAlertVC.firstButtonTitle = NSLocalizedString(@"close", @"A button label. The button allows the user to close the conversation.");
    customModalAlertVC.link = descriptionText;
    __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
    customModalAlertVC.firstCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self presentViewController:customModalAlertVC animated:YES completion:nil];
}

- (void)presentChatLinkOptionsWithLink:(NSString *)link {
    CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
    customModalAlertVC.image = [UIImage imageNamed:@"chatLinkCreation"];
    customModalAlertVC.viewTitle = self.chatRoom.title;
    customModalAlertVC.detail = NSLocalizedString(@"People can join your group by using this link.", @"Text explaining users how the chat links work.");
    customModalAlertVC.firstButtonTitle = NSLocalizedString(@"general.share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
    customModalAlertVC.link = link;
    if (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator) {
        customModalAlertVC.secondButtonTitle = NSLocalizedString(@"delete", nil);
    }
    customModalAlertVC.dismissButtonTitle = NSLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
    __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
    customModalAlertVC.firstCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:^{            
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
            if (activityVC.popoverPresentationController != nil) {
                activityVC.popoverPresentationController.sourceView = self.view;
                activityVC.popoverPresentationController.sourceRect = CGRectMake(0, 0, self.view.frame.size.width/2, self.view.frame.size.height/2);
            }
            
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
    };
    
    customModalAlertVC.secondCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:^{
            MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                if (!error.type) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"linkRemoved", @"Message shown when the link to a file or folder has been removed")];
                }
            }];
            [[MEGASdkManager sharedMEGAChatSdk] removeChatLink:self.chatRoom.chatId delegate:delegate];
        }];
    };
    
    customModalAlertVC.dismissCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self presentViewController:customModalAlertVC animated:YES completion:nil];
}

- (BOOL)shouldShowChatNotificationEnabledCell {
    return (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo) && !self.chatRoom.isPreview  ? YES : NO;
}

- (void)openContactDetailsWithEmail:(NSString *)email userHandle:(uint64_t)userHandle {
    if (email) {
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromGroupChat;
        contactDetailsVC.userEmail = email;
        contactDetailsVC.userHandle = userHandle;
        contactDetailsVC.groupChatRoom = self.chatRoom;
        
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

#pragma mark - IBActions

- (IBAction)didTapPermissionsButton:(UIButton *)sender {
    NSInteger index = (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator) ? (sender.tag - 1) : sender.tag;
    
    NSNumber *participant = [self.participantsMutableArray objectOrNilAtIndex:index];
    if (participant == nil) {
        return;
    }
    
    uint64_t userHandle = participant.unsignedLongLongValue;
    NSString *peerEmail = [MEGASdkManager.sharedMEGAChatSdk userEmailFromCacheByUserHandle:userHandle];
    
    if (index != (self.participantsMutableArray.count - 1)) {
        NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
        MEGAChatRoomPrivilege privilege = [self.chatRoom peerPrivilegeByHandle:userHandle];
        
        if (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator) {
            __weak __typeof__(self) weakSelf = self;
            
            UIImageView *checkmarkImageView = [UIImageView.alloc initWithImage:[UIImage imageNamed:@"turquoise_checkmark"]];

            [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat.") detail:nil accessoryView:privilege == MEGAChatRoomPrivilegeModerator ? checkmarkImageView : nil image:[UIImage imageNamed:@"moderator"] style:UIAlertActionStyleDefault actionHandler:^{
                [MEGASdkManager.sharedMEGAChatSdk updateChatPermissions:weakSelf.chatRoom.chatId userHandle:userHandle privilege:MEGAChatRoomPrivilegeModerator delegate:weakSelf];
            }]];
            [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.") detail:nil accessoryView:privilege == MEGAChatRoomPrivilegeStandard ? checkmarkImageView : nil image:[UIImage imageNamed:@"standard"] style:UIAlertActionStyleDefault actionHandler:^{
                [MEGASdkManager.sharedMEGAChatSdk updateChatPermissions:weakSelf.chatRoom.chatId userHandle:userHandle privilege:MEGAChatRoomPrivilegeStandard delegate:weakSelf];
            }]];
            [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") detail:nil accessoryView:privilege == MEGAChatRoomPrivilegeRo ? checkmarkImageView : nil image:[UIImage imageNamed:@"readOnly_chat"] style:UIAlertActionStyleDefault actionHandler:^{
                [MEGASdkManager.sharedMEGAChatSdk updateChatPermissions:weakSelf.chatRoom.chatId userHandle:userHandle privilege:MEGAChatRoomPrivilegeRo delegate:weakSelf];
            }]];
            
            if (peerEmail) {
                MEGAUser *user = [MEGASdkManager.sharedMEGASdk contactForEmail:peerEmail];
                if (!user || user.visibility != MEGAUserVisibilityVisible) {
                    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email") detail:nil image:[UIImage imageNamed:@"add"] style:UIAlertActionStyleDefault actionHandler:^{
                        if (MEGAReachabilityManager.isReachableHUDIfNot) {
                            MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [MEGAInviteContactRequestDelegate.alloc initWithNumberOfRequests:1];
                            [MEGASdkManager.sharedMEGASdk inviteContactWithEmail:peerEmail message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
                        }
                    }]];
                }
            
            }
            [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"removeParticipant", @"A button title which removes a participant from a chat.") detail:nil image:[UIImage imageNamed:@"delete"] style:UIAlertActionStyleDestructive actionHandler:^{
                [MEGASdkManager.sharedMEGAChatSdk removeFromChat:self.chatRoom.chatId userHandle:userHandle delegate:weakSelf];
            }]];
        } else {
            [self openContactDetailsWithEmail:peerEmail userHandle:userHandle];
        }
        
        if (actions.count > 0) {
            ActionSheetViewController *permissionsActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:NSLocalizedString(@"permissions", @"Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder ") dismissCompletion:nil sender:sender];
            [self presentViewController:permissionsActionSheet animated:YES completion:nil];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupDetailsSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (self.groupDetailsSections[section].unsignedIntegerValue) {
        case GroupChatDetailsSectionChatNotifications:
            numberOfRows = [self shouldShowChatNotificationEnabledCell] ? 1 : 0;
            break;
            
        case GroupChatDetailsSectionRenameGroup:
            numberOfRows = (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 1 : 0;
            break;

        case GroupChatDetailsSectionSharedFiles:
            numberOfRows = 1;
            break;
            
        case GroupChatDetailsSectionGetChatLink:
            numberOfRows = (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo && self.chatRoom.isPublicChat && !self.chatRoom.isPreview) ? 1 : 0;
            break;
            
        case GroupChatDetailsSectionManageChatHistory:
            numberOfRows = (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 1 : 0;
            break;
            
        case GroupChatDetailsSectionArchiveChat:
            numberOfRows = self.chatRoom.isPreview ? 0 : 1;
            break;
            
        case GroupChatDetailsSectionLeaveGroup:
            numberOfRows = (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo) ? 1 : 0;
            break;
        
        case GroupChatDetailsSectionEndCallForAll:
            numberOfRows = 1;
            break;
        case GroupChatDetailsSectionEncryptedKeyRotation: {
            numberOfRows = (!self.chatRoom.isPublicChat || self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 1 : 0;
            break;
        }
            
        case GroupChatDetailsSectionObservers:
            numberOfRows = self.chatRoom.previewersCount ? 1 : 0;
            break;
            
        case GroupChatDetailsSectionParticipants:
            numberOfRows = self.participantsMutableArray.count;
            
            if ([self shouldShowAddParticipants]) {
                numberOfRows += 1;
            }
            break;
            
        case GroupChatDetailsSectionAllowNonHostToAddParticipants:
            numberOfRows = (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator) ? 1 : 0;

        default:
            break;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupChatDetailsViewTableViewCell *cell;
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    
    if (self.groupDetailsSections[indexPath.section].unsignedIntegerValue != GroupChatDetailsSectionParticipants
        && self.groupDetailsSections[indexPath.section].unsignedIntegerValue != GroupChatDetailsSectionObservers
        && self.groupDetailsSections[indexPath.section].unsignedIntegerValue != GroupChatDetailsSectionChatNotifications) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsLeaveGroupTypeID" forIndexPath:indexPath];
        cell.enableLabel.text = @"";
    }
    
    switch (self.groupDetailsSections[indexPath.section].unsignedIntegerValue) {
        case GroupChatDetailsSectionChatNotifications:
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsSwitchTypeID" forIndexPath:indexPath];
            [self.chatNotificationControl configureWithCell:(id<ChatNotificationControlCellProtocol>)cell
                                                     chatId:self.chatRoom.chatId];
            cell.delegate = self;
            break;
            
        case GroupChatDetailsSectionAllowNonHostToAddParticipants:
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsSwitchTypeID" forIndexPath:indexPath];
            [self configureAllowNonHostToAddParticipantsCell:cell];
            break;
            
        case GroupChatDetailsSectionRenameGroup:
            cell.leftImageView.image = [UIImage imageNamed:@"rename"];
            cell.leftImageView.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            cell.nameLabel.text = NSLocalizedString(@"renameGroup", @"The title of a menu button which allows users to rename a group chat.");
            break;
            
        case GroupChatDetailsSectionSharedFiles:
            cell.leftImageView.image = [UIImage imageNamed:@"sharedFiles"];
            cell.nameLabel.text =  NSLocalizedString(@"Shared Files", @"Header of block with all shared files in chat.");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case GroupChatDetailsSectionGetChatLink:
            cell.leftImageView.image = [UIImage imageNamed:@"link"];
            cell.nameLabel.text = NSLocalizedString(@"Get Chat Link", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case GroupChatDetailsSectionManageChatHistory:
            cell.leftImageView.image = [UIImage imageNamed:@"clearChatHistory"];
            cell.nameLabel.text = NSLocalizedString(@"Manage Chat History", @"Text related with the section where you can manage the chat history. There you can for example, clear the history or configure the retention setting.");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case GroupChatDetailsSectionArchiveChat:
            cell.leftImageView.image = self.chatRoom.isArchived ? [UIImage imageNamed:@"unArchiveChat"] : [UIImage imageNamed:@"archiveChat"];
            cell.leftImageView.tintColor = self.chatRoom.isArchived ? [UIColor mnz_redForTraitCollection:(self.traitCollection)] : [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            cell.nameLabel.text = self.chatRoom.isArchived ? NSLocalizedString(@"unarchiveChat", @"The title of the dialog to unarchive an archived chat.") : NSLocalizedString(@"archiveChat", @"Title of button to archive chats.");
            [cell setDestructive:self.chatRoom.isArchived];
            break;
            
        case GroupChatDetailsSectionLeaveGroup:
            cell.leftImageView.image = [UIImage imageNamed:@"leaveGroup"];
            cell.nameLabel.text = self.chatRoom.isPreview ? NSLocalizedString(@"close", nil) : NSLocalizedString(@"leaveGroup", @"Button title that allows the user to leave a group chat.");
            [cell setDestructive:YES];
            break;
        
        case GroupChatDetailsSectionEndCallForAll:
            cell.leftImageView.image = [UIImage imageNamed:@"endCall"];
            cell.leftImageView.tintColor = [UIColor redColor];
            cell.leftImageView.contentMode = UIViewContentModeScaleAspectFit;
            cell.nameLabel.text = NSLocalizedString(@"meetings.endCall.endForAllButtonTitle", @"Button title that ends the call for all the participants.");
            [cell setDestructive:YES];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;

        case GroupChatDetailsSectionEncryptedKeyRotation:
            cell.nameLabel.text = self.chatRoom.isPublicChat ? NSLocalizedString(@"Enable Encrypted Key Rotation", @"Title show in a cell where the users can enable the 'Encrypted Key Rotation'") : NSLocalizedString(@"Encrypted Key Rotation", @"Label in a cell where you can enable the 'Encrypted Key Rotation'");
            cell.leftImageView.hidden = YES;
            if (self.chatRoom.isPublicChat) {
                cell.enableLabel.hidden = YES;
                cell.nameLabel.enabled = cell.userInteractionEnabled = self.chatRoom.peerCount < 100;
            } else {
                cell.enableLabel.hidden = cell.userInteractionEnabled = NO;
            }
            cell.accessoryType = cell.enableLabel.hidden ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            cell.enableLabel.text = cell.enableLabel.hidden ? @"" : NSLocalizedString(@"Enabled", @"The label of the toggle switch to indicate that file versioning is enabled.");
            break;
            
        case GroupChatDetailsSectionObservers:
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsObserversTypeID" forIndexPath:indexPath];
            cell.leftImageView.image = [UIImage imageNamed:@"chatObservers"];
            cell.emailLabel.text = NSLocalizedString(@"Observers", @"Users previewing a public chat");
            cell.rightLabel.text = [NSString stringWithFormat:@"%tu", self.chatRoom.previewersCount];
            break;
            
        case GroupChatDetailsSectionParticipants: {
            if ((indexPath.row == 0) && [self shouldShowAddParticipants]) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantEmailTypeID" forIndexPath:indexPath];
                cell.leftImageView.image = [UIImage imageNamed:@"inviteToChat"];
                cell.emailLabel.text = NSLocalizedString(@"addParticipant", @"Button label. Allows to add contacts in current chat conversation.");
                cell.onlineStatusView.backgroundColor = nil;
                [cell.permissionsButton setImage:nil forState:UIControlStateNormal];
                cell.permissionsButton.tag = indexPath.row;
                
                return cell;
            }
            
            NSInteger index = [self shouldShowAddParticipants] ? (indexPath.row - 1) : indexPath.row;
            
            uint64_t handle = [[self.participantsMutableArray objectAtIndex:index] unsignedLongLongValue];
            NSString *base64Handle = [MEGASdk base64HandleForUserHandle:handle];
            
            [self.indexPathsMutableDictionary setObject:indexPath forKey:base64Handle];
            
            NSString *peerDisplayName;
            NSString *peerEmail;
            MEGAChatRoomPrivilege privilege;
            MEGAUser *user = [MEGASdkManager.sharedMEGASdk contactForEmail:base64Handle];

            if (handle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
                NSString *myFullname = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
                peerDisplayName = [NSString stringWithFormat:@"%@ (%@)", myFullname, NSLocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.")];
                peerEmail = [[MEGASdkManager sharedMEGAChatSdk] myEmail];
                privilege = self.chatRoom.ownPrivilege;
            } else {                
                NSString *nickname = user.mnz_nickname;
                if (nickname.length > 0) {
                    peerDisplayName = nickname;
                } else {
                    peerDisplayName = [MEGASdkManager.sharedMEGAChatSdk userFullnameFromCacheByUserHandle:handle];
                }
                if (user.visibility == MEGAUserVisibilityVisible || user.visibility == MEGAUserVisibilityInactive) {
                    peerEmail = [MEGASdkManager.sharedMEGAChatSdk userEmailFromCacheByUserHandle:handle] ?: @"";
                } else {
                    peerEmail = @"";
                }
                
                privilege = [self.chatRoom peerPrivilegeAtIndex:index];
                if (!peerDisplayName) {
                    peerDisplayName = @"";
                    if (![self.requestedParticipantsMutableSet containsObject:[self.participantsMutableArray objectAtIndex:index]]) {
                        self.pendingCellsToLoadAfterThreshold++;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self loadVisibleParticipantsIfNeeded];
                        });
                    }
                }
            }
            
            BOOL isNameEmpty = [[peerDisplayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
            if (isNameEmpty) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantEmailTypeID" forIndexPath:indexPath];
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupChatDetailsParticipantTypeID" forIndexPath:indexPath];
                cell.nameLabel.text = peerDisplayName;
                [cell.leftImageView mnz_setImageForUserHandle:handle];
            }
            
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForChatStatus:[MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:handle]];
            
            cell.emailLabel.text = peerEmail;
            
            UIImage *permissionsImage = nil;
            switch (privilege) {
                case MEGAChatRoomPrivilegeUnknown:
                case MEGAChatRoomPrivilegeRm:
                    break;
                    
                case MEGAChatRoomPrivilegeRo:
                    permissionsImage = [UIImage imageNamed:@"readOnly_chat"];
                    break;
                    
                case MEGAChatRoomPrivilegeStandard:
                    permissionsImage = [UIImage imageNamed:@"standard"];
                    break;
                    
                case MEGAChatRoomPrivilegeModerator:
                    permissionsImage = [UIImage imageNamed:@"moderator"];
                    break;
            }
            [cell.permissionsButton setImage:permissionsImage forState:UIControlStateNormal];
            cell.permissionsButton.tag = indexPath.row;
            cell.verifiedImageView.hidden = ![MEGASdkManager.sharedMEGASdk areCredentialsVerifiedOfUser:user];
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    GenericHeaderFooterView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    
    switch (self.groupDetailsSections[section].unsignedIntegerValue) {
        case GroupChatDetailsSectionChatNotifications:
            [headerView configureWithTitle:nil topDistance:[self shouldShowChatNotificationEnabledCell] ? 20.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionManageChatHistory:
        case GroupChatDetailsSectionRenameGroup: {
            CGFloat headerHeight = self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator ? (self.groupDetailsSections[section].unsignedIntegerValue == GroupChatDetailsSectionRenameGroup ? 20.0f : 10.0f) : 1.0f;
            [headerView configureWithTitle:nil topDistance:headerHeight isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
        }
            break;
            
        case GroupChatDetailsSectionSharedFiles:
            [headerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionGetChatLink:
            if (self.chatRoom.isPublicChat) {
                if (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator) {
                    [headerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                } else if (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo && !self.chatRoom.isPreview) {
                    [headerView configureWithTitle:nil topDistance:20.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                } else {
                    [headerView configureWithTitle:nil topDistance:1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                }
            } else {
                [headerView configureWithTitle:nil topDistance:1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            }
            break;
            
        case GroupChatDetailsSectionArchiveChat:
            if (self.chatRoom.isPreview) {
                [headerView configureWithTitle:nil topDistance:1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            } else {
                if (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) {
                    [headerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                } else if ( self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo) {
                    if (self.chatRoom.isPublicChat) {
                        [headerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                    } else {
                        [headerView configureWithTitle:nil topDistance:20.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                    }
                } else {
                    [headerView configureWithTitle:nil topDistance:20.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                }
            }
            
            break;
            
        case GroupChatDetailsSectionLeaveGroup:
            [headerView configureWithTitle:nil topDistance:self.chatRoom.isPreview ? 20.0f : 10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
        
        case GroupChatDetailsSectionEndCallForAll:
            [headerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
        
        case GroupChatDetailsSectionEncryptedKeyRotation:
            [headerView configureWithTitle:nil topDistance:(!self.chatRoom.isPublicChat || self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            break;
            
        case GroupChatDetailsSectionObservers:
            [headerView configureWithTitle:nil topDistance:(self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionParticipants:
            headerView.titleLabel.font = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium];
            [headerView configureWithTitle:NSLocalizedString(@"participants", @"Label to describe the section where you can see the participants of a group chat").localizedUppercaseString topDistance:4.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:YES];
            break;
            
        case GroupChatDetailsSectionAllowNonHostToAddParticipants:
            [headerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        default:
            [headerView configureWithTitle:nil topDistance:1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
    }
    
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    GenericHeaderFooterView *footerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GenericHeaderFooterViewID"];
    
    switch (self.groupDetailsSections[section].unsignedIntegerValue) {
        case GroupChatDetailsSectionChatNotifications: {
            NSString *remainingTimeString = [self.chatNotificationControl timeRemainingForDNDDeactivationStringWithChatId:self.chatRoom.chatId];
            
            footerView.titleLabel.numberOfLines = 0;
            footerView.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            [footerView configureWithTitle:[self shouldShowChatNotificationEnabledCell] ? remainingTimeString : nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
        }
            break;
            
        case GroupChatDetailsSectionRenameGroup:
            [footerView configureWithTitle:nil topDistance:self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionSharedFiles:
            [footerView configureWithTitle:nil topDistance:self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionGetChatLink:
            [footerView configureWithTitle:nil topDistance:(self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo) && self.chatRoom.isPublicChat && !self.chatRoom.isPreview ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionManageChatHistory:
            [footerView configureWithTitle:nil topDistance:self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionArchiveChat:
            [footerView configureWithTitle:nil topDistance:self.chatRoom.isPreview ? 1.0f : 10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionLeaveGroup:
            [footerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
        case GroupChatDetailsSectionEndCallForAll:
            [footerView configureWithTitle:nil topDistance:10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
        
        case GroupChatDetailsSectionEncryptedKeyRotation: {
            if (self.chatRoom.isPublicChat && self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) {
                footerView.titleLabel.numberOfLines = 0;
                footerView.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
                if (self.chatRoom.peerCount < 100) {
                    [footerView configureWithTitle:[NSLocalizedString(@"Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.", @"Footer text to explain what means 'Encrypted Key Rotation'") stringByAppendingString:@"\n"] topDistance:self.chatRoom.isPublicChat ? (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 10.0f : 1.0f : 10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                } else {
                    [footerView configureWithTitle:NSLocalizedString(@"Key rotation is disabled for conversations with more than 100 participants.", @"Footer to explain why key rotation is disabled for public chats with many participants") topDistance:self.chatRoom.isPublicChat ? (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) ? 10.f : 1.0f : 10.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
                }
            } else {
                [footerView configureWithTitle:nil topDistance:1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            }
            
            break;
        }
            
        case GroupChatDetailsSectionObservers:
            [footerView configureWithTitle:nil topDistance:self.chatRoom.previewersCount ? 10.0f : 1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        case GroupChatDetailsSectionParticipants:
            [footerView configureWithTitle:nil topDistance:20.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
            
        default:
            [footerView configureWithTitle:nil topDistance:1.0f isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
            break;
           
    }
    
    return footerView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (self.groupDetailsSections[indexPath.section].unsignedIntegerValue) {
            case GroupChatDetailsSectionRenameGroup:
                [self renameChatGroup];
                break;

            case GroupChatDetailsSectionSharedFiles:
                [self.navigationController pushViewController:[ChatSharedItemsViewController instantiateWith:self.chatRoom] animated:YES];
                break;
            
            case GroupChatDetailsSectionGetChatLink: {
                if (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeModerator) {
                    if (self.chatRoom.hasCustomTitle) {
                        MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                            if (error.type == MEGAChatErrorTypeOk) {
                                [self presentChatLinkOptionsWithLink:request.text];
                            } else {
                                MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                                    if (error.type == MEGAChatErrorTypeOk) {
                                        [self presentChatLinkOptionsWithLink:request.text];
                                    }
                                }];
                                [[MEGASdkManager sharedMEGAChatSdk] createChatLink:self.chatRoom.chatId delegate:delegate];
                            }
                        }];
                        [[MEGASdkManager sharedMEGAChatSdk] queryChatLink:self.chatRoom.chatId delegate:delegate];
                    } else {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Chat Link", @"Label shown in a cell where you can enable a switch to get a chat link") message:NSLocalizedString(@"To create a chat link you must name the group.", @"Alert message to advice the users that to generate a chat link they need enter a group name for the chat")  preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        }]];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self renameChatGroup];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                } else if (self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeRo) {
                    if (self.chatRoom.hasCustomTitle) {
                        MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                            if (error.type == MEGAChatErrorTypeOk) {
                                [self presentChatLinkOptionsWithLink:request.text];
                            } else {
                                [self presentNoChatLinkAvailable];
                            }
                        }];
                        [[MEGASdkManager sharedMEGAChatSdk] queryChatLink:self.chatRoom.chatId delegate:delegate];
                    } else {
                        [self presentNoChatLinkAvailable];
                    }
                }
                break;
            }
                
            case GroupChatDetailsSectionManageChatHistory:
                [[ManageChatHistoryViewRouter.alloc initWithChatId:self.chatRoom.chatId navigationController:self.navigationController] start];
                break;
                
            case GroupChatDetailsSectionArchiveChat:
                [self showArchiveChatAlert];
                break;
                
            case GroupChatDetailsSectionLeaveGroup:
                if (self.chatRoom.isPreview) {
                    [[MEGASdkManager sharedMEGAChatSdk] closeChatPreview:self.chatRoom.chatId];
                    if (self.presentingViewController) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }
                } else {
                    [self showLeaveChatAlert];
                }
                break;
            
            case GroupChatDetailsSectionEndCallForAll:
                [self showEndCallForAll];
                break;
                
            case GroupChatDetailsSectionEncryptedKeyRotation: {
                CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
                customModalAlertVC.image = [UIImage imageNamed:@"lock"];
                customModalAlertVC.viewTitle = NSLocalizedString(@"Enable Encrypted Key Rotation", @"Title show in a cell where the users can enable the 'Encrypted Key Rotation'");
                customModalAlertVC.detail = NSLocalizedString(@"Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.", @"Footer text to explain what means 'Encrypted Key Rotation'");
                customModalAlertVC.firstButtonTitle = NSLocalizedString(@"enable", nil);
                customModalAlertVC.dismissButtonTitle = NSLocalizedString(@"cancel", nil);
                __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
                customModalAlertVC.firstCompletion = ^{
                    MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                        if (error.type == MEGAChatErrorTypeOk) {
                            [weakCustom dismissViewControllerAnimated:YES completion:^{
                                [self.tableView reloadData];
                            }];
                        }
                    }];
                    [[MEGASdkManager sharedMEGAChatSdk] setPublicChatToPrivate:self.chatRoom.chatId delegate:delegate];
                };
                
                [self presentViewController:customModalAlertVC animated:YES completion:nil];
                break;
            }
                
            case GroupChatDetailsSectionParticipants:
                if (!MEGASdkManager.sharedMEGASdk.isLoggedIn) {
                    break;
                }
                
                if ((indexPath.row == 0) && [self shouldShowAddParticipants]) {
                    [self addParticipant];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    return;
                }
                
                NSInteger index = [self shouldShowAddParticipants] ? (indexPath.row - 1) : indexPath.row;
                uint64_t userHandle = [self.participantsMutableArray[index] unsignedLongLongValue];

                if (userHandle != MEGASdkManager.sharedMEGASdk.myUser.handle) {
                    NSString *userEmail = [MEGASdkManager.sharedMEGAChatSdk userEmailFromCacheByUserHandle:userHandle];
                    [self openContactDetailsWithEmail:userEmail userHandle:userHandle];
                }
                break;
                
            default:
                break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadVisibleParticipants];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadVisibleParticipants];
    }
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    self.chatRoom = [api chatRoomForChatId:self.chatRoom.chatId];
    
    if (error.type) {
        return;
    }
    
    switch (request.type) {            
        case MEGAChatRequestTypeUpdatePeerPermissions:
        case MEGAChatRequestTypeInviteToChatRoom:
        case MEGAChatRequestTypeRemoveFromChatRoom:
            [self setParticipants];
            [self.tableView reloadData];
            break;
            
        case MEGAChatRequestTypeGetPeerAttributes: {
            MEGAHandleList *handleList = request.megaHandleList;
            NSMutableArray<NSIndexPath *> *indexPathsToReload = [NSMutableArray.alloc initWithCapacity:handleList.size];
            for (NSUInteger i = 0; i < handleList.size; i++) {
                NSString *base64Handle = [MEGASdk base64HandleForUserHandle:[handleList megaHandleAtIndex:i]];
                NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
                if (indexPath && [self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                    [indexPathsToReload addObject:indexPath];
                }
            }
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
            
            break;
        }
            
        case MEGAChatRequestTypeTruncateHistory: {
            [SVProgressHUD showImage:[UIImage imageNamed:@"clearChatHistory"] status:NSLocalizedString(@"Chat History has Been Cleared", @"Message show when the history of a chat has been successfully deleted")];
            break;
        }
            
        default:
            break;
    }
}
#pragma mark - MEGAChatDelegate

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item {
    if (self.chatRoom.chatId == item.chatId) {
        self.chatRoom = [api chatRoomForChatId:item.chatId];
        MEGALogInfo(@"onChatListItemUpdate %@", item);
        
        switch (item.changes) {
            case MEGAChatListItemChangeTypeOwnPrivilege:
            case MEGAChatListItemChangeTypeParticipants:
                [self setParticipants];
                [self.tableView reloadData];
                [self updateHeadingView];
                break;
                
            case MEGAChatListItemChangeTypeTitle:
                [self updateHeadingView];
                break;
                
            case MEGAChatListItemChangeTypeClosed:
                [self.navigationController popToRootViewControllerAnimated:YES];
                break;
                
            case MEGAChatListItemChangeTypeUpdatePreviewers: {
                [self.tableView reloadData];
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress) {
        return;
    }
    
    if (userHandle != api.myUserHandle) {
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            GroupChatDetailsViewTableViewCell *cell = (GroupChatDetailsViewTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForChatStatus:onlineStatus];
        }
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    [self setParticipants];
    BOOL reloadData = NO;
    for (NSInteger i = 0 ; i < userList.size.integerValue; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        if (user.isOwnChange == 0) {
            reloadData = YES;
            break;
        }
    }
    if (reloadData) {
        [self.tableView reloadData];
    }
}

#pragma mark - ChatNotificationControlProtocol

- (void)pushNotificationSettingsLoaded {
    GroupChatDetailsViewTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:GroupChatDetailsSectionChatNotifications]];
    if (cell.controlSwitch != nil) {
        cell.controlSwitch.enabled = YES;
    }
}

@end
