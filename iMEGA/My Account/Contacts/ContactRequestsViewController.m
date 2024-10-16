#import "ContactRequestsViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "UIImage+GKContact.h"
#import "SVProgressHUD.h"

#import "ContactRequestsTableViewCell.h"
#import "EmptyStateView.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"
#import "NSDate+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

typedef NS_ENUM(NSInteger, Segment) {
    SegmentReceived = 0,
    SegmentSent
};

@interface ContactRequestsViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAGlobalDelegate>

@property (nonatomic, strong) NSMutableArray *outgoingContactRequestArray;
@property (nonatomic, strong) NSMutableArray *incomingContactRequestArray;

@property (weak, nonatomic) IBOutlet UISegmentedControl *contactRequestsSegmentedControl;

@property (nonatomic) NSUInteger remainingOperations;

@property (nonatomic, getter=isAcceptingOrDecliningLastRequest) BOOL acceptingOrDecliningLastRequest;
@property (nonatomic, getter=isDeletingLastRequest) BOOL deletingLastRequest;
@property (nonatomic, getter=isPerformingRequest) BOOL performingRequest;

@property (nonatomic, strong) NSRelativeDateTimeFormatter *relativeDateTimeFormatter;

@end

@implementation ContactRequestsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.navigationItem.titleView = self.contactRequestsSegmentedControl;
    
    self.relativeDateTimeFormatter = NSRelativeDateTimeFormatter.alloc.init;
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self.navigationItem setTitle:LocalizedString(@"contactRequests", @"Contact requests")];
    
    [self.contactRequestsSegmentedControl setTitle:LocalizedString(@"received", @"Title of one of the filters in 'Contacts requests' section. If 'Received' is selected, it will only show the requests which have been recieved.") forSegmentAtIndex:SegmentReceived];
    [self.contactRequestsSegmentedControl setTitle:LocalizedString(@"sent", @"Title of one of the filters in 'Contacts requests' section. If 'Sent' is selected, it will only show the requests which have been sent out.") forSegmentAtIndex:SegmentSent];
    
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared removeMEGAGlobalDelegate:self];
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
        case SegmentReceived:
            [self reloadIncomingContactsRequestsView];
            break;
            
        case SegmentSent:
            [self reloadOutgoingContactsRequestsView];
            break;
            
        default:
            break;
    }
    
    [self.tableView reloadData];
    
    self.performingRequest = NO;
}

- (void)reloadOutgoingContactsRequestsView {
    self.outgoingContactRequestArray = [[NSMutableArray alloc] init];
    
    MEGAContactRequestList *outgoingContactRequestList = [MEGASdk.shared outgoingContactRequests];
    for (NSInteger i = 0; i < outgoingContactRequestList.size; i++) {
        MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
        [self.outgoingContactRequestArray addObject:contactRequest];
    }
    
    //If user cancel all sent requests and HAS incoming requests > Switch to Received
    //If user cancel all sent requests and HAS NOT incoming requests > Go back to Contacts
    if (outgoingContactRequestList.size == 0 && self.isDeletingLastRequest) {
        MEGAContactRequestList *incomingContactRequestList = MEGASdk.shared.incomingContactRequests;
        if (incomingContactRequestList.size == 0) {
            if (self.presentingViewController) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } else {
            self.contactRequestsSegmentedControl.selectedSegmentIndex = SegmentReceived;
        }
        
        self.deletingLastRequest = NO;
    }
}

- (void)reloadIncomingContactsRequestsView {
    self.incomingContactRequestArray = [[NSMutableArray alloc] init];
    
    MEGAContactRequestList *incomingContactRequestList = [MEGASdk.shared incomingContactRequests];
    for (NSInteger i = 0; i < incomingContactRequestList.size; i++) {
        MEGAContactRequest *contactRequest = [incomingContactRequestList contactRequestAtIndex:i];
        [self.incomingContactRequestArray addObject:contactRequest];
    }
    
    //If user accepts all received requests > Go back to Contacts
    //If user accepts all received requests and HAS sent requests > Go back to Contacts
    if (incomingContactRequestList.size == 0 && self.isAcceptingOrDecliningLastRequest) {
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        self.acceptingOrDecliningLastRequest = NO;
    }
}

#pragma mark - IBActions

- (IBAction)contactsSegmentedControlValueChanged:(UISegmentedControl *)sender {
    [self reloadUI];
}

- (void)acceptTouchUpInside:(UIButton *)sender {
    if (self.isPerformingRequest) {
        return;
    }
    if (sender.tag < self.incomingContactRequestArray.count) {
        MEGAContactRequest *contactSelected = [self.incomingContactRequestArray objectAtIndex:sender.tag];
        [MEGASdk.shared replyContactRequest:contactSelected action:MEGAReplyActionAccept delegate:self];
        
        if (self.incomingContactRequestArray.count == 1) {
            self.acceptingOrDecliningLastRequest = YES;
        }
    }
}

