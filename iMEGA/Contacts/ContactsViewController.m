#import "ContactsViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIBarButtonItem+Badge.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "Helper.h"
#import "NSMutableAttributedString+MNZCategory.h"

#import "ContactTableViewCell.h"
#import "BrowserViewController.h"
#import "SharedItemsViewController.h"

#import "ShareFolderActivity.h"


@interface ContactsViewController () <ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAGlobalDelegate> {
    UIAlertView *removeAlertView;
    
    NSUInteger remainingOperations;
    
    BOOL allUsersSelected;
    BOOL isSwipeEditing;
    
    MEGAUser *userTapped;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersArray;
@property (nonatomic, strong) NSMutableArray *outSharesForNodeMutableArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *contactRequestsBarButtonItem;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *insertAnEmailBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareFolderWithBarButtonItem;
@property (strong, nonatomic) NSString *email;

@property (nonatomic, strong) NSMutableDictionary *indexPathsMutableDictionary;
@property (nonatomic, strong) NSMutableArray *userNamesRequestedMutableArray;
@property (nonatomic, strong) NSMutableArray *usersAvatarRequestedMutableArray;

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
        case Contacts: {
            self.namesMutableDictionary = [[NSMutableDictionary alloc] init];
            
            NSArray *buttonsItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem, self.addBarButtonItem, self.contactRequestsBarButtonItem];
            self.navigationItem.rightBarButtonItems = buttonsItems;
            
            [self.shareFolderBarButtonItem setTitle:AMLocalizedString(@"shareFolder", nil)];
            break;
        }
            
        case ContactsShareFolderWith:
        case ContactsShareFoldersWith: {
            [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
            [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:17.0], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            [self.navigationItem setRightBarButtonItems:@[_cancelBarButtonItem] animated:NO];
            
            [_insertAnEmailBarButtonItem setTitle:AMLocalizedString(@"addFromEmail", nil)];
            [_shareFolderWithBarButtonItem setTitle:AMLocalizedString(@"shareFolder", nil)];
            [self.insertAnEmailBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:17.0], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            [self.shareFolderWithBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:17.0], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [self.navigationController.topViewController setToolbarItems:@[_shareFolderWithBarButtonItem, flexibleItem, _insertAnEmailBarButtonItem ] animated:NO];
            [self.navigationController setToolbarHidden:NO];
            
            break;
        }
            
        case ContactsFolderSharedWith: {
            if(self.namesMutableDictionary == nil) {
                self.namesMutableDictionary = [[NSMutableDictionary alloc] init];
            }
            
            NSArray *buttonsItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem];
            [self.navigationItem setRightBarButtonItems:buttonsItems];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [_toolbar setItems:@[flexibleItem, _deleteBarButtonItem]];
            
            break;
        }
    }
    
    self.indexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    self.userNamesRequestedMutableArray = [[NSMutableArray alloc] init];
    self.usersAvatarRequestedMutableArray = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    if (self.contactsMode == ContactsFolderSharedWith) {
        [self.navigationItem setTitle:AMLocalizedString(@"sharedWith", nil)];
    } else {
        [self.navigationItem setTitle:AMLocalizedString(@"contactsTitle", nil)];
    }
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    if (self.contactsMode == ContactsShareFolderWith || self.contactsMode == ContactsShareFoldersWith) {
        [self editTapped:_editBarButtonItem];
    }
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.tableView isEditing]) {
        [self setEditing:NO animated:NO];
    }
    
    [self.namesMutableDictionary removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.contactsMode == Contacts) {
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

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"edit"]];
    [self setTableViewEditing:value animated:YES];
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        [self.addBarButtonItem setEnabled:NO];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        }
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allUsersSelected = NO;
        self.selectedUsersArray = nil;
        [self.addBarButtonItem setEnabled:YES];
        self.navigationItem.leftBarButtonItems = @[];
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
    
    isSwipeEditing = NO;
}

#pragma mark - Private

- (void)reloadUI {
    self.visibleUsersArray = [[NSMutableArray alloc] init];
    
    if (self.contactsMode == ContactsFolderSharedWith) {
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
            if ([user visibility] == MEGAUserVisibilityVisible)
                [self.visibleUsersArray addObject:user];
        }
    }
    
    if ([self.visibleUsersArray count] == 0) {
        [_editBarButtonItem setEnabled:NO];
    } else {
        [_editBarButtonItem setEnabled:YES];
    }
    
    [self.tableView reloadData];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
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
        if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:self.view]) {
                [actionSheet showInView:self.view];
            } else {
                [actionSheet showInView:window];
            }
        } else {
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
}

- (void)shareFolder {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedDescending)) {
            if (self.shareFolderActivity != nil) {
                [self.shareFolderActivity activityDidFinish:YES];
            }
        }
        
        [self selectPermissions];
        
    }
}

- (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
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
        [self.usersAvatarRequestedMutableArray removeObject:user.email];
        userHasChanged = YES;
    } else if ([user hasChangedType:MEGAUserChangeTypeFirstname] || [user hasChangedType:MEGAUserChangeTypeLastname] || [user hasChangedType:MEGAUserChangeTypeEmail]) {
        [self.namesMutableDictionary removeObjectForKey:[user email]];
        userHasChanged = YES;
    }
    
    return  userHasChanged;
}

