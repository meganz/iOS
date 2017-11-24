
#import "ContactsViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIBarButtonItem+Badge.h"

#import "Helper.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveContactRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAUser+MNZCategory.h"
#import "NSMutableAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "ContactDetailsViewController.h"
#import "ContactTableViewCell.h"
#import "ShareFolderActivity.h"

@interface ContactsViewController () <ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *contactsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *contactsHeaderViewLabel;

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersArray;
@property (nonatomic, strong) NSMutableArray *outSharesForNodeMutableArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *contactRequestsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *groupBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addParticipantBarButtonItem;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *insertAnEmailBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareFolderWithBarButtonItem;
@property (strong, nonatomic) NSString *insertedEmail;

@property (nonatomic, strong) NSMutableDictionary *indexPathsMutableDictionary;

@property (nonatomic, strong) MEGAUser *userTapped;

@property (nonatomic) BOOL pendingRequestsPresented;

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.pendingRequestsPresented = NO;
    
    [self setupContacts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.contactsMode == ContactsModeDefault) {
        MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
        [self.contactRequestsBarButtonItem setBadgeValue:[NSString stringWithFormat:@"%d", incomingContactsLists.size.intValue]];
        if (@available(iOS 11.0, *)) {
            self.contactRequestsBarButtonItem.badgeOriginY = 0.0f;
        }
        if (!self.pendingRequestsPresented && incomingContactsLists.size.intValue > 0) {
            UINavigationController *contactRequestsNC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsNavigationControllerID"];
            [self presentViewController:contactRequestsNC animated:YES completion:nil];
            self.pendingRequestsPresented = YES;
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

#pragma mark - Private

- (void)setupContacts {
    self.indexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    
    [self.toolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 49)];
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            NSArray *buttonsItems = @[self.addBarButtonItem, self.contactRequestsBarButtonItem];
            self.navigationItem.rightBarButtonItems = buttonsItems;            
            break;
        }
            
        case ContactsModeShareFoldersWith: {
            [self updatePromptTitle];
            
            self.selectAllBarButtonItem.image =  nil;
            self.selectAllBarButtonItem.title = AMLocalizedString(@"selectAll", @"Select all items/elements on the list");
            [self.selectAllBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            self.navigationItem.leftBarButtonItem = self.selectAllBarButtonItem;
            
            self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", nil);
            [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem];
            
            self.insertAnEmailBarButtonItem.title = AMLocalizedString(@"addFromEmail", @"Item menu option to add a contact writting his/her email");
            [self.insertAnEmailBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            
            self.shareFolderWithBarButtonItem.title = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
            [self.shareFolderWithBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.navigationController.topViewController.toolbarItems = @[self.insertAnEmailBarButtonItem, flexibleItem, self.shareFolderWithBarButtonItem];
            [self.navigationController setToolbarHidden:NO];
            
            [self editTapped:self.editBarButtonItem];
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            negativeSpaceBarButtonItem.width = [[UIDevice currentDevice] iPadDevice] ? -8.0 : -4.0;
            NSArray *buttonsItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem];
            [self.navigationItem setRightBarButtonItems:buttonsItems];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.deleteBarButtonItem.title = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
            self.toolbar.items = @[flexibleItem, self.deleteBarButtonItem];
            break;
        }
            
        case ContactsModeChatStartConversation: {
            self.groupBarButtonItem.title = AMLocalizedString(@"group", @"Title of a menu button which allows users to start a conversation creating a 'Group' chat.");
            self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
            self.navigationItem.rightBarButtonItems = @[self.groupBarButtonItem];
            self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
            break;
        }
            
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant: {
            self.addParticipantBarButtonItem.title = AMLocalizedString(@"ok", nil);
            
            [self setTableViewEditing:YES animated:NO];
            self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
            self.navigationItem.rightBarButtonItems = @[self.addParticipantBarButtonItem];
            break;
        }
    }
}


- (void)reloadUI {
    [self setNavigationBarTitle];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    self.visibleUsersArray = [[NSMutableArray alloc] init];
    [self.indexPathsMutableDictionary removeAllObjects];
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        self.outSharesForNodeMutableArray = [self outSharesForNode:self.node];
        for (MEGAShare *share in self.outSharesForNodeMutableArray) {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[share user]];
            [self.visibleUsersArray addObject:user];
        }
    } else {
        self.users = [[MEGASdkManager sharedMEGASdk] contacts];
        NSInteger count = [[self.users size] integerValue];
        NSMutableArray *usersArray = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < count; i++) {
            MEGAUser *user = [self.users userAtIndex:i];
            if ([user visibility] == MEGAUserVisibilityVisible) {
                if (self.contactsMode == ContactsModeChatAddParticipant) {
                    if ([self.participantsMutableDictionary objectForKey:[NSNumber numberWithUnsignedLongLong:user.handle]] == nil) {
                        [usersArray addObject:user];
                    }
                } else {
                    [usersArray addObject:user];
                }
            }
        }
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"mnz_fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        self.visibleUsersArray = [usersArray sortedArrayUsingDescriptors:@[sort]];
    }
    
    if ([self.visibleUsersArray count] == 0) {
        [self.editBarButtonItem setEnabled:NO];
        self.addParticipantBarButtonItem.enabled = NO;
    } else {
        [self.editBarButtonItem setEnabled:YES];
        self.addParticipantBarButtonItem.enabled = YES;
    }
    
    [self.tableView reloadData];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    boolValue ? [self reloadUI] : [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.contactRequestsBarButtonItem setEnabled:boolValue];
    [self.addBarButtonItem setEnabled:boolValue];
    [self.editBarButtonItem setEnabled:boolValue];
}

