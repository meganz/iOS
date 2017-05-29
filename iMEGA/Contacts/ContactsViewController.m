#import "ContactsViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIBarButtonItem+Badge.h"
#import "UIImageView+MNZCategory.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "Helper.h"
#import "NSMutableAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "MEGAUser+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactDetailsViewController.h"
#import "ContactTableViewCell.h"

#import "ShareFolderActivity.h"


@interface ContactsViewController () <ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAGlobalDelegate> {
    UIAlertView *removeAlertView;
    
    NSUInteger remainingOperations;
    
    BOOL allUsersSelected;
    BOOL isSwipeEditing;
    
    MEGAUser *userTapped;
}

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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *insertAnEmailBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareFolderWithBarButtonItem;
@property (strong, nonatomic) NSString *email;

@property (nonatomic, strong) NSMutableDictionary *indexPathsMutableDictionary;

@property (nonatomic) BOOL addingMoreThanOneContact;

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.toolbar setFrame:CGRectMake(0, 49, CGRectGetWidth(self.view.frame), 49)];
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhone6XPlus]) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    
    [self.deleteBarButtonItem setTitle:AMLocalizedString(@"remove", nil)];
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            NSArray *buttonsItems = @[negativeSpaceBarButtonItem, self.addBarButtonItem, self.contactRequestsBarButtonItem];
            self.navigationItem.rightBarButtonItems = buttonsItems;
            
            [self.shareFolderBarButtonItem setTitle:AMLocalizedString(@"shareFolder", nil)];
            break;
        }
        
        case ContactsModeShareFoldersWith: {
            [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
            [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            
            self.navigationItem.leftBarButtonItems = @[self.cancelBarButtonItem];
            
            self.shareFolderWithBarButtonItem.title = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
            [self.shareFolderWithBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItems = @[self.shareFolderWithBarButtonItem];
            
            [_insertAnEmailBarButtonItem setTitle:AMLocalizedString(@"addFromEmail", nil)];
            [self.insertAnEmailBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            
            self.selectAllBarButtonItem.image =  nil;
            self.selectAllBarButtonItem.title = AMLocalizedString(@"selectAll", @"Select all items/elements on the list");
            [self.selectAllBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.navigationController.topViewController.toolbarItems = @[self.selectAllBarButtonItem, flexibleItem, self.insertAnEmailBarButtonItem];
            [self.navigationController setToolbarHidden:NO];
            
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            NSArray *buttonsItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem];
            [self.navigationItem setRightBarButtonItems:buttonsItems];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [_toolbar setItems:@[flexibleItem, _deleteBarButtonItem]];
            
            break;
        }
            
        case ContactsModeChatStartConversation: {
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
            
        default:
            break;
    }
    
    self.indexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        self.navigationItem.title = AMLocalizedString(@"select", @"Button that allows you to select a given folder");
    } else if (self.contactsMode == ContactsModeFolderSharedWith) {
        [self.navigationItem setTitle:AMLocalizedString(@"sharedWith", nil)];
    } else if (self.contactsMode == ContactsModeChatStartConversation) {
        [self.navigationItem setTitle:AMLocalizedString(@"startConversation", @"start a chat/conversation")];
    } else if (self.contactsMode == ContactsModeChatAddParticipant) {
        self.navigationItem.title = AMLocalizedString(@"addParticipant", @"Button label. Allows to add contacts in current chat conversation.");
    } else if (self.contactsMode == ContactsModeChatAttachParticipant) {
        self.navigationItem.title = AMLocalizedString(@"sendContact", @"A button label. The button sends contact information to a user in the conversation.");
    } else {
        [self.navigationItem setTitle:AMLocalizedString(@"contactsTitle", nil)];
    }
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        [self editTapped:_editBarButtonItem];
    }
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.tableView isEditing]) {
        [self setEditing:NO animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.contactsMode == ContactsModeDefault) {
        MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
        [self.contactRequestsBarButtonItem setBadgeValue:[NSString stringWithFormat:@"%d", incomingContactsLists.size.intValue]];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (self.contactsMode == ContactsModeChatStartConversation) {
        if (editing) {
        } else {
            self.selectedUsersArray = [[NSMutableArray alloc] init];
        }
        
        if (!self.selectedUsersArray) {
            self.selectedUsersArray = [[NSMutableArray alloc] init];
        }
        
    } else {
        if (editing) {
            [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
            [self.addBarButtonItem setEnabled:NO];
            if (!isSwipeEditing) {
                if (self.contactsMode != ContactsModeShareFoldersWith) {
                    self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
                }
            }
        } else {
            [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
            allUsersSelected = NO;
            self.selectedUsersArray = nil;
            [self.addBarButtonItem setEnabled:YES];
            if (self.contactsMode != ContactsModeShareFoldersWith) {
                self.navigationItem.leftBarButtonItems = @[];
            }
        }
        
        if (!self.selectedUsersArray) {
            self.selectedUsersArray = [NSMutableArray new];
            [self.deleteBarButtonItem setEnabled:NO];
            [self.shareFolderBarButtonItem setEnabled:NO];
        }
        
        [self.tabBarController.tabBar addSubview:self.toolbar];
        
        [UIView animateWithDuration:animated ? .33 : 0 animations:^{
            self.toolbar.frame = CGRectMake(0, editing ? 0 : 49 , CGRectGetWidth(self.view.frame), 49);
        }];
    }
    
    isSwipeEditing = NO;
}

#pragma mark - Private

- (void)reloadUI {
    self.visibleUsersArray = [[NSMutableArray alloc] init];
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        _outSharesForNodeMutableArray = [self outSharesForNode:self.node];
        for (MEGAShare *share in _outSharesForNodeMutableArray) {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[share user]];
            [self.visibleUsersArray addObject:user];
        }
    } else {
        self.users = [[MEGASdkManager sharedMEGASdk] contacts];
        NSInteger count = [[self.users size] integerValue];
        for (NSInteger i = 0; i < count; i++) {
            MEGAUser *user = [self.users userAtIndex:i];
            if ([user visibility] == MEGAUserVisibilityVisible) {
                if (self.contactsMode == ContactsModeChatAddParticipant) {
                    if ([self.participantsMutableDictionary objectForKey:[NSNumber numberWithUnsignedLongLong:user.handle]] == nil) {
                        [self.visibleUsersArray addObject:user];
                    }
                } else {
                    [self.visibleUsersArray addObject:user];
                }
            }
        }
    }
    
    if ([self.visibleUsersArray count] == 0) {
        [_editBarButtonItem setEnabled:NO];
        self.addParticipantBarButtonItem.enabled = NO;
    } else {
        [_editBarButtonItem setEnabled:YES];
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

- (void)selectPermissions {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:AMLocalizedString(@"permissions", nil)
                                                             delegate:self
                                                    cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:AMLocalizedString(@"readOnly", nil), AMLocalizedString(@"readAndWrite", nil), AMLocalizedString(@"fullAccess", nil), nil];
    [actionSheet setTag:1];
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        [actionSheet showInView:self.view];
    } else {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

- (void)shareFolder {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self selectPermissions];
    }
}

- (BOOL)userTypeHasChanged:(MEGAUser *)user {
    BOOL userHasChanged = NO;
    
    if ([user hasChangedType:MEGAUserChangeTypeAvatar]) {
        NSString *avatarFilePath = [Helper pathForUser:user searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
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

- (void)updateNavigationBarTitle {
    NSNumber *selectedUsersCount = [NSNumber numberWithUnsignedInteger:self.selectedUsersArray.count];
    
    NSString *navigationTitle;
    if (selectedUsersCount.unsignedIntegerValue == 0) {
        navigationTitle = AMLocalizedString(@"select", @"Button that allows you to select a given folder");
    } else if (selectedUsersCount.unsignedIntegerValue == 1) {
        navigationTitle = AMLocalizedString(@"oneContact", @"");
    } else {
        navigationTitle = AMLocalizedString(@"XContactsSelected", @"[X] will be replaced by a plural number, indicating the total number of contacts the user has");
        navigationTitle = [navigationTitle stringByReplacingOccurrencesOfString:@"[X]" withString:selectedUsersCount.stringValue];
    }
    self.navigationItem.title = navigationTitle;
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedUsersArray removeAllObjects];
    
    if (!allUsersSelected) {
        MEGAUser *u = nil;
        
        for (NSInteger i = 0; i < [self.visibleUsersArray count]; i++) {
            u = [self.visibleUsersArray objectAtIndex:i];
            [self.selectedUsersArray addObject:u];
        }
        
        allUsersSelected = YES;
    } else {
        allUsersSelected = NO;
    }
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        [self updateNavigationBarTitle];
    }
    
    if (self.selectedUsersArray.count == 0) {
        [self.deleteBarButtonItem setEnabled:NO];
        [self.shareFolderBarButtonItem setEnabled:NO];
        
    } else {
        [self.deleteBarButtonItem setEnabled:YES];
        [self.shareFolderBarButtonItem setEnabled:YES];
    }
    
    [self.tableView reloadData];
    
}

- (IBAction)addContact:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:AMLocalizedString(@"addFromEmail", nil), AMLocalizedString(@"addFromContacts", nil), nil];
    [actionSheet setTag:0];
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        [actionSheet showFromBarButtonItem:self.addBarButtonItem animated:YES];
    } else {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        remainingOperations = [self.selectedUsersArray count];
        for (MEGAUser *user in self.selectedUsersArray) {
            [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:user level:MEGAShareTypeAccessUnkown delegate:self];
        }
    } else {
        NSString *message = (self.selectedUsersArray.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"removeMultipleUsersMessage", nil), self.selectedUsersArray.count] :[NSString stringWithFormat:AMLocalizedString(@"removeUserMessage", nil), [[self.selectedUsersArray objectAtIndex:0] email]];
        
        removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeUserTitle", @"Remove user") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        [removeAlertView show];
        removeAlertView.tag = 1;
        [removeAlertView show];
    }
}

