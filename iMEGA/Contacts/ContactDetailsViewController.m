#import "ContactDetailsViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "UIImageView+MNZCategory.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGARemoveContactRequestDelegate.h"
#import "MEGAChatCreateChatGroupRequestDelegate.h"

#import "BrowserViewController.h"
#import "CloudDriveTableViewController.h"
#import "ChatRoomsViewController.h"
#import "CustomActionViewController.h"
#import "ContactTableViewCell.h"
#import "DisplayMode.h"
#import "MessagesViewController.h"
#import "NodeInfoViewController.h"
#import "SharedItemsTableViewCell.h"
#import "VerifyCredentialsViewController.h"

@interface ContactDetailsViewController () <CustomActionViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *backBarButtonItem;

@property (strong, nonatomic) IBOutlet UIView *emptyHeaderView;
@property (strong, nonatomic) IBOutlet UIView *participantsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *participantsHeaderViewLabel;

@property (strong, nonatomic) IBOutlet UIView *actionsSectionEmptyFooterView;
@property (strong, nonatomic) IBOutlet UIView *sharedFoldersEmptyFooterView;

@property (nonatomic, strong) MEGAUser *user;
@property (nonatomic, strong) MEGANodeList *incomingNodeListForUser;

@end

@implementation ContactDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.backBarButtonItem;
    self.navigationItem.title = AMLocalizedString(@"contactInfo", @"title of the contact properties screen");
    
    self.user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.userEmail];
    [self.avatarImageView mnz_setImageForUserHandle:self.user.handle];
    
    //TODO: Show the blue check if the Contact is verified
    
    self.nameLabel.text = self.userName;
    self.emailLabel.text = self.userEmail;
    
    self.emptyHeaderView = [[[NSBundle mainBundle] loadNibNamed:@"EmptyHeaderView" owner:self options:nil] firstObject];
    self.actionsSectionEmptyFooterView = [[[NSBundle mainBundle] loadNibNamed:@"EmptyFooterView" owner:self options:nil] firstObject];
    self.sharedFoldersEmptyFooterView = [[[NSBundle mainBundle] loadNibNamed:@"EmptyFooterView" owner:self options:nil] firstObject];
    
    self.incomingNodeListForUser = [[MEGASdkManager sharedMEGASdk] inSharesForUser:self.user];
    
    if (@available(iOS 11.0, *)) {
        self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)showClearChatHistoryAlert {
    UIAlertController *clearChatHistoryAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.") message:AMLocalizedString(@"clearTheFullMessageHistory", @"A confirmation message for a user to confirm that they want to clear the history of a chat.") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"continue", @"'Next' button in a dialog") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[MEGASdkManager sharedMEGAChatSdk] clearChatHistory:self.chatId];
    }];
    
    [clearChatHistoryAlertController addAction:cancelAction];
    [clearChatHistoryAlertController addAction:continueAction];
    
    [self presentViewController:clearChatHistoryAlertController animated:YES completion:nil];
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

- (void)pushVerifyCredentialsViewController {
    VerifyCredentialsViewController *verifyCredentialsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"VerifyCredentialsViewControllerID"];
    [self.navigationController pushViewController:verifyCredentialsVC animated:YES];
}

- (void)changeToChatTabAndOpenChatId:(uint64_t)chatId {
    MEGAChatRoom *chatRoom             = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatId];
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    messagesVC.chatRoom                = chatRoom;
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:messagesVC];
    [self presentViewController:navigationController animated:YES completion:^{
        NSUInteger chatTabPosition = 2;
        self.tabBarController.selectedIndex = chatTabPosition;
    }];
}

#pragma mark - IBActions

