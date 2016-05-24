/**
 * @file ContactRequestsViewController.m
 * @brief View controller that show your contact requests
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

#import "ContactRequestsViewController.h"

#import <AddressBookUI/AddressBookUI.h>

#import "MEGASdkManager.h"
#import "Helper.h"

#import "MEGAReachabilityManager.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "DateTools.h"

#import "ContactRequestsTableViewCell.h"

@interface ContactRequestsViewController () <UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAGlobalDelegate>

@property (nonatomic, strong) NSMutableArray *outgoingContactRequestArray;
@property (nonatomic, strong) NSMutableArray *incomingContactRequestArray;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *contactRequestsBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;

@property (weak, nonatomic) IBOutlet UISegmentedControl *contactRequestsSegmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ContactRequestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    NSArray *buttonsItems = @[self.addBarButtonItem];
    self.navigationItem.rightBarButtonItems = buttonsItems;
    
    [self internetConnectionChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self.navigationItem setTitle:AMLocalizedString(@"contactRequests", @"Contact requests")];
    
    [self.contactRequestsSegmentedControl setTitle:AMLocalizedString(@"requests", nil) forSegmentAtIndex:0];
    [self.contactRequestsSegmentedControl setTitle:AMLocalizedString(@"sent", nil) forSegmentAtIndex:1];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)reloadUI {
    switch (self.contactRequestsSegmentedControl.selectedSegmentIndex) {
        case 0:
            [self reloadIncomingContactsRequestsView];
            break;
            
        case 1:
            [self reloadOutgoingContactsRequestsView];
            break;
            
        default:
            break;
    }
    
    [self.tableView reloadData];
}

- (void)reloadOutgoingContactsRequestsView {
    self.outgoingContactRequestArray = [[NSMutableArray alloc] init];
    
    MEGAContactRequestList *outgoingContactRequestList = [[MEGASdkManager sharedMEGASdk] outgoingContactRequests];
    for (NSInteger i = 0; i < [[outgoingContactRequestList size] integerValue]; i++) {
        MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
        [self.outgoingContactRequestArray addObject:contactRequest];
    }
}

- (void)reloadIncomingContactsRequestsView {
    self.incomingContactRequestArray = [[NSMutableArray alloc] init];
    
    MEGAContactRequestList *incomingContactRequestList = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
    for (NSInteger i = 0; i < [[incomingContactRequestList size] integerValue]; i++) {
        MEGAContactRequest *contactRequest = [incomingContactRequestList contactRequestAtIndex:i];
        [self.incomingContactRequestArray addObject:contactRequest];
    }
}

- (void)internetConnectionChanged {
    [_addBarButtonItem setEnabled:[MEGAReachabilityManager isReachable]];
}

#pragma mark - IBActions

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

- (IBAction)contactsSegmentedControlValueChanged:(UISegmentedControl *)sender {
    [self reloadUI];
}

- (void)acceptTouchUpInside:(UIButton *)sender {
    MEGAContactRequest *contactSelected = [self.incomingContactRequestArray objectAtIndex:sender.tag];
    [[MEGASdkManager sharedMEGASdk] replyContactRequest:contactSelected action:MEGAReplyActionAccept delegate:self];
}

- (void)declineOrDeleteTouchUpInside:(UIButton *)sender {
    if (self.contactRequestsSegmentedControl.selectedSegmentIndex == 0) {
        MEGAContactRequest *contactSelected = [self.incomingContactRequestArray objectAtIndex:sender.tag];
        [[MEGASdkManager sharedMEGASdk] replyContactRequest:contactSelected action:MEGAReplyActionDeny delegate:self];
    } else {
        MEGAContactRequest *contactSelected = [self.outgoingContactRequestArray objectAtIndex:sender.tag];
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:[contactSelected targetEmail] message:@"" action:MEGAInviteActionDelete delegate:self];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (self.contactRequestsSegmentedControl.selectedSegmentIndex) {
        case 0:
            numberOfRows = [self.incomingContactRequestArray count];
            break;
            
        case 1:
            numberOfRows = [self.outgoingContactRequestArray count];
            break;
            
        default:
            break;
    }
    
    if (numberOfRows == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactRequestsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IncomingContactRequestsCell" forIndexPath:indexPath];
    
    cell.declineButton.tag = indexPath.row;
    [cell.declineButton addTarget:self action:@selector(declineOrDeleteTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *pendingString = [[@" (" stringByAppendingString:AMLocalizedString(@"pending", nil)] stringByAppendingString:@")"];
    switch (self.contactRequestsSegmentedControl.selectedSegmentIndex) {
        case 0: { //INCOMING CONTACTS REQUESTS
            [cell.acceptButton setHidden:NO];
            cell.acceptButton.tag = indexPath.row;
            [cell.acceptButton addTarget:self action:@selector(acceptTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            
            MEGAContactRequest *contactRequest = [self.incomingContactRequestArray objectAtIndex:indexPath.row];
            [cell.avatarImageView setImage:[UIImage imageForName:[contactRequest sourceEmail].uppercaseString size:CGSizeMake(30, 30)]];
            cell.nameLabel.text = [contactRequest sourceEmail];
            cell.timeAgoLabel.text = [[[contactRequest modificationTime] timeAgoSinceNow] stringByAppendingString:pendingString];
            
            break;
        }
            
        case 1: { //OUTGOING CONTACTS REQUESTS
            [cell.acceptButton setHidden:YES];
            
            MEGAContactRequest *contactRequest = [self.outgoingContactRequestArray objectAtIndex:indexPath.row];
            [cell.avatarImageView setImage:[UIImage imageForName:[contactRequest targetEmail].uppercaseString size:CGSizeMake(30, 30)]];
            cell.nameLabel.text = [contactRequest targetEmail];
            cell.timeAgoLabel.text = [[[contactRequest modificationTime] timeAgoSinceNow] stringByAppendingString:pendingString];
            break;
        }
            
        default:
            break;
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        UIAlertView *emailAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"addContact", nil) message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"addContactButton", nil), nil];
        [emailAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [emailAlertView textFieldAtIndex:0].placeholder = AMLocalizedString(@"contactEmail", nil);
        emailAlertView.tag = 0;
        [emailAlertView show];
    } else if (buttonIndex == 1) {
        ABPeoplePickerNavigationController *contactsPickerNC = [[ABPeoplePickerNavigationController alloc] init];
        contactsPickerNC.peoplePickerDelegate = self;
        
        [self presentViewController:contactsPickerNC animated:YES completion:nil];
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

#pragma mark - UIAlertDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            if ([MEGAReachabilityManager isReachable]) {
                [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:[[alertView textFieldAtIndex:0] text] message:@"" action:MEGAInviteActionAdd delegate:self];
            } else {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
            }
        }
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if ([MEGAReachabilityManager isReachable]) {
        text = AMLocalizedString(@"noRequestPending", nil);
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
    UIEdgeInsets capInsets = UIEdgeInsetsMake(10.0, 54.0, 12.0, 54.0);
    UIEdgeInsets rectInsets;
    if (iPhone4X || iPhone5X || iPhone6 || iPhone6Plus) {
        rectInsets = UIEdgeInsetsMake(0.0, -20.0, 0.0, -20.0);
    } else  if (iPad) {
        rectInsets = UIEdgeInsetsMake(0.0, -182.0, 0.0, -182.0);
    } else if (iPadPro) {
        rectInsets = UIEdgeInsetsMake(0.0, -310.0, 0.0, -310.0);
    }
    
    return [[[UIImage imageNamed:@"buttonBorder"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return 40.0f;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    [self addContact:_addBarButtonItem];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([request type] == MEGARequestTypeInviteContact) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(error.name, nil)];
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrUser: {
            for (ContactRequestsTableViewCell *icrtvc in [self.tableView visibleCells]) {
                if ([[request email] isEqualToString:[icrtvc.nameLabel text]]) {
                    NSString *fileName = [request email];
                    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    NSString *avatarFilePath = [cacheDirectory stringByAppendingPathComponent:@"thumbnailsV3"];
                    avatarFilePath = [avatarFilePath stringByAppendingPathComponent:fileName];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
                    if (fileExists) {
                        [icrtvc.avatarImageView setImage:[UIImage imageWithContentsOfFile:avatarFilePath]];
                        icrtvc.avatarImageView.layer.cornerRadius = icrtvc.avatarImageView.frame.size.width/2;
                        icrtvc.avatarImageView.layer.masksToBounds = YES;
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeInviteContact:
            switch (request.number.integerValue) {
                case 0:
                    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"requestSent", nil)];
                    break;
                    
                case 1:
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudError"] status:AMLocalizedString(@"requestCancelled", nil)];
                    break;
                    
                default:
                    break;
            }
            break;
            
            
        case MEGARequestTypeReplyContactRequest:
            switch (request.number.integerValue) {
                case 0:
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudSuccess"] status:AMLocalizedString(@"requestAccepted", nil)];
                    break;
                    
                case 1:
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudError"] status:AMLocalizedString(@"requestDeleted", nil)];
                    break;
                    
                default:
                    break;
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

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self reloadUI];
}

@end