- (IBAction)shareFolderAction:(UIBarButtonItem *)sender {
    UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    MEGANavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
    [browserVC setSelectedUsersArray:self.selectedUsersArray];
    [browserVC setBrowserAction:BrowserActionSelectFolderToShare];
    
    [self setTableViewEditing:NO animated:YES];
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
    
    [self setTableViewEditing:NO animated:YES];
}

- (IBAction)shareFolderWithAction:(UIBarButtonItem *)sender {
    if (_selectedUsersArray.count == 0) {
        return;
    }
    
    [self shareFolder];
}

- (IBAction)insertAnEmailAction:(UIBarButtonItem *)sender {
    UIAlertView *insertAnEmailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"shareFolder", nil) message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
    [insertAnEmailAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[insertAnEmailAlertView textFieldAtIndex:0] setPlaceholder:AMLocalizedString(@"contactEmail", nil)];
    [insertAnEmailAlertView setTag:3];
    [insertAnEmailAlertView show];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"edit"]];
    [self setTableViewEditing:value animated:YES];
}

- (IBAction)groupAction:(UIBarButtonItem *)sender {
    BOOL value = ![self.groupBarButtonItem.title isEqualToString:AMLocalizedString(@"ok", nil)];
    if (value) {
        self.groupBarButtonItem.title = AMLocalizedString(@"ok", nil);
        if (self.selectedUsersArray.count == 0) {
            self.groupBarButtonItem.enabled = NO;
        }
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem];
    } else {
        if (self.selectedUsersArray.count > 0) {
            self.userSelected(self.selectedUsersArray);
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            self.groupBarButtonItem.title = AMLocalizedString(@"group", @"Title of a menu button which allows users to start a conversation creating a 'Group' chat.");
        }
    }
    [self setTableViewEditing:value animated:YES];
}