- (IBAction)backAction:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.incomingNodeListForUser.size.integerValue == 0) {
        return 1;
    }
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (section == 0) {
        if (self.contactDetailsMode == ContactDetailsModeDefault) {
            //TODO: When possible, re-add the rows "Notifications" and "Verify Credentials".
            numberOfRows = 2;
        } else if (self.contactDetailsMode == ContactDetailsModeFromChat) {
            //TODO: When possible, re-add the rows "Notifications", "Close Chat" and "Verify Credentials".
            if (self.user.visibility == MEGAUserVisibilityHidden) {
                numberOfRows = 1;
            } else {
                numberOfRows = 2;
            }
            
        }
    } else if (section == 1) { //SHARED FOLDERS
        numberOfRows = self.incomingNodeListForUser.size.integerValue;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
        
        if (self.contactDetailsMode == ContactDetailsModeDefault) {
            switch (indexPath.row) {
                case 0: //Send Message
                    cell.nameLabel.text = AMLocalizedString(@"sendMessage", @"Title to perform the action of sending a message to a contact.");
                    break;
                    
                case 1: //Remove Contact
                    cell.avatarImageView.image = [UIImage imageNamed:@"delete"];
                    cell.nameLabel.text = AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts");
                    cell.nameLabel.font = [UIFont mnz_SFUIRegularWithSize:15.0f];
                    cell.nameLabel.textColor = [UIColor mnz_redF0373A];
                    cell.lineView.hidden = YES;
                    break;
            }
        } else if (self.contactDetailsMode == ContactDetailsModeFromChat) {
            switch (indexPath.row) {
                case 0: //Clear Chat History
                    cell.avatarImageView.image = [UIImage imageNamed:@"clearChatHistory"];
                    cell.nameLabel.text = AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.");
                    break;
                    
                case 1: //Remove Contact
                    cell.avatarImageView.image = [UIImage imageNamed:@"delete"];
                    cell.nameLabel.text = AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts");
                    cell.nameLabel.textColor = [UIColor mnz_redF0373A];
                    cell.lineView.hidden = YES;
                    break;
            }
            cell.nameLabel.font = [UIFont mnz_SFUIRegularWithSize:15.0f];
        }
    } else if (indexPath.section == 1) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsSharedFolderTypeID" forIndexPath:indexPath];
        MEGANode *node = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
        cell.avatarImageView.image = [Helper incomingFolderImage];
        cell.nameLabel.text = node.name;
        cell.shareLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
        cell.permissionsImageView.image = [Helper permissionsButtonImageForShareType:shareType];
        
        if ((self.incomingNodeListForUser.size.integerValue - 1) == indexPath.row) {
            cell.lineView.hidden = YES;
        }
    }
    
    if (@available(iOS 11.0, *)) {
        cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return self.emptyHeaderView;
    }
    
    if (section == 1) {
        self.participantsHeaderViewLabel.text = [AMLocalizedString(@"sharedFolders", @"Title of the incoming shared folders of a user.") uppercaseString];
        return self.participantsHeaderView;
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return self.actionsSectionEmptyFooterView;
    }
    
    if (section == 1) {
        return self.sharedFoldersEmptyFooterView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 48.0f;
    }
    
    if (section == 1) {
        return 24.0f;
    }
    
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 24.0f;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow;
    switch (indexPath.section) {
        case 0:
            heightForRow = 44.0f;
            break;
            
        case 1:
            heightForRow = 60.0f;
            break;
            
        default:
            heightForRow = 0.0f;
            break;
    }
    
    return heightForRow;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.contactDetailsMode == ContactDetailsModeDefault) {
            switch (indexPath.row) {
                case 0: { //Send Message
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
                        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:self.userHandle];
                        if (chatRoom) {
                            [self changeToChatTabAndOpenChatId:chatRoom.chatId];
                        } else {
                            MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
                            [peerList addPeerWithHandle:self.userHandle privilege:MEGAChatRoomPrivilegeStandard];
                            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                                [self changeToChatTabAndOpenChatId:chatRoom.chatId];
                            }];
                            [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
                        }
                    } else {
                        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"chatIsDisabled", @"Title show when the chat is disabled")];
                    }
                    break;
                }
                    
                case 1: //Remove Contact
                    [self showRemoveContactAlert];
                    break;
            }
        } else if (self.contactDetailsMode == ContactDetailsModeFromChat) {
            switch (indexPath.row) {
                case 0: //Clear Chat History
                    [self showClearChatHistoryAlert];
                    break;
                    
                case 1: //Remove Contact
                    [self showRemoveContactAlert];
                    break;
            }
        }
    } else if (indexPath.section == 1) { //Show incoming shared folder contents
        CloudDriveTableViewController *cloudTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        MEGANode *incomingNode = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
        cloudTVC.parentNode = incomingNode;
        cloudTVC.displayMode = DisplayModeCloudDrive;
        [self.navigationController pushViewController:cloudTVC animated:YES];
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
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            [self presentViewController:navigationController animated:YES completion:nil];
            
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            browserVC.selectedNodesArray = @[node];
            browserVC.browserAction = BrowserActionCopy;
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

@end
