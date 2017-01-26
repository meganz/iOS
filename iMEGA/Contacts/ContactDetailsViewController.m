#import "ContactDetailsViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAUser+MNZCategory.h"

#import "ContactTableViewCell.h"
#import "DetailsNodeInfoViewController.h"
#import "SharedItemsTableViewCell.h"
#import "VerifyCredentialsViewController.h"

@interface ContactDetailsViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *participantsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *participantsHeaderViewLabel;

@property (nonatomic, strong) MEGAUser *user;
@property (nonatomic, strong) MEGANodeList *incomingNodeListForUser;

@end

@implementation ContactDetailsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"contactInfo", @"title of the contact properties screen");
    
    self.user = [[MEGASdkManager sharedMEGASdk] contactForEmail:self.userEmail];
    [self.avatarImageView mnz_setImageForUserHandle:self.user.handle];
    
    //TODO: Show the blue check if the Contact is verified
    
    self.nameLabel.text = self.userName;
    self.emailLabel.text = self.userEmail;
    
    self.incomingNodeListForUser = [[MEGASdkManager sharedMEGASdk] inSharesForUser:self.user];
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
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
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
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[MEGASdkManager sharedMEGASdk] removeContactUser:self.user delegate:self];
    }];
    
    [removeContactAlertController addAction:cancelAction];
    [removeContactAlertController addAction:okAction];
    
    [self presentViewController:removeContactAlertController animated:YES completion:nil];
}

- (void)pushVerifyCredentialsViewController {
    VerifyCredentialsViewController *verifyCredentialsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"VerifyCredentialsViewControllerID"];
    [self.navigationController pushViewController:verifyCredentialsVC animated:YES];
}

#pragma mark - IBActions

- (IBAction)notificationsSwitchValueChanged:(UISwitch *)sender {
    
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
    
    DetailsNodeInfoViewController *detailsNodeInfoVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
    detailsNodeInfoVC.displayMode = DisplayModeSharedItem;
    detailsNodeInfoVC.userName = self.userName;
    detailsNodeInfoVC.email = self.userEmail;
    detailsNodeInfoVC.node = node;
    
    [self.navigationController pushViewController:detailsNodeInfoVC animated:YES];
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
            numberOfRows = 4;
        } else if (self.contactDetailsMode == ContactDetailsModeFromChat) {
            numberOfRows = 5;
        }
    } else if (section == 1) { //SHARED FOLDERS
        numberOfRows = self.incomingNodeListForUser.size.integerValue;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsNotificationsTypeID" forIndexPath:indexPath];
        } else {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsDefaultTypeID" forIndexPath:indexPath];
            
            NSInteger redRowsFrom = (self.contactDetailsMode == ContactDetailsModeDefault) ? 3 : 2;
            if (indexPath.row > redRowsFrom) {
                cell.nameLabel.font = [UIFont fontWithName:@"SFUIText-Regular" size:17.0];
                cell.nameLabel.textColor = [UIColor mnz_redD90007];
            }
        }
        
        if (self.contactDetailsMode == ContactDetailsModeDefault) {
            switch (indexPath.row) {
                case 0: //Notifications
                    cell.nameLabel.text = AMLocalizedString(@"notifications", nil);
                    break;
                    
                case 1: //Send Message
                    cell.nameLabel.text = AMLocalizedString(@"sendMessage", @"Title to perform the action of sending a message to a contact.");
                    break;
                    
                case 2: //Verify Credentials
                    cell.nameLabel.text = AMLocalizedString(@"verifyCredentials", @"Title for a section on the fingerprint warning dialog. Below it is a button which will allow the user to verify their contact's fingerprint credentials.");
                    break;
                    
                case 3: //Remove User
                    cell.nameLabel.text = AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts");
                    break;
            }
        } else if (self.contactDetailsMode == ContactDetailsModeFromChat) {
            switch (indexPath.row) {
                case 0: //Notifications
                    cell.nameLabel.text = AMLocalizedString(@"notifications", nil);
                    break;
                    
                case 1: //Verify Credentials
                    cell.nameLabel.text = AMLocalizedString(@"verifyCredentials", @"Title for a section on the fingerprint warning dialog. Below it is a button which will allow the user to verify their contact's fingerprint credentials.");
                    break;
                    
                case 2: //Clear Chat History
                    cell.nameLabel.text = AMLocalizedString(@"clearChatHistory", @"A button title to delete the history of a chat.");
                    break;
                
                case 3: //Close Chat
                    cell.nameLabel.text = AMLocalizedString(@"closeChat", @"Button title that allows the user to close a chat.");
                    break;
                    
                case 4: //Remove Contact
                    cell.nameLabel.text = AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts");
                    break;
            }
        }
    } else if (indexPath.section == 1) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactDetailsSharedFolderTypeID" forIndexPath:indexPath];
        MEGANode *node = [self.incomingNodeListForUser nodeAtIndex:indexPath.row];
        cell.avatarImageView.image = [Helper incomingFolderImage];
        cell.nameLabel.text = node.name;
        cell.shareLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
        cell.permissionsImageView.image = [Helper permissionsButtonImageForShareType:shareType];
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        self.participantsHeaderViewLabel.text = [AMLocalizedString(@"sharedFolders", @"Title of the incoming shared folders of a user.") uppercaseString];
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
        if (self.contactDetailsMode == ContactDetailsModeDefault) {
            switch (indexPath.row) {
                case 0: //Notifications
                    break;
                    
                case 1: { //Send Message
                    //TODO: If there's a chat with this contact, open it. If not, start conversation.
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TO-DO" message:@"🔜🤓💻📱" preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    break;
                }
                    
                case 2: //Verify Credentials
                    [self pushVerifyCredentialsViewController];
                    break;
                    
                case 3: //Remove Contact
                    [self showRemoveContactAlert];
                    break;
            }
        } else if (self.contactDetailsMode == ContactDetailsModeFromChat) {
            switch (indexPath.row) {
                case 0: //Notifications
                    break;
                    
                case 1: //Verify Credentials
                    [self pushVerifyCredentialsViewController];
                    break;
                    
                case 2: //Clear Chat History
                    [self showClearChatHistoryAlert];
                    break;
                    
                case 3: //Close Chat
                    //TODO: Close chat
                    break;
                    
                case 4: //Remove Contact
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


#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeRemoveContact: {
            NSString *message = [NSString stringWithFormat:AMLocalizedString(@"removedContact", nil), [request email]];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
            
            //TODO: Close chat room because the contact was removed
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