- (NSMutableArray *)outSharesForNode:(MEGANode *)node {
    NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
    
    MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
    NSUInteger outSharesForNodeCount = [[outSharesForNodeShareList size] unsignedIntegerValue];
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if ([share user] != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    return outSharesForNodeMutableArray;
}

- (void)selectPermissionsFromButton:(UIBarButtonItem *)sourceButton {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *shareFolderAlertController = [self prepareShareFolderAlertController];
        
        if (sourceButton) {
            shareFolderAlertController.popoverPresentationController.barButtonItem = sourceButton;
        } else {
            shareFolderAlertController.popoverPresentationController.sourceRect = self.view.frame;
            shareFolderAlertController.popoverPresentationController.sourceView = self.view;
        }
        
        [self presentViewController:shareFolderAlertController animated:YES completion:nil];
    }
}

- (void)selectPermissionsFromCellRect:(CGRect)cellRect {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *shareFolderAlertController = [self prepareShareFolderAlertController];
        
        shareFolderAlertController.popoverPresentationController.sourceRect = cellRect;
        shareFolderAlertController.popoverPresentationController.sourceView = self.tableView;
        
        [self presentViewController:shareFolderAlertController animated:YES completion:nil];
    }
}

- (UIAlertController *)prepareShareFolderAlertController {
    UIAlertController *shareFolderAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"permissions", @"Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [shareFolderAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *fullAccessAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"fullAccess", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareNodesWithLevel:MEGAShareTypeAccessFull];
    }];
    [fullAccessAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [shareFolderAlertController addAction:fullAccessAlertAction];
    
    UIAlertAction *readAndWritetAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readAndWrite", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareNodesWithLevel:MEGAShareTypeAccessReadWrite];
    }];
    [readAndWritetAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [shareFolderAlertController addAction:readAndWritetAlertAction];
    
    UIAlertAction *readOnlyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareNodesWithLevel:MEGAShareTypeAccessRead];
    }];
    [readOnlyAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [shareFolderAlertController addAction:readOnlyAlertAction];
    
    shareFolderAlertController.modalPresentationStyle = UIModalPresentationPopover;
    
    return shareFolderAlertController;
}

- (void)shareNodesWithLevel:(MEGAShareType)shareType {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initWithNumberOfRequests:self.nodesArray.count completion:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        if (self.insertedEmail) {
            for (MEGANode *node in self.nodesArray) {
                [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:self.insertedEmail level:shareType delegate:shareRequestDelegate];
            }
            self.insertedEmail = nil;
        } else {
            for (MEGAUser *user in self.selectedUsersArray) {
                for (MEGANode *node in self.nodesArray) {
                    [[MEGASdkManager sharedMEGASdk] shareNode:node withUser:user level:shareType delegate:shareRequestDelegate];
                }
            }
        }
    } else if (self.contactsMode == ContactsModeFolderSharedWith) {
        void (^completion)(void);
        if (shareType == MEGAShareTypeAccessUnkown) {
            completion = ^{
                if ([self.selectedUsersArray count] == [self.visibleUsersArray count]) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                
                [self editTapped:self.editBarButtonItem];
            };
        } else {
            completion = ^{
                NSString *base64Handle = [MEGASdk base64HandleForUserHandle:self.userTapped.handle];
                NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
                if (indexPath != nil) {
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            };
        }
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:1 completion:completion];
        [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:self.userTapped level:shareType delegate:shareRequestDelegate];
    }
}