- (IBAction)addParticipantAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count > 0) {
        self.userSelected(self.selectedUsersArray);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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
        MEGAShare *share = [_outSharesForNodeMutableArray objectAtIndex:indexPath.row];
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
    
    (self.tableView.isEditing) ? (cell.separatorInset = UIEdgeInsetsMake(0.0, 102.0, 0.0, 0.0)) : (cell.separatorInset = UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0));
    
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
    
    if (tableView.isEditing) {
        [self.selectedUsersArray addObject:user];
        [self.deleteBarButtonItem setEnabled:YES];
        [self.shareFolderBarButtonItem setEnabled:YES];
        
        if (self.selectedUsersArray.count == [self.visibleUsersArray count]) {
            allUsersSelected = YES;
        } else {
            allUsersSelected = NO;
        }
        
        if (self.contactsMode == ContactsModeShareFoldersWith) {
            [self updateNavigationBarTitle];
        } else if (self.contactsMode == ContactsModeChatStartConversation && self.selectedUsersArray.count > 0 ) {
            self.groupBarButtonItem.enabled = YES;
        }
        
        return;
    }
    
    if (!user) {
        [SVProgressHUD showErrorWithStatus:@"Invalid user"];
        return;
    }
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        userTapped = user;
        [self selectPermissions];
    } else if (self.contactsMode == ContactsModeChatStartConversation) {
        self.userSelected(@[user]);
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
        contactDetailsVC.userEmail = user.email;
        contactDetailsVC.userName = user.mnz_fullName;
        contactDetailsVC.userHandle = user.handle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
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
        
        if (self.contactsMode == ContactsModeShareFoldersWith) {
            [self updateNavigationBarTitle];
        }
        
        if (self.selectedUsersArray.count == 0) {
            if (self.contactsMode != ContactsModeChatStartConversation) {
                [self.deleteBarButtonItem setEnabled:NO];
                [self.shareFolderBarButtonItem setEnabled:NO];
            } else {
                self.groupBarButtonItem.enabled = NO;
            }
        }
        
        allUsersSelected = NO;
        
        return;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setTableViewEditing:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setTableViewEditing:NO animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    
    self.selectedUsersArray = [NSMutableArray new];
    [self.selectedUsersArray addObject:user];
    
    [self.deleteBarButtonItem setEnabled:YES];
    [self.shareFolderBarButtonItem setEnabled:YES];
    
    isSwipeEditing = YES;
    
    return (UITableViewCellEditingStyleDelete);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        remainingOperations = 1;
        
        switch (self.contactsMode) {
            case ContactsModeDefault: {
                MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
                [[MEGASdkManager sharedMEGASdk] removeContactUser:user delegate:self];
                break;
            }
            
            case ContactsModeShareFoldersWith:
            case ContactsModeShareFoldersWithEmail:
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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case 0: {
            if (buttonIndex == 0) {
                UIAlertView *emailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"addContact", nil) message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"addContactButton", nil), nil];
                [emailAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
                [emailAlertView textFieldAtIndex:0].placeholder = AMLocalizedString(@"contactEmail", nil);
                emailAlertView.tag = 0;
                [emailAlertView show];
            } else if (buttonIndex == 1) {
                if (self.presentedViewController != nil) {
                    [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
                }
            
                if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
                    ABPeoplePickerNavigationController *contactsPickerNC = [[ABPeoplePickerNavigationController alloc] init];
                    contactsPickerNC.predicateForEnablingPerson = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
                    contactsPickerNC.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
                    contactsPickerNC.peoplePickerDelegate = self;
                    [self presentViewController:contactsPickerNC animated:YES completion:nil];
                } else {
                    CNContactPickerViewController *contactsPickerViewController = [[CNContactPickerViewController alloc] init];
                    contactsPickerViewController.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
                    contactsPickerViewController.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
                    contactsPickerViewController.delegate = self;
                    [self presentViewController:contactsPickerViewController animated:YES completion:nil];
                }
            }
            break;
        }
        
        case 1: {
            NSInteger level;
            switch (buttonIndex) {
                case 0:
                    level = MEGAShareTypeAccessRead;
                    break;
                    
                case 1:
                    level = MEGAShareTypeAccessReadWrite;
                    break;
                    
                case 2:
                    level = MEGANodeAccessLevelFull;
                    break;
                    
                default:
                    return;
            }
            
            if (self.contactsMode == ContactsModeShareFoldersWith) {
                remainingOperations = self.selectedUsersArray.count;
            } else if (self.contactsMode == ContactsModeShareFoldersWithEmail) {
                remainingOperations = [self.nodesArray count];
            } else if (self.contactsMode == ContactsModeFolderSharedWith) {
                remainingOperations = 1;
            }
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            
            switch (self.contactsMode) {
                case ContactsModeShareFoldersWith: {
                    for (MEGAUser *u in self.selectedUsersArray) {
                        for (MEGANode *node in self.nodesArray) {
                            [[MEGASdkManager sharedMEGASdk] shareNode:node withUser:u level:level delegate:self];
                        }
                    }
                    break;
                }
                    
                case ContactsModeShareFoldersWithEmail: {
                    for (MEGANode *node in self.nodesArray) {
                        [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:_email level:level delegate:self];
                    }
                    _email = nil;
                    break;
                }
                    
                case ContactsModeFolderSharedWith: {
                    [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:userTapped level:level delegate:self];
                    break;
                }
                    
                default:
                    break;
            }
            break;
        }
            
        default:
            break;
    }
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
        remainingOperations = 1;
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:self];
    } else {
        UIAlertView *noEmailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"contactWithoutEmail", nil) message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        noEmailAlertView.tag = 2;
        [noEmailAlertView show];
    }
    
    if (emails) {
        CFRelease(emails);
    }
}

