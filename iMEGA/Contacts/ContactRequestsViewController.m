#import "ContactRequestsViewController.h"

#import "MEGASdkManager.h"
#import "Helper.h"

#import "MEGAReachabilityManager.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"
#import "DateTools.h"

#import "ContactRequestsTableViewCell.h"

@interface ContactRequestsViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAGlobalDelegate>

@property (nonatomic, strong) NSMutableArray *outgoingContactRequestArray;
@property (nonatomic, strong) NSMutableArray *incomingContactRequestArray;

@property (weak, nonatomic) IBOutlet UISegmentedControl *contactRequestsSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSUInteger remainingOperations;

@end

@implementation ContactRequestsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.navigationItem.titleView = self.contactRequestsSegmentedControl;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self.navigationItem setTitle:AMLocalizedString(@"contactRequests", @"Contact requests")];
    
    [self.contactRequestsSegmentedControl setTitle:AMLocalizedString(@"received", @"Title of one of the filters in 'Contacts requests' section. If 'Received' is selected, it will only show the requests which have been recieved.") forSegmentAtIndex:0];
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
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

#pragma mark - Private

- (void)internetConnectionChanged {
    [self.tableView reloadData];
}

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

#pragma mark - IBActions

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

- (IBAction)doneTouchUpInside:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
    
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
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
            NSString *avatarColorString = [MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactRequest.handle]];
            cell.avatarImageView.image = [UIImage imageForName:contactRequest.sourceEmail.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor colorFromHexString:avatarColorString] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(cell.avatarImageView.frame.size.width/2.0f)]];
            cell.nameLabel.text = [contactRequest sourceEmail];
            cell.timeAgoLabel.text = [[[contactRequest modificationTime] timeAgoSinceNow] stringByAppendingString:pendingString];
            
            break;
        }
            
        case 1: { //OUTGOING CONTACTS REQUESTS
            [cell.acceptButton setHidden:YES];
            
            MEGAContactRequest *contactRequest = [self.outgoingContactRequestArray objectAtIndex:indexPath.row];
            NSString *avatarColorString = [MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactRequest.handle]];
            cell.avatarImageView.image = [UIImage imageForName:contactRequest.targetEmail.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor colorFromHexString:avatarColorString] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(cell.avatarImageView.frame.size.width/2.0f)]];
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
    cell.separatorInset = UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([request type] == MEGARequestTypeInviteContact) {
            [SVProgressHUD showErrorWithStatus:error.name];
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrUser: {
            for (ContactRequestsTableViewCell *icrtvc in [self.tableView visibleCells]) {
                if ([[request email] isEqualToString:[icrtvc.nameLabel text]]) {
                    NSString *fileName = [request email];
                    NSString *avatarFilePath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
                    avatarFilePath = [avatarFilePath stringByAppendingPathComponent:fileName];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath];
                    if (fileExists) {
                        [icrtvc.avatarImageView setImage:[UIImage imageWithContentsOfFile:avatarFilePath]];
                        icrtvc.avatarImageView.layer.masksToBounds = YES;
                    }
                }
            }
            break;
        }
            
        case MEGARequestTypeInviteContact:
            switch (request.number.integerValue) {                    
                case 1:
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"requestCancelled", nil)];
                    break;
                    
                default:
                    break;
            }
            break;
            
            
        case MEGARequestTypeReplyContactRequest:
            switch (request.number.integerValue) {
                case 0:
                    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"requestAccepted", nil)];
                    break;
                    
                case 1:
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"requestDeleted", nil)];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    [self reloadUI];
}

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self reloadUI];
}

@end