- (BOOL)userTypeHasChanged:(MEGAUser *)user {
    BOOL userHasChanged = NO;
    
    if ([user hasChangedType:MEGAUserChangeTypeAvatar]) {
        NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:userBase64Handle];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
        if (fileExists) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:avatarFilePath error:&error];
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
        userHasChanged = YES;
    } else if ([user hasChangedType:MEGAUserChangeTypeFirstname] || [user hasChangedType:MEGAUserChangeTypeLastname] || [user hasChangedType:MEGAUserChangeTypeEmail]) {
        userHasChanged = YES;
    }
    
    return  userHasChanged;
}

- (void)setNavigationBarTitle {
    [self updatePromptTitle];
    
    switch (self.contactsMode) {
        case ContactsModeDefault:
        case ContactsModeShareFoldersWith:
            self.navigationItem.title = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section");
            break;
            
        case ContactsModeFolderSharedWith:
            self.navigationItem.title = AMLocalizedString(@"sharedWith", @"Title of the view where you see with who you have shared a folder");
            break;
            
        case ContactsModeChatStartConversation:
            self.navigationItem.title = AMLocalizedString(@"startConversation", @"start a chat/conversation");
            break;
            
        case ContactsModeChatAddParticipant:
            self.navigationItem.title = AMLocalizedString(@"addParticipant", @"Button label. Allows to add contacts in current chat conversation.");
            break;
            
        case ContactsModeChatAttachParticipant:
            self.navigationItem.title = AMLocalizedString(@"sendContact", @"A button label. The button sends contact information to a user in the conversation.");
            break;
    }
}

- (void)updatePromptTitle {
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        NSString *promptString;
        NSNumber *selectedUsersCount = [NSNumber numberWithUnsignedInteger:self.selectedUsersArray.count];
        if (selectedUsersCount.unsignedIntegerValue == 0) {
            promptString = AMLocalizedString(@"select", @"Button that allows you to select a given folder");
        } else if (selectedUsersCount.unsignedIntegerValue == 1) {
            promptString = AMLocalizedString(@"oneContact", @"");
        } else {
            promptString = AMLocalizedString(@"XContactsSelected", @"[X] will be replaced by a plural number, indicating the total number of contacts the user has");
            promptString = [promptString stringByReplacingOccurrencesOfString:@"[X]" withString:selectedUsersCount.stringValue];
        }
        self.navigationItem.prompt = promptString;
    }
}

- (void)alertControllerShouldEnableDefaultButtonForEmailTextField:(UITextField *)sender {
    UIAlertController *addContactFromEmailAlertController = (UIAlertController *)self.presentedViewController;
    if (addContactFromEmailAlertController) {
        UITextField *textField = addContactFromEmailAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = addContactFromEmailAlertController.actions.lastObject;
        NSString *email = textField.text;
        rightButtonAction.enabled = (email.length > 0) ? [email mnz_isValidEmail] : NO;;
    }
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        [self.addBarButtonItem setEnabled:NO];
        
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.tabBar addSubview:self.toolbar];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        self.selectedUsersArray = nil;
        [self.addBarButtonItem setEnabled:YES];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
    
    if (!self.selectedUsersArray) {
        self.selectedUsersArray = [NSMutableArray new];
        [self.deleteBarButtonItem setEnabled:NO];
    }
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count != self.visibleUsersArray.count) {
        [self.selectedUsersArray removeAllObjects];
        
        MEGAUser *user = nil;
        for (NSInteger i = 0; i < self.visibleUsersArray.count; i++) {
            user = [self.visibleUsersArray objectAtIndex:i];
            [self.selectedUsersArray addObject:user];
        }
    } else {
        [self.selectedUsersArray removeAllObjects];
    }
    
    [self updatePromptTitle];
    
    self.deleteBarButtonItem.enabled = (self.selectedUsersArray.count == 0) ? NO : YES;
    
    [self.tableView reloadData];
}

