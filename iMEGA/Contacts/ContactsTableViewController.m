/**
 * @file ContactsTableViewController.m
 * @brief View controller that show your contacts
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "ContactsTableViewController.h"
#import "ContactTableViewCell.h"
#import "Helper.h"
#import "CloudDriveTableViewController.h"
#import "BrowserViewController.h"

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "MEGANavigationController.h"

@interface ContactsTableViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate> {
    UIAlertView *emailAlertView;
    UIAlertView *removeAlertView;
    
    NSUInteger remainingOperations;
    
    BOOL allUsersSelected;
    BOOL isSwipeEditing;
}

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderBarButtonItem;

@end

@implementation ContactsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    NSArray *buttonsItems = @[self.editButtonItem, self.addBarButtonItem];
    self.navigationItem.rightBarButtonItems = buttonsItems;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"contactsTitle", @"Contacts")];
    
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [self reloadUI];
}

- (void)dealloc {
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [self.addBarButtonItem setEnabled:NO];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        }
    } else {
        allUsersSelected = NO;
        self.selectAllBarButtonItem.image = [UIImage imageNamed:@"selectAll"];
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
    self.visibleUsersArray = [NSMutableArray new];
    
    self.users = [[MEGASdkManager sharedMEGASdk] contacts];
    for (NSInteger i = 0; i < [[self.users size] integerValue] ; i++) {
        MEGAUser *u = [self.users userAtIndex:i];
        if ([u access] == MEGAUserVisibilityVisible)
            [self.visibleUsersArray addObject:u];
    }
    
    [self.tableView reloadData];
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
        self.selectAllBarButtonItem.image = [UIImage imageNamed:@"deselectAll"];
    } else {
        allUsersSelected = NO;
        self.selectAllBarButtonItem.image = [UIImage imageNamed:@"selectAll"];
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
                                                    cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:AMLocalizedString(@"addFromEmail", nil), AMLocalizedString(@"addFromContacts", nil), nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    
    NSString *message = (self.selectedUsersArray.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"removeMultipleUsersMessage", nil), self.selectedUsersArray.count] :[NSString stringWithFormat:AMLocalizedString(@"removeUserMessage", nil), [[self.selectedUsersArray objectAtIndex:0] email]];
    
    removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeUserTitle", @"Remove user") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"ok", @"OK"), nil];
    [removeAlertView show];
    removeAlertView.tag = 1;
    [removeAlertView show];
}

- (IBAction)shareFolderAction:(UIBarButtonItem *)sender {
    UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    MEGANavigationController *mcnc = [cloudStoryboard instantiateViewControllerWithIdentifier:@"moveNodeNav"];
    [self presentViewController:mcnc animated:YES completion:nil];
    
    BrowserViewController *mcnvc = mcnc.viewControllers.firstObject;
    mcnvc.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
    [mcnvc setSelectedUsersArray:self.selectedUsersArray];
    
    [self setEditing:NO animated:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  [self.visibleUsersArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    
    cell.nameLabel.text = [user email];
    
    NSString *avatarFilePath = [Helper pathForUser:user searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
    
    if (fileExists) {
        [cell.avatarImageView setImage:[UIImage imageWithContentsOfFile:avatarFilePath]];
        cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.size.width/2;
        cell.avatarImageView.layer.masksToBounds = YES;
    } else {
        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath delegate:self];
        [cell.avatarImageView setImage:[UIImage imageForName:[user email].uppercaseString size:CGSizeMake(30, 30)]];
    }
    
    int numFilesShares = [[[[MEGASdkManager sharedMEGASdk] inSharesForUser:user] size] intValue];
    if (numFilesShares == 0) {
        cell.shareLabel.text = AMLocalizedString(@"noFoldersShare", @"No folders shared");
    } else  if (numFilesShares == 1 ) {
        cell.shareLabel.text = AMLocalizedString(@"oneFolderShare", @" folder shared");
    } else {
        cell.shareLabel.text = [NSString stringWithFormat:AMLocalizedString(@"foldersShare", @" folders shared"), numFilesShares];
    }
    
    if (self.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGAUser *u in self.selectedUsersArray) {
            if ([[u email] isEqualToString:[user email]]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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
            self.selectAllBarButtonItem.image = [UIImage imageNamed:@"deselectAll"];
        } else {
            allUsersSelected = NO;
            self.selectAllBarButtonItem.image = [UIImage imageNamed:@"selectAll"];
        }
        
        return;
    }
    
    if (!user) {
        [SVProgressHUD showErrorWithStatus:@"Invalid user"];
        return;
    }
    
    if ([[[[MEGASdkManager sharedMEGASdk] inSharesForUser:user] size] integerValue] > 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
        CloudDriveTableViewController *cloud = [storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];

        [self.navigationController pushViewController:cloud animated:YES];
        cloud.navigationItem.title = [user email];

        [cloud setUser:user];
        [cloud setDisplayMode:DisplayModeContact];
    }
    
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
        self.selectAllBarButtonItem.image = [UIImage imageNamed:@"selectAll"];
        
        return;
    }
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
        MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
        [[MEGASdkManager sharedMEGASdk] removeContactUser:user delegate:self];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        emailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"contactTitle", nil) message:AMLocalizedString(@"contactMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"addContactButton", nil), nil];
        [emailAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [emailAlertView textFieldAtIndex:0].text = @"";
        emailAlertView.tag = 0;
        [emailAlertView show];
    } else if (buttonIndex == 1) {
        ABPeoplePickerNavigationController *contactsPickerNC = [[ABPeoplePickerNavigationController alloc] init];
        contactsPickerNC.peoplePickerDelegate = self;
        
        [self presentViewController:contactsPickerNC animated:YES completion:nil];
    }
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

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
        [[MEGASdkManager sharedMEGASdk] addContactWithEmail:email delegate:self];
    } else {
        UIAlertView *noEmailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"contactWithoutEmailTitle", nil) message:AMLocalizedString(@"contactWithoutEmailMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
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
        [[MEGASdkManager sharedMEGASdk] addContactWithEmail:email delegate:self];
    } else {
        UIAlertView *noEmailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"contactWithoutEmailTitle", nil) message:AMLocalizedString(@"contactWithoutEmailMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        noEmailAlertView.tag = 2;
        [noEmailAlertView show];
    }
    
    if (emails) {
        CFRelease(emails);
    }
}

#pragma mark - UIAlertDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            [[MEGASdkManager sharedMEGASdk] addContactWithEmail:[[alertView textFieldAtIndex:0] text] delegate:self];
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            remainingOperations = self.selectedUsersArray.count;
            for (NSInteger i = 0; i < self.selectedUsersArray.count; i++) {
                [[MEGASdkManager sharedMEGASdk] removeContactUser:[self.selectedUsersArray objectAtIndex:i] delegate:self];
            }
        }
    } else if (alertView.tag == 2) {
    
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = AMLocalizedString(@"contactsEmptyState_title", @"Add new contacts using the upper button.");
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = AMLocalizedString(@"contactsEmptyState_text", @"You don't have any contacts added yet!");
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"emptyContacts"];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeAddContact:
            [SVProgressHUD showWithStatus:AMLocalizedString(@"adding", nil)];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([request type] == MEGARequestTypeAddContact) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"addContactError", nil)];
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrUser: {
            for (ContactTableViewCell *ctvc in [self.tableView visibleCells]) {
                if ([[request email] isEqualToString:[ctvc.nameLabel text]]) {
                    NSString *fileName = [request email];                    
                    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    NSString *avatarFilePath = [cacheDirectory stringByAppendingPathComponent:@"thumbs"];
                    avatarFilePath = [avatarFilePath stringByAppendingPathComponent:fileName];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
                    if (fileExists) {
                        [ctvc.avatarImageView setImage:[UIImage imageWithContentsOfFile:avatarFilePath]];
                        ctvc.avatarImageView.layer.cornerRadius = ctvc.avatarImageView.frame.size.width/2;
                        ctvc.avatarImageView.layer.masksToBounds = YES;
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeAddContact:
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"added", nil)];
            break;
            
        case MEGARequestTypeRemoveContact:
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message = (self.selectedUsersArray.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"removedContact", nil), [request email]] : [NSString stringWithFormat:AMLocalizedString(@"removedContacts", nil), self.selectedUsersArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self setEditing:NO animated:NO];
            }
            
            break;
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    [self reloadUI];
}

@end
