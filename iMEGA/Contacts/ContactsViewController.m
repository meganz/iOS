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

#import <AddressBookUI/AddressBookUI.h>

#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "Helper.h"

#import "ContactsViewController.h"
#import "ContactTableViewCell.h"
#import "CloudDriveTableViewController.h"
#import "BrowserViewController.h"

#import "ShareFolderActivity.h"


@interface ContactsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAGlobalDelegate> {
    UIAlertView *emailAlertView;
    UIAlertView *removeAlertView;
    
    NSUInteger remainingOperations;
    
    BOOL allUsersSelected;
    BOOL isSwipeEditing;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderBarButtonItem;

@property (weak, nonatomic) IBOutlet UIButton *shareFolderWithButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.toolbar setFrame:CGRectMake(0, 49, CGRectGetWidth(self.view.frame), 49)];
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    
    NSArray *buttonsItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem, self.addBarButtonItem];
    self.navigationItem.rightBarButtonItems = buttonsItems;
    
    [self.shareFolderBarButtonItem setTitle:AMLocalizedString(@"shareFolder", @"Share folder")];
    [self.deleteBarButtonItem setTitle:AMLocalizedString(@"remove", nil)];
    
    if (self.node != nil) {
        [_shareFolderWithButton setTitle:AMLocalizedString(@"shareFolder", nil) forState:UIControlStateNormal];
        [_shareFolderWithButton setEnabled:YES];
        [_shareFolderWithButton setHidden:NO];
        
        [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
        [self.navigationItem setRightBarButtonItems:@[_cancelBarButtonItem] animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self.navigationItem setTitle:AMLocalizedString(@"contactsTitle", @"Contacts")];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    if (self.node != nil) {
        [self editTapped:_editBarButtonItem];
    }
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
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
    self.visibleUsersArray = [NSMutableArray new];
    
    self.users = [[MEGASdkManager sharedMEGASdk] contacts];
    for (NSInteger i = 0; i < [[self.users size] integerValue] ; i++) {
        MEGAUser *u = [self.users userAtIndex:i];
        if ([u access] == MEGAUserVisibilityVisible)
            [self.visibleUsersArray addObject:u];
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
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [actionSheet showFromBarButtonItem:self.addBarButtonItem animated:YES];
    } else {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    
    NSString *message = (self.selectedUsersArray.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"removeMultipleUsersMessage", nil), self.selectedUsersArray.count] :[NSString stringWithFormat:AMLocalizedString(@"removeUserMessage", nil), [[self.selectedUsersArray objectAtIndex:0] email]];
    
    removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeUserTitle", @"Remove user") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
    [removeAlertView show];
    removeAlertView.tag = 1;
    [removeAlertView show];
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

- (IBAction)shareFolderWithTouchUpInside:(UIButton *)sender {
    if (_selectedUsersArray.count == 0) {
        return;
    }
    
    if ([MEGAReachabilityManager isReachable]) {
        if (self.shareFolderActivity != nil) {
            [self.shareFolderActivity activityDidFinish:YES];
        }
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"readOnly", nil), AMLocalizedString(@"readAndWrite", nil), AMLocalizedString(@"fullAccess", nil), nil];
        [actionSheet setTag:1];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
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
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    
    cell.nameLabel.text = [user email];
    
    NSString *avatarFilePath = [Helper pathForUser:user searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
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
        cell.shareLabel.text = AMLocalizedString(@"noFoldersShared", @"No folders shared");
    } else  if (numFilesShares == 1 ) {
        cell.shareLabel.text = AMLocalizedString(@"oneFolderShared", @" folder shared");
    } else {
        cell.shareLabel.text = [NSString stringWithFormat:AMLocalizedString(@"foldersShared", @" folders shared"), numFilesShares];
    }
    
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"done"]];
    
    if (value) {
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
        } else {
            allUsersSelected = NO;
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
    switch (actionSheet.tag) {
        case 0: {
            if (buttonIndex == 0) {
                emailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"addContact", nil) message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"addContactButton", nil), nil];
                [emailAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
                [emailAlertView textFieldAtIndex:0].placeholder = AMLocalizedString(@"contactEmail", nil);
                emailAlertView.tag = 0;
                [emailAlertView show];
            } else if (buttonIndex == 1) {
                ABPeoplePickerNavigationController *contactsPickerNC = [[ABPeoplePickerNavigationController alloc] init];
                contactsPickerNC.peoplePickerDelegate = self;
                
                [self presentViewController:contactsPickerNC animated:YES completion:nil];
            }
            break;
        }
        
        case 1: {
            NSInteger level;
            switch (buttonIndex) {
                case 0:
                    level = 0;
                    break;
                    
                case 1:
                    level = 1;
                    break;
                    
                case 2:
                    level = 2;
                    break;
                    
                default:
                    return;
            }
            
            remainingOperations = self.selectedUsersArray.count;
            
            for (MEGAUser *u in self.selectedUsersArray) {
                [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:u level:level delegate:self];
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
            [button setTitleColor:megaRed forState:UIControlStateNormal];
        }
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
        [[MEGASdkManager sharedMEGASdk] addContactWithEmail:email delegate:self];
    } else {
        UIAlertView *noEmailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"contactWithoutEmail", nil) message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
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
            if ([MEGAReachabilityManager isReachable]) {
                [[MEGASdkManager sharedMEGASdk] addContactWithEmail:[[alertView textFieldAtIndex:0] text] delegate:self];
            } else {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
            }
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            if ([MEGAReachabilityManager isReachable]) {
                remainingOperations = self.selectedUsersArray.count;
                for (NSInteger i = 0; i < self.selectedUsersArray.count; i++) {
                    [[MEGASdkManager sharedMEGASdk] removeContactUser:[self.selectedUsersArray objectAtIndex:i] delegate:self];
                }
            } else {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
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
        text = AMLocalizedString(@"contactsEmptyState_title", @"You don't have any contacts added yet!");
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
   NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaBlack};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        text = AMLocalizedString(@"contactsEmptyState_text", @"Add new contacts using the above button.");
    } else {
        text = @"";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:14.0],
                                 NSForegroundColorAttributeName:megaGray,
                                 NSParagraphStyleAttributeName:paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        return [UIImage imageNamed:@"emptyContacts"];
    } else {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeAddContact:
            [SVProgressHUD show];
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
                    NSString *avatarFilePath = [cacheDirectory stringByAppendingPathComponent:@"thumbnailsV3"];
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
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"contactAdded", nil)];
            break;
            
        case MEGARequestTypeRemoveContact: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message = (self.selectedUsersArray.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"removedContact", nil), [request email]] : [NSString stringWithFormat:AMLocalizedString(@"removedContacts", nil), self.selectedUsersArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self setTableViewEditing:NO animated:NO];
            }
            
            break;
        }
            
        case MEGARequestTypeShare: {
            remainingOperations--;
            if (remainingOperations == 0) {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"sharedFolder_success", @"Folder shared!")];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
            
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