- (IBAction)addContact:(UIButton *)sender {
    UIAlertController *addContactAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [addContactAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *addFromEmailAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addFromEmail", @"Item menu option to add a contact writting his/her email") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController *addContactFromEmailAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [addContactFromEmailAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = AMLocalizedString(@"contactEmail", @"Clue text to help the user know what should write there. In this case the contact email you want to add to your contacts list");
            [textField addTarget:self action:@selector(alertControllerShouldEnableDefaultButtonForEmailTextField:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [addContactFromEmailAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *addContactAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addContactButton", @"Button title to 'Add' the contact to your contacts list") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *textField = [[addContactFromEmailAlertController textFields] firstObject];
                MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
                [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:textField.text message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
                [addContactAlertController dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        addContactAlertAction.enabled = NO;
        [addContactFromEmailAlertController addAction:addContactAlertAction];
        
        [self presentViewController:addContactFromEmailAlertController animated:YES completion:nil];
    }];
    [addFromEmailAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [addContactAlertController addAction:addFromEmailAlertAction];
    
    UIAlertAction *addFromContactsAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addFromContacts", @"Item menu option to add a contact through your device app Contacts") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (self.presentedViewController != nil) {
            [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        }
        
        if (@available(iOS 9.0, *)) {
            CNContactPickerViewController *contactsPickerViewController = [[CNContactPickerViewController alloc] init];
            contactsPickerViewController.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
            contactsPickerViewController.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
            contactsPickerViewController.delegate = self;
            [self presentViewController:contactsPickerViewController animated:YES completion:nil];
        } else {
            ABPeoplePickerNavigationController *contactsPickerNC = [[ABPeoplePickerNavigationController alloc] init];
            contactsPickerNC.predicateForEnablingPerson = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
            contactsPickerNC.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
            contactsPickerNC.peoplePickerDelegate = self;
            [self presentViewController:contactsPickerNC animated:YES completion:nil];
        }
    }];
    [addFromContactsAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [addContactAlertController addAction:addFromContactsAlertAction];
    
    addContactAlertController.modalPresentationStyle = UIModalPresentationPopover;
    if (self.addBarButtonItem) {
        addContactAlertController.popoverPresentationController.barButtonItem = self.addBarButtonItem;
    } else {
        addContactAlertController.popoverPresentationController.sourceRect = sender.frame;
        addContactAlertController.popoverPresentationController.sourceView = sender.superview;
    }
    
    [self presentViewController:addContactAlertController animated:YES completion:nil];
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:self.selectedUsersArray.count completion:^{
            if ([self.selectedUsersArray count] == [self.visibleUsersArray count]) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self reloadUI];
            }
            
            [self setTableViewEditing:NO animated:YES];
        }];
        
        for (MEGAUser *user in self.selectedUsersArray) {
            [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:user level:MEGAShareTypeAccessUnkown delegate:shareRequestDelegate];
        }
    } else {
        NSString *message = (self.selectedUsersArray.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"removeMultipleUsersMessage", nil), self.selectedUsersArray.count] :[NSString stringWithFormat:AMLocalizedString(@"removeUserMessage", nil), [[self.selectedUsersArray objectAtIndex:0] email]];
        UIAlertController *removeUserAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts") message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [removeUserAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [removeUserAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                MEGARemoveContactRequestDelegate *removeContactRequestDelegate = [[MEGARemoveContactRequestDelegate alloc] initWithNumberOfRequests:self.selectedUsersArray.count completion:^{
                    [self setTableViewEditing:NO animated:NO];
                }];
                for (NSInteger i = 0; i < self.selectedUsersArray.count; i++) {
                    [[MEGASdkManager sharedMEGASdk] removeContactUser:[self.selectedUsersArray objectAtIndex:i] delegate:removeContactRequestDelegate];
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }]];
        
        [self presentViewController:removeUserAlertController animated:YES completion:nil];
    }
}

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    if (self.shareFolderActivity != nil) {
        [self.shareFolderActivity activityDidFinish:YES];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)backAction:(UIBarButtonItem *)sender {
    self.navigationItem.leftBarButtonItems = @[self.cancelBarButtonItem];
    self.groupBarButtonItem.title = AMLocalizedString(@"group", @"Title of a menu button which allows users to start a conversation creating a 'Group' chat.");
    self.groupBarButtonItem.enabled = YES;
    
    [self.tableView setEditing:NO animated:YES];
}

