#import "ChatAttachedContactsViewController.h"

#import "MEGAInviteContactRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "UIImageView+MNZCategory.h"

#import "ContactDetailsViewController.h"
#import "ContactTableViewCell.h"

#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface ChatAttachedContactsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableDictionary *alreadyContactsMutableDictionary;
@property (strong, nonatomic) NSMutableDictionary *alreadyContactsIndexPathMutableDictionary;

@property (strong, nonatomic) NSMutableArray *selectedUsersMutableArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;

@end

@implementation ChatAttachedContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAttachedContacts];
    [self configureImages];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark - Private

- (void)configureImages {
    self.selectAllBarButtonItem.image = [UIImage megaImageWithNamed:@"selectAllItems"];
}

- (void)setupAttachedContacts {
    self.backBarButtonItem.image = self.backBarButtonItem.image.imageFlippedForRightToLeftLayoutDirection;
    self.navigationItem.leftBarButtonItem = self.backBarButtonItem;
    self.editBarButtonItem.title = LocalizedString(@"select", @"Caption of a button to select files");
    self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
    
    self.addBarButtonItem.title = LocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email");
    [self.addBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_red]} forState:UIControlStateNormal];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[flexibleItem, self.addBarButtonItem]];
    
    self.alreadyContactsMutableDictionary = [[NSMutableDictionary alloc] init];
    NSUInteger usersAttachedCount =  self.message.usersCount;
    for (NSUInteger i = 0; i < usersAttachedCount; i++) {
        NSString *userEmail = [self.message userEmailAtIndex:i];
        MEGAUser *user = [MEGASdk.shared contactForEmail:userEmail];
        if ((user != nil) && (user.visibility == MEGAUserVisibilityVisible)) {
            NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
            [self.alreadyContactsMutableDictionary setObject:user forKey:userBase64Handle];
        }
    }
    
    self.alreadyContactsIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    self.selectedUsersMutableArray = [[NSMutableArray alloc] init];
}

- (void)reloadUI {
    [self setNavigationBarTitle];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    [self.tableView reloadData];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    boolValue ? [self reloadUI] : [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    self.editBarButtonItem.enabled = boolValue;
}

- (void)setNavigationBarTitle {
    [self updatePromptTitle];
    
    NSString *navigationTitle = LocalizedString(@"sentXContacts", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
    navigationTitle = [navigationTitle stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%lu", (unsigned long)self.message.usersCount]];
    self.navigationItem.title = navigationTitle;
}

- (void)updatePromptTitle {
    if (self.tableView.isEditing) {
        self.navigationItem.prompt = [self titleForPromptWithCountOfContacts:(int)self.selectedUsersMutableArray.count];
    } else {
        self.navigationItem.prompt = nil;
    }
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
        self.addBarButtonItem.enabled = NO;
    } else {
        self.editBarButtonItem.title = LocalizedString(@"select", @"Caption of a button to select files");
        self.addBarButtonItem.enabled = YES;
        
        [self.selectedUsersMutableArray removeAllObjects];
    }
}

- (void)setContactTableViewCell:(ContactTableViewCell *)cell enabled:(BOOL)boolValue {
    cell.userInteractionEnabled = boolValue;
    cell.nameLabel.enabled = boolValue;
    cell.shareLabel.enabled = boolValue;
    cell.avatarImageView.alpha = boolValue ? 1.0 : 0.5;
}

#pragma mark - IBActions

- (IBAction)backAction:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    
    [self setTableViewEditing:enableEditing animated:YES];
    
    self.navigationItem.leftBarButtonItem = enableEditing ? self.selectAllBarButtonItem : self.backBarButtonItem;
    [self updatePromptTitle];
    
    NSArray *indexPathsArray = self.alreadyContactsIndexPathMutableDictionary.allValues;
    for (NSIndexPath *indexPath in indexPathsArray) {
        ContactTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self setContactTableViewCell:cell enabled:!self.tableView.isEditing];
    }
    
    [self.navigationController setToolbarHidden:!enableEditing animated:YES];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    NSUInteger selectedUsersCount = self.selectedUsersMutableArray.count;
    if (self.message.usersCount != selectedUsersCount) {
        [self.selectedUsersMutableArray removeAllObjects];
        
        NSUInteger usersAttachedCount = self.message.usersCount;
        for (NSInteger i = 0; i < usersAttachedCount; i++) {
            uint64_t userHandle = [self.message userHandleAtIndex:i];
            NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
            if (![self.alreadyContactsMutableDictionary objectForKey:userBase64Handle]) {
                NSString *email = [self.message userEmailAtIndex:i];
                [self.selectedUsersMutableArray addObject:email];
            }
        }
    } else {
        [self.selectedUsersMutableArray removeAllObjects];
    }
    
    [self updatePromptTitle];
    selectedUsersCount = self.selectedUsersMutableArray.count;
    self.addBarButtonItem.title = (selectedUsersCount > 1) ? LocalizedString(@"addContacts", @"Button title shown in empty views when you can 'Add contacts'") : LocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email");
    self.addBarButtonItem.enabled = (selectedUsersCount == 0) ? NO : YES;
    [self.tableView reloadData];
}