- (void)declineOrDeleteTouchUpInside:(UIButton *)sender {
    if (self.isPerformingRequest) {
        return;
    }
    if (self.contactRequestsSegmentedControl.selectedSegmentIndex == SegmentReceived && sender.tag < self.incomingContactRequestArray.count) {
        MEGAContactRequest *contactSelected = [self.incomingContactRequestArray objectAtIndex:sender.tag];
        [MEGASdk.shared replyContactRequest:contactSelected action:MEGAReplyActionDeny delegate:self];
        
        if (self.incomingContactRequestArray.count == 1) {
            self.acceptingOrDecliningLastRequest = YES;
        }
    } else if (sender.tag < self.outgoingContactRequestArray.count) {
        MEGAContactRequest *contactSelected = [self.outgoingContactRequestArray objectAtIndex:sender.tag];
        [MEGASdk.shared inviteContactWithEmail:[contactSelected targetEmail] message:@"" action:MEGAInviteActionDelete delegate:self];
        
        if (self.outgoingContactRequestArray.count == 1) {
            self.deletingLastRequest = YES;
        }
    }
}
    
#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        switch (self.contactRequestsSegmentedControl.selectedSegmentIndex) {
            case SegmentReceived:
                numberOfRows = [self.incomingContactRequestArray count];
                break;
                
            case SegmentSent:
                numberOfRows = [self.outgoingContactRequestArray count];
                break;
                
            default:
                break;
        }
    }
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactRequestsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IncomingContactRequestsCell" forIndexPath:indexPath];
    
    cell.declineButton.tag = indexPath.row;
    [cell.declineButton addTarget:self action:@selector(declineOrDeleteTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    switch (self.contactRequestsSegmentedControl.selectedSegmentIndex) {
        case SegmentReceived: {
            [cell.acceptButton setHidden:NO];
            cell.acceptButton.tag = indexPath.row;
            [cell.acceptButton addTarget:self action:@selector(acceptTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            
            MEGAContactRequest *contactRequest = [self.incomingContactRequestArray objectAtIndex:indexPath.row];
            NSString *avatarColorString = [MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactRequest.handle]];
            NSString *avatarSecondaryColorString = [MEGASdk avatarSecondaryColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactRequest.handle]];
            cell.avatarImageView.image = [UIImage imageForName:contactRequest.sourceEmail.mnz_initialForAvatar size:cell.avatarImageView.frame.size backgroundColor:[UIColor mnz_fromHexString:avatarColorString] backgroundGradientColor:[UIColor mnz_fromHexString:avatarSecondaryColorString] textColor:UIColor.whiteTextColor font:[UIFont systemFontOfSize:(cell.avatarImageView.frame.size.width/2.0f)]];
            cell.nameLabel.text = [contactRequest sourceEmail];
            cell.timeAgoLabel.text = [self.relativeDateTimeFormatter localizedStringForDate:[contactRequest modificationTime] relativeToDate:NSDate.date];
            
            break;
        }
            
        case SegmentSent: {
            [cell.acceptButton setHidden:YES];
            
            MEGAContactRequest *contactRequest = [self.outgoingContactRequestArray objectAtIndex:indexPath.row];
            NSString *avatarColorString = [MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactRequest.handle]];
            NSString *avatarSecondaryColorString = [MEGASdk avatarSecondaryColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactRequest.handle]];
            cell.avatarImageView.image = [UIImage imageForName:contactRequest.targetEmail.mnz_initialForAvatar size:cell.avatarImageView.frame.size backgroundColor:[UIColor mnz_fromHexString:avatarColorString] backgroundGradientColor:[UIColor mnz_fromHexString:avatarSecondaryColorString] textColor:UIColor.whiteTextColor font:[UIFont systemFontOfSize:(cell.avatarImageView.frame.size.width/2.0f)]];
            cell.nameLabel.text = [contactRequest targetEmail];
            cell.timeAgoLabel.text = [self.relativeDateTimeFormatter localizedStringForDate:[contactRequest modificationTime] relativeToDate:NSDate.date];
            break;
        }
            
        default:
            break;
    }
    
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

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

- (NSString *)titleForEmptyState {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        text = LocalizedString(@"noRequestPending", @"");
    } else {
        text = LocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if ([MEGAReachabilityManager isReachable]) {
        return [UIImage imageNamed:@"contactsEmptyState"];
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeInviteContact || request.type == MEGARequestTypeReplyContactRequest) {
        [SVProgressHUD show];
        self.performingRequest = YES;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([request type] == MEGARequestTypeInviteContact) {
            [SVProgressHUD showErrorWithStatus:LocalizedString(error.name, @"")];
        }
        self.performingRequest = NO;
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrUser: {
            for (ContactRequestsTableViewCell *icrtvc in self.tableView.visibleCells) {
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
            switch (request.number) {
                case 1:
                    [SVProgressHUD showErrorWithStatus:LocalizedString(@"requestCancelled", @"")];
                    break;
                    
                default:
                    break;
            }
            break;
            
            
        case MEGARequestTypeReplyContactRequest:
            switch (request.number) {
                case 0:
                    [SVProgressHUD showSuccessWithStatus:LocalizedString(@"requestAccepted", @"")];
                    break;
                    
                case 1:
                    [SVProgressHUD showErrorWithStatus:LocalizedString(@"requestDeleted", @"")];
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