- (IBAction)shareFolderWithAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count == 0) {
        return;
    }
    
    [self selectPermissionsFromButton:self.shareFolderWithBarButtonItem];
}

- (IBAction)insertAnEmailAction:(UIBarButtonItem *)sender {
    UIAlertController *insertAnEmailToShareWithAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"shareFolder", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected, the folder you want inside your Cloud Drive") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [insertAnEmailToShareWithAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = AMLocalizedString(@"contactEmail", @"Clue text to help the user know what should write there. In this case the contact email you want to add to your contacts list");
        [textField addTarget:self action:@selector(alertControllerShouldEnableDefaultButtonForEmailTextField:) forControlEvents:UIControlEventEditingChanged];
        [self alertControllerShouldEnableDefaultButtonForEmailTextField:textField];
    }];
    
    [insertAnEmailToShareWithAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = [[insertAnEmailToShareWithAlertController textFields] firstObject];
            self.insertedEmail = textField.text;
            [self selectPermissionsFromButton:self.insertAnEmailBarButtonItem];
            [insertAnEmailToShareWithAlertController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [insertAnEmailToShareWithAlertController addAction:okAlertAction];
    okAlertAction.enabled = NO;
    
    [self presentViewController:insertAnEmailToShareWithAlertController animated:YES completion:nil];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        self.navigationItem.leftBarButtonItems = enableEditing ? @[self.selectAllBarButtonItem] : @[];
    }
    
    [self setTableViewEditing:enableEditing animated:YES];
}