- (void)requestUserNameAndLastNameWithEmail:(NSString *)userEmail {
    
    BOOL isUserNameAlreadyRequested = [self.userNamesRequestedMutableArray containsObject:userEmail];
    if (!isUserNameAlreadyRequested) {
        MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:userEmail];
        [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname delegate:self];
        [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname delegate:self];
        [self.userNamesRequestedMutableArray addObject:userEmail];
    }
}

- (UIImage *)avatarForUser:(MEGAUser *)user withSize:(CGSize )avatarSize {
    UIImage *avatar;
    NSString *avatarFilePath = [Helper pathForUser:user searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
    if (fileExists) {
        avatar = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        NSString *colorString = [[MEGASdkManager sharedMEGASdk] avatarColorForUser:user];
        avatar = [UIImage imageForName:[user email].uppercaseString size:avatarSize backgroundColor:[UIColor colorFromHexString:colorString] textColor:[UIColor whiteColor] font:[UIFont fontWithName:kFont size:(avatarSize.width/2)]];
        
        [self requestAvatarForUser:user destinationFilePath:avatarFilePath];
    }
    
    return avatar;
}

- (void)requestAvatarForUser:(MEGAUser *)user destinationFilePath:(NSString *)avatarFilePath {
    BOOL isUserAvatarAlreadyRequested = [self.usersAvatarRequestedMutableArray containsObject:[user email]];
    if (!isUserAvatarAlreadyRequested) {
        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath delegate:self];
        [self.usersAvatarRequestedMutableArray addObject:[user email]];
    }
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
    
    if (self.contactsMode == ContactsFolderSharedWith) {
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
    NSString *userEmail = [user email];
    NSString *userName = nil;
    if (self.contactsMode == ContactsFolderSharedWith) {
        userName = [self.namesMutableDictionary objectForKey:userEmail];
        BOOL isNameEmpty = [[userName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
        if (userName != nil && !isNameEmpty) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsNameTableViewCellID" forIndexPath:indexPath];
            [cell.nameLabel setText:userName];
            [cell.shareLabel setText:userEmail];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsEmailTableViewCellID" forIndexPath:indexPath];
            [cell.nameLabel setText:userEmail];
            
            [self requestUserNameAndLastNameWithEmail:userEmail];
        }
        MEGAShare *share = [_outSharesForNodeMutableArray objectAtIndex:indexPath.row];
        [cell.permissionsImageView setImage:[Helper permissionsButtonImageForShareType:share.access]];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
        [cell.nameLabel setText:userEmail];
        
        int numFilesShares = [[[[MEGASdkManager sharedMEGASdk] inSharesForUser:user] size] intValue];
        if (numFilesShares == 0) {
            cell.shareLabel.text = AMLocalizedString(@"noFoldersShared", @"No folders shared");
        } else  if (numFilesShares == 1 ) {
            cell.shareLabel.text = AMLocalizedString(@"oneFolderShared", @" folder shared");
        } else {
            cell.shareLabel.text = [NSString stringWithFormat:AMLocalizedString(@"foldersShared", @" folders shared"), numFilesShares];
        }
    }
    
    UIImage *userAvatarImage = [self avatarForUser:user withSize:cell.avatarImageView.frame.size];
    cell.avatarImageView.image = userAvatarImage;
    cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.size.width/2;
    cell.avatarImageView.layer.masksToBounds = YES;
    
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"done"]];
    
    if (value) {
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
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    return cell;
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
        
        return;
    }
    
    if (!user) {
        [SVProgressHUD showErrorWithStatus:@"Invalid user"];
        return;
    }
    
    if (self.contactsMode == ContactsFolderSharedWith) {
        userTapped = user;
        [self selectPermissions];
    } else {
        if ([[[[MEGASdkManager sharedMEGASdk] inSharesForUser:user] size] integerValue] > 0) {
            SharedItemsViewController *sharedItemsVC = [[UIStoryboard storyboardWithName:@"SharedItems" bundle:nil] instantiateViewControllerWithIdentifier:@"SharedItemsViewControllerID"];
            sharedItemsVC.user = user;
            sharedItemsVC.sharedItemsMode = SharedItemsModeInSharesForUser;
            [self.navigationController pushViewController:sharedItemsVC animated:YES];
        }
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
        
        if (self.selectedUsersArray.count == 0) {
            [self.deleteBarButtonItem setEnabled:NO];
            [self.shareFolderBarButtonItem setEnabled:NO];
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
            case Contacts: {
                MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
                [[MEGASdkManager sharedMEGASdk] removeContactUser:user delegate:self];
                break;
            }
                
            case ContactsShareFolderWith:
            case ContactsShareFolderWithEmail:
            case ContactsShareFoldersWith:
            case ContactsShareFoldersWithEmail:
                break;
                
            case ContactsFolderSharedWith: {
                [self deleteAction:self.deleteBarButtonItem];
                break;
            }
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
                    if ([contactsPickerNC respondsToSelector:@selector(predicateForSelectionOfProperty)]) {
                        contactsPickerNC.predicateForEnablingPerson = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
                        contactsPickerNC.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
                    }
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
            
            if ((self.contactsMode == ContactsShareFolderWith) || (self.contactsMode == ContactsShareFoldersWith)) {
                remainingOperations = self.selectedUsersArray.count;
            } else if (self.contactsMode == ContactsShareFoldersWithEmail) {
                remainingOperations = [self.nodesArray count];
            } else if ((self.contactsMode == ContactsFolderSharedWith) || (self.contactsMode == ContactsShareFolderWithEmail)) {
                remainingOperations = 1;
            }
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            
            switch (self.contactsMode) {
                case ContactsShareFolderWith: {
                    for (MEGAUser *u in self.selectedUsersArray) {
                        [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:u level:level delegate:self];
                    }
                    break;
                }
                    
                case ContactsShareFolderWithEmail: {
                    [[MEGASdkManager sharedMEGASdk] shareNode:self.node withEmail:_email level:level delegate:self];
                    _email = nil;
                    break;
                }
                    
                case ContactsShareFoldersWith: {
                    for (MEGAUser *u in self.selectedUsersArray) {
                        for (MEGANode *node in self.nodesArray) {
                            [[MEGASdkManager sharedMEGASdk] shareNode:node withUser:u level:level delegate:self];
                        }
                    }
                    break;
                }
                    
                case ContactsShareFoldersWithEmail: {
                    for (MEGANode *node in self.nodesArray) {
                        [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:_email level:level delegate:self];
                    }
                    _email = nil;
                    break;
                }
                    
                case ContactsFolderSharedWith: {
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

//For iOS 7 UIActionSheet color
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:[UIColor mnz_redD90007] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewControllerAnimated:YES completion:nil];    // iOS 7
}

// iOS 7
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

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
    remainingOperations = contactProperties.count;
    for (CNContactProperty *contactProperty in contactProperties) {
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:contactProperty.value message:@"" action:MEGAInviteActionAdd delegate:self];
    }
}

#pragma mark - UIAlertDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable = YES;
    if ([alertView tag] == 3) {
        NSString *email = [[alertView textFieldAtIndex:0] text];
        shouldEnable = [self validateEmail:email];
    }
    
    return shouldEnable;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 3) { //insertAnEmailAlertView
        [[alertView textFieldAtIndex:0] resignFirstResponder];
        
        if (buttonIndex == 1) {
            if (self.contactsMode == ContactsShareFolderWith) {
                [self setContactsMode:ContactsShareFolderWithEmail];
            } else if (self.contactsMode == ContactsShareFoldersWith) {
                [self setContactsMode:ContactsShareFoldersWithEmail];
            }
            
            _email = [[alertView textFieldAtIndex:0] text];
            [self shareFolder];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
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
        return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.") sectionTitle:AMLocalizedString(@"myContacts", @"Title of My Contacts section")];
        
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
   NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
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
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        text = AMLocalizedString(@"addContacts", nil);
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:20.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]};
    
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
        if ([request type] == MEGARequestTypeInviteContact || [request type] == MEGARequestTypeShare) {
            [SVProgressHUD showErrorWithStatus:error.name];
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrUser: {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[request email]];
            NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
            NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
            
            BOOL shouldUpdateCell = NO;
            
            if ([request file] != nil) {
                for (ContactTableViewCell *ctvc in [self.tableView visibleCells]) {
                    NSIndexPath *visibleCellIndexPath = [self.tableView indexPathForCell:ctvc];
                    if (indexPath == visibleCellIndexPath) {
                        shouldUpdateCell = YES;
                        break;
                    }
                }
            } else {
                NSString *name;
                switch ([request paramType]) {
                    case MEGAUserAttributeFirstname: {
                        name = [request text];
                        if (name != nil) {
                            [self.namesMutableDictionary setObject:name forKey:[request email]];
                        } else {
                            [self.namesMutableDictionary setObject:[request email] forKey:[request email]];
                        }
                        break;
                    }
                        
                    case MEGAUserAttributeLastname: {
                        name = [self.namesMutableDictionary objectForKey:[request email]];
                        name = [name stringByAppendingString:[NSString stringWithFormat:@" %@", [request text]]];
                        if (name != nil) {
                            [self.namesMutableDictionary setObject:name forKey:[request email]];
                        } else {
                            [self.namesMutableDictionary setObject:[request email] forKey:[request email]];
                        }
                        
                        [self.userNamesRequestedMutableArray removeObject:[request email]];
                        shouldUpdateCell = YES;
                        break;
                    }
                }
            }
            
            if (indexPath != nil && shouldUpdateCell) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            break;
        }
            
        case MEGARequestTypeInviteContact:
            remainingOperations--;
            if (remainingOperations == 0) {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"requestSent", nil)];
            }
            break;
            
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
                
                if (self.contactsMode == ContactsFolderSharedWith) {
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