- (IBAction)addContacts:(UIBarButtonItem *)sender {
    NSUInteger count = self.selectedUsersMutableArray.count;
    MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:count];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *email = [self.selectedUsersMutableArray objectAtIndex:i];
        [MEGASdk.shared inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
    }
    
    [self editTapped:self.editBarButtonItem];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        numberOfRows = self.message.usersCount;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    
    NSString *username = [self.message contactNameAtIndex:indexPath.row];
    NSString *currentEmail = [self.message userEmailAtIndex:indexPath.row];
    
    [cell.avatarImageView mnz_setImageForUserHandle:[self.message userHandleAtIndex:indexPath.row] name:username];
    cell.nameLabel.text = username;
    
    uint64_t userHandle = [self.message userHandleAtIndex:indexPath.row];
    NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    if ([self.alreadyContactsMutableDictionary objectForKey:userBase64Handle] != nil) {
        NSString *alreadyAContactString = LocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.");
        cell.shareLabel.text = [alreadyAContactString stringByReplacingOccurrencesOfString:@"%s" withString:currentEmail];
        
        [self.alreadyContactsIndexPathMutableDictionary setObject:indexPath forKey:userBase64Handle];
        
        [self setContactTableViewCell:cell enabled:!tableView.isEditing];
    } else {
        cell.shareLabel.text = currentEmail;
        [self setContactTableViewCell:cell enabled:YES];
    }
    
    if (self.tableView.isEditing) {
        for (NSString *email in self.selectedUsersMutableArray) {
            if ([currentEmail isEqualToString:email]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColor.clearColor;
    cell.selectedBackgroundView = view;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.alreadyContactsIndexPathMutableDictionary objectForKey:indexPath] ? NO : YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *userEmailSelected = [self.message userEmailAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        [self.selectedUsersMutableArray addObject:userEmailSelected];
        
        [self updatePromptTitle];
        
        NSUInteger selectedUsersCount = self.selectedUsersMutableArray.count;
        self.addBarButtonItem.title = (selectedUsersCount > 1) ? LocalizedString(@"addContacts", @"Button title shown in empty views when you can 'Add contacts'") : LocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email");
        self.addBarButtonItem.enabled = (selectedUsersCount == 0) ? NO : YES;
        return;
    } else {
        uint64_t userHandle = [self.message userHandleAtIndex:indexPath.row];
        NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
        if ([self.alreadyContactsIndexPathMutableDictionary objectForKey:userBase64Handle] != nil) {
            ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
            contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
            contactDetailsVC.userEmail          = [self.message userEmailAtIndex:indexPath.row];
            contactDetailsVC.userName           = [self.message userNameAtIndex:indexPath.row];
            contactDetailsVC.userHandle         = userHandle;
            [self.navigationController pushViewController:contactDetailsVC animated:YES];
            return;
        }
        
        NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
        [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email") detail:nil image:nil style:UIAlertActionStyleDefault actionHandler:^{
            MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [MEGAInviteContactRequestDelegate.alloc initWithNumberOfRequests:1];
            [MEGASdk.shared inviteContactWithEmail:userEmailSelected message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
        }]];
        
        ActionSheetViewController *moreActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:userEmailSelected dismissCompletion:nil sender:[tableView cellForRowAtIndexPath:indexPath]];
        [self presentViewController:moreActionSheet animated:YES completion:nil];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        NSString *emailDeselected = [self.message userEmailAtIndex:indexPath.row];
        NSMutableArray *tempArray = self.selectedUsersMutableArray.copy;
        for (NSString *email in tempArray) {
            if ([emailDeselected isEqualToString:email]) {
                [self.selectedUsersMutableArray removeObject:email];
            }
        }
        
        [self updatePromptTitle];
        
        NSUInteger selectedUsersCount = self.selectedUsersMutableArray.count;
        self.addBarButtonItem.title = (selectedUsersCount > 1) ? LocalizedString(@"addContacts", @"Button title shown in empty views when you can 'Add contacts'") : LocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email");
        self.addBarButtonItem.enabled = (selectedUsersCount == 0) ? NO : YES;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.alreadyContactsIndexPathMutableDictionary objectForKey:indexPath] ? NO : YES;
}

@end