- (IBAction)groupAction:(UIBarButtonItem *)sender {
    BOOL enableGroupMode = [self.groupBarButtonItem.title isEqualToString:AMLocalizedString(@"group", @"Title of a menu button which allows users to start a conversation creating a 'Group' chat.")];
    if (enableGroupMode) {
        self.selectedUsersArray = [[NSMutableArray alloc] init];
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem];
        self.groupBarButtonItem.title = AMLocalizedString(@"ok", nil);
        self.groupBarButtonItem.enabled = NO;
    } else {
        //Start Group Conversation
        if (self.selectedUsersArray.count > 0) {
            self.userSelected(self.selectedUsersArray);
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    [self.tableView setEditing:enableGroupMode animated:YES];
}

- (IBAction)addParticipantAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count > 0) {
        self.userSelected(self.selectedUsersArray);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        numberOfRows = [self.visibleUsersArray count];
    }
    
    if (numberOfRows == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
    [self.indexPathsMutableDictionary setObject:indexPath forKey:base64Handle];
    
    ContactTableViewCell *cell;
    NSString *userName = user.mnz_fullName;
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        if (userName) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsNameTableViewCellID" forIndexPath:indexPath];
            [cell.nameLabel setText:userName];
            cell.shareLabel.text = user.email;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsEmailTableViewCellID" forIndexPath:indexPath];
            cell.nameLabel.text = user.email;
        }
        MEGAShare *share = [self.outSharesForNodeMutableArray objectAtIndex:indexPath.row];
        [cell.permissionsImageView setImage:[Helper permissionsButtonImageForShareType:share.access]];
    } else if (self.contactsMode >= ContactsModeChatStartConversation) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
        
        cell.nameLabel.text = userName ? userName : user.email;
        cell.shareLabel.text = user.email;
        
        cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:user.handle]];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
        cell.nameLabel.text = userName ? userName : user.email;
        
        cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:user.handle]];
        
        int numFilesShares = [[[[MEGASdkManager sharedMEGASdk] inSharesForUser:user] size] intValue];
        if (numFilesShares == 0) {
            cell.shareLabel.text = AMLocalizedString(@"noFoldersShared", @"No folders shared");
        } else  if (numFilesShares == 1 ) {
            cell.shareLabel.text = AMLocalizedString(@"oneFolderShared", @" folder shared");
        } else {
            cell.shareLabel.text = [NSString stringWithFormat:AMLocalizedString(@"foldersShared", @" folders shared"), numFilesShares];
        }
    }
    
    [cell.avatarImageView mnz_setImageForUserHandle:user.handle];
    
    if (self.tableView.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGAUser *u in self.selectedUsersArray) {
            if ([[u email] isEqualToString:[user email]]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    
    cell.separatorInset = (self.tableView.isEditing) ? UIEdgeInsetsMake(0.0, 96.0, 0.0, 0.0) : UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
    
    if (@available(iOS 11.0, *)) {
        cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && (self.contactsMode >= ContactsModeChatStartConversation)) {
        if (self.visibleUsersArray.count == 0) {
            return nil;
        }
        
        self.contactsHeaderViewLabel.text = [AMLocalizedString(@"contactsTitle", @"Title of the Contacts section") uppercaseString];
        return self.contactsHeaderView;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat heightForHeader = 0.0f;
    if (section == 0 && (self.contactsMode >= ContactsModeChatStartConversation)) {
        if (self.visibleUsersArray.count == 0) {
            return heightForHeader;
        }
        
        heightForHeader = 23.0f;
    }
    
    return heightForHeader;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    if (!user) {
        [SVProgressHUD showErrorWithStatus:@"Invalid user"];
        return;
    }
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
            contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
            contactDetailsVC.userEmail = user.email;
            contactDetailsVC.userName = user.mnz_fullName;
            contactDetailsVC.userHandle = user.handle;
            [self.navigationController pushViewController:contactDetailsVC animated:YES];
            break;
        }
            
        case ContactsModeShareFoldersWith:
            if (tableView.isEditing) {
                [self.selectedUsersArray addObject:user];
                [self updatePromptTitle];
                return;
            }
            break;
            
        case ContactsModeFolderSharedWith:
            if (tableView.isEditing) {
                [self.selectedUsersArray addObject:user];
                self.deleteBarButtonItem.enabled = (self.selectedUsersArray.count > 0);
                return;
            }
            
            self.userTapped = user;
            CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
            [self selectPermissionsFromCellRect:cellRect];
            break;
            
        case ContactsModeChatStartConversation: {
            if (tableView.isEditing) {
                [self.selectedUsersArray addObject:user];
                self.groupBarButtonItem.enabled = (self.selectedUsersArray.count > 0);
                return;
            }
            
            self.userSelected(@[user]);
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant:
            if (tableView.isEditing) {
                [self.selectedUsersArray addObject:user];
                return;
            }
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = [self.selectedUsersArray copy];
        for (MEGAUser *u in tempArray) {
            if ([u.email isEqualToString:user.email]) {
                [self.selectedUsersArray removeObject:u];
            }
        }
        
        [self updatePromptTitle];
        
        if (self.selectedUsersArray.count == 0) {
            if (self.contactsMode != ContactsModeChatStartConversation) {
                [self.deleteBarButtonItem setEnabled:NO];
            } else {
                self.groupBarButtonItem.enabled = NO;
            }
        }
        
        return;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.contactsMode == ContactsModeDefault || self.contactsMode == ContactsModeFolderSharedWith) {
        return;
    }
    
    [self setTableViewEditing:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setTableViewEditing:NO animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.contactsMode == ContactsModeChatStartConversation) {
        return UITableViewCellEditingStyleNone;
    }
    
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    
    self.selectedUsersArray = [NSMutableArray new];
    [self.selectedUsersArray addObject:user];
    
    [self.deleteBarButtonItem setEnabled:YES];
    
    return (UITableViewCellEditingStyleDelete);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        switch (self.contactsMode) {
            case ContactsModeDefault: {
                MEGARemoveContactRequestDelegate *removeContactRequestDelegate = [[MEGARemoveContactRequestDelegate alloc] initWithNumberOfRequests:1 completion:^{
                    [self setTableViewEditing:NO animated:NO];
                }];
                MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
                [[MEGASdkManager sharedMEGASdk] removeContactUser:user delegate:removeContactRequestDelegate];
                break;
            }
                
            case ContactsModeShareFoldersWith:
                break;
                
            case ContactsModeFolderSharedWith: {
                [self deleteAction:self.deleteBarButtonItem];
                break;
            }
                
            default:
                break;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *titleForDeleteConfirmationButton;
    switch (self.contactsMode) {
        case ContactsModeShareFoldersWith:
        case ContactsModeChatStartConversation:
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant:
            titleForDeleteConfirmationButton = @"";
            break;
        
        case ContactsModeDefault:
        case ContactsModeFolderSharedWith:
            titleForDeleteConfirmationButton = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
            break;
    }
    
    return titleForDeleteConfirmationButton;
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person {
    
    NSString *email = nil;
    ABMultiValueRef emails = ABRecordCopyValue(person,
                                                     kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 0) {
        email = (__bridge_transfer NSString*)
        ABMultiValueCopyValueAtIndex(emails, 0);
    }

    if (email) {
        MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
    } else {
        UIAlertController *contactHasNoEmailAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"contactWithoutEmail", @"Alert title shown when you add a contact from your device and the selected one doesn't have an email.") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [contactHasNoEmailAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:contactHasNoEmailAlertController animated:YES completion:nil];
    }
    
    if (emails) {
        CFRelease(emails);
    }
}

#pragma mark - CNContactPickerDelegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperties:(NSArray<CNContactProperty*> *)contactProperties {
    NSUInteger usersCount = contactProperties.count;
    MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:usersCount];
    for (CNContactProperty *contactProperty in contactProperties) {
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:contactProperty.value message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.") sectionTitle:AMLocalizedString(@"contactsTitle", @"Title of My Contacts section")];
        
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
   NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        return [UIImage imageNamed:@"emptyContacts"];
    } else {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    if (self.contactsMode >= ContactsModeChatAddParticipant) {
        return nil;
    }
    
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        text = AMLocalizedString(@"addContacts", nil);
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

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    [self addContact:button];
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    BOOL userAdded = NO;
    
    NSMutableArray *updateContactsIndexPathMutableArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *deleteContactsIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    NSInteger count = userList.size.integerValue;
    for (NSInteger i = 0 ; i < count; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
        if (([user handle] == [[[MEGASdkManager sharedMEGASdk] myUser] handle]) && (user.isOwnChange != 0)) {
            continue;
        } else if (user.isOwnChange == 0) { //If the change is external, update the modified contacts
            switch (user.visibility) {
                case MEGAUserVisibilityHidden: { //If I deleted a contact
                    if (indexPath != nil) {
                        [deleteContactsIndexPathMutableDictionary setObject:user forKey:indexPath];
                    }
                    continue;
                }
                    
                case MEGAUserVisibilityVisible: {
                    if (indexPath == nil) {
                        userAdded = YES;
                    }
                    break;
                }
                    
                default:
                    break;
            }
            
            BOOL userHasChanged = [self userTypeHasChanged:user];
            if (userHasChanged && (indexPath != nil)) {
                [updateContactsIndexPathMutableArray addObject:indexPath];
            }
        } else if (user.isOwnChange != 0) { //If the change is internal
            if (user.visibility != MEGAUserVisibilityVisible) { //If I deleted a contact
                if (indexPath != nil) {
                    [deleteContactsIndexPathMutableDictionary setObject:user forKey:indexPath];
                }
            } else {
                if ((user.visibility == MEGAUserVisibilityVisible) && (indexPath == nil)) { //If someone has accepted me as contact
                    userAdded = YES;
                }
                continue;
            }
        }
    }
    
    if (userAdded) {
        [self reloadUI];
    } else {
        if (updateContactsIndexPathMutableArray.count != 0) {
            [self.tableView reloadRowsAtIndexPaths:updateContactsIndexPathMutableArray withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        NSArray *deleteContactsOnIndexPathsArray = [deleteContactsIndexPathMutableDictionary allKeys];
        if (deleteContactsOnIndexPathsArray.count != 0) {
            for (NSIndexPath *indexPath in deleteContactsOnIndexPathsArray) {
                [self.visibleUsersArray removeObjectAtIndex:indexPath.row];
                MEGAUser *userToDelete = [deleteContactsIndexPathMutableDictionary objectForKey:indexPath];
                NSString *userToDeleteBase64Handle = [MEGASdk base64HandleForUserHandle:userToDelete.handle];
                [self.indexPathsMutableDictionary removeObjectForKey:userToDeleteBase64Handle];
            }
            [self.tableView deleteRowsAtIndexPaths:deleteContactsOnIndexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
    self.contactRequestsBarButtonItem.badgeValue = [NSString stringWithFormat:@"%d", incomingContactsLists.size.intValue];
    if (@available(iOS 11.0, *)) {
        self.contactRequestsBarButtonItem.badgeOriginY = 0.0f;
    }
}

@end