#pragma mark - CNContactPickerDelegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperties:(NSArray<CNContactProperty*> *)contactProperties {
    self.addingMoreThanOneContact = (contactProperties.count > 1) ? YES : NO;
    remainingOperations = contactProperties.count;
    for (CNContactProperty *contactProperty in contactProperties) {
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:contactProperty.value message:@"" action:MEGAInviteActionAdd delegate:self];
    }
}

#pragma mark - UIAlertDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable = YES;
    if ([alertView tag] == 0 || [alertView tag] == 3) {
        NSString *email = [[alertView textFieldAtIndex:0] text];
        shouldEnable = (email.length > 0) ? [email mnz_isValidEmail] : NO;
    }
    
    return shouldEnable;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 3) { //insertAnEmailAlertView
        [[alertView textFieldAtIndex:0] resignFirstResponder];
        
        if (buttonIndex == 1) {
            self.contactsMode = ContactsModeShareFoldersWithEmail;
            
            _email = [[alertView textFieldAtIndex:0] text];
            [self shareFolder];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                remainingOperations = 1;
                [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:[[alertView textFieldAtIndex:0] text] message:@"" action:MEGAInviteActionAdd delegate:self];
            }
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                remainingOperations = self.selectedUsersArray.count;
                for (NSInteger i = 0; i < self.selectedUsersArray.count; i++) {
                    [[MEGASdkManager sharedMEGASdk] removeContactUser:[self.selectedUsersArray objectAtIndex:i] delegate:self];
                }
            }
        }
    } else if (alertView.tag == 2) {
    
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
    [self addContact:_addBarButtonItem];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        if ([request type] == MEGARequestTypeInviteContact) {
            if (error.type == MEGAErrorTypeApiEArgs && [request.email isEqualToString:[[MEGASdkManager sharedMEGASdk] myEmail]]) {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noNeedToAddYourOwnEmailAddress", @"Add contacts and share dialog error message when user try to add your own email address")];
            } else if (error.type == MEGAErrorTypeApiEExist) {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"alreadyHaveAContactWithThatEmailAddress", @"Add contacts and share dialog error message when user try to add already existing email address.")];
            } else {
                [SVProgressHUD showErrorWithStatus:error.name];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:error.name];
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeInviteContact: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *alertTitle;
                if (self.addingMoreThanOneContact) {
                    alertTitle = AMLocalizedString(@"theUsersHaveBeenInvited", @"Success message shown when some contacts have been invited");
                } else {
                    alertTitle = AMLocalizedString(@"theUserHasBeenInvited", @"Success message shown when a contact has been invited");
                    alertTitle = [alertTitle stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
                }
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeRemoveContact: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message = (self.selectedUsersArray.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"removedContact", nil), [request email]] : [NSString stringWithFormat:AMLocalizedString(@"removedContacts", nil), self.selectedUsersArray.count];
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
                [self setTableViewEditing:NO animated:NO];
            }
            
            break;
        }
            
        case MEGARequestTypeShare: {
            remainingOperations--;
            if (remainingOperations == 0) {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                
                if (self.contactsMode == ContactsModeFolderSharedWith) {
                    if ([request access] == MEGAShareTypeAccessUnkown) {
                        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"shareRemoved", nil)];
                        
                        if ([self.selectedUsersArray count] == [self.visibleUsersArray count]) {
                            [self.navigationController popToRootViewControllerAnimated:YES];
                        }
                        
                        [self editTapped:_editBarButtonItem];
                        
                    } else {
                        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"permissionsChanged", nil)];
                        
                        MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[request email]];
                        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
                        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
                        if (indexPath != nil) {
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    }
                } else {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudSharedFolder"] status:AMLocalizedString(@"sharedFolder_success", nil)];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
            break;
        }
            
        default:
            break;
    }
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
}

@end
