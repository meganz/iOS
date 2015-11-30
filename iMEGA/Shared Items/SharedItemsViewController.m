/**
 * @file SharedItemsViewController.m
 * @brief View controller that allows to see and manage the incoming and outgoing shares of your account.
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

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "SharedItemsViewController.h"
#import "DetailsNodeInfoViewController.h"
#import "SharedItemsTableViewCell.h"

@interface SharedItemsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate> {
    
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UISegmentedControl *sharedItemsSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leaveShareBarButtonItem;
@property (nonatomic, strong) NSMutableArray *exportLinksMutableArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *getLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *removeShareBarButtonItem;

@property (nonatomic) NSUInteger remainingOperations;
@property (nonatomic) NSIndexPath *indexPath;

@property (nonatomic, strong) MEGAShareList *incomingShareList;
@property (nonatomic, strong) NSMutableArray *incomingNodesMutableArray;

@property (nonatomic, strong) MEGAShareList *outgoingShareList;
@property (nonatomic, strong) NSMutableArray *outgoingSharesMutableArray;
@property (nonatomic, strong) NSMutableArray *outgoingNodesMutableArray;

@property (nonatomic, strong) NSMutableDictionary *namesMutableDictionary;
@property (nonatomic) NSUInteger numberOfShares;

@property (nonatomic, strong) NSMutableArray *selectedNodesMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedSharesMutableArray;

@end

@implementation SharedItemsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    _namesMutableDictionary = [[NSMutableDictionary alloc] init];
    
    [self.navigationController.view setBackgroundColor:megaLightGray];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.navigationItem setTitle:AMLocalizedString(@"sharedItems", nil)];
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    [self.navigationItem setRightBarButtonItems:@[negativeSpaceBarButtonItem, self.editBarButtonItem] animated:YES];
    
    [_sharedItemsSegmentedControl setTitle:AMLocalizedString(@"incoming", nil) forSegmentAtIndex:0];
    [_sharedItemsSegmentedControl setTitle:AMLocalizedString(@"outgoing", nil) forSegmentAtIndex:1];
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
    
    if ([self.tableView isEditing]) {
        [self setEditing:NO animated:NO];
    }
    
    [_namesMutableDictionary removeAllObjects];
    
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

#pragma mark - Private

- (void)reloadUI {
    
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: {
            [self incomingNodes];
            break;
        }
            
        case 1: {
            [self outgoingNodes];
            break;
        }
    }
    
    [self.tableView reloadData];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    [self toolbarItemsSetEnabled:boolValue];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    
    [self.editBarButtonItem setEnabled:boolValue];
}

- (void)toolbarItemsSetEnabled:(BOOL)boolValue {
    [_downloadBarButtonItem setEnabled:boolValue];
    [_carbonCopyBarButtonItem setEnabled:boolValue];
    [_leaveShareBarButtonItem setEnabled:boolValue];
    
    [_getLinkBarButtonItem setEnabled:boolValue];
    [_shareFolderBarButtonItem setEnabled:boolValue];
    [_removeShareBarButtonItem setEnabled:boolValue];
}

- (void)incomingNodes {
    _incomingShareList = [[MEGASdkManager sharedMEGASdk] inSharesList];
    _incomingNodesMutableArray = [[NSMutableArray alloc] init];
    NSUInteger count = [[_incomingShareList size] unsignedIntegerValue];
    for (NSUInteger i = 0; i < count; i++) {
        MEGAShare *share = [_incomingShareList shareAtIndex:i];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:share.nodeHandle];
        [_incomingNodesMutableArray addObject:node];
    }
}

- (void)outgoingNodes {
    _outgoingShareList = [[MEGASdkManager sharedMEGASdk] outShares];
    _outgoingSharesMutableArray = [[NSMutableArray alloc] init];
    
    NSString *lastBase64Handle = @"";
    _outgoingNodesMutableArray = [[NSMutableArray alloc] init];
    
    NSUInteger count = [[_outgoingShareList size] unsignedIntegerValue];
    for (NSUInteger i = 0; i < count; i++) {
        MEGAShare *share = [_outgoingShareList shareAtIndex:i];
        if ([share user] != nil) {
            [_outgoingSharesMutableArray addObject:share];
            
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:share.nodeHandle];
            
            if (![lastBase64Handle isEqualToString:[node base64Handle]]) {
                lastBase64Handle = [node base64Handle];
                [_outgoingNodesMutableArray addObject:node];
            }
        }
    }
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

- (void)toolbarItemsForSharedItems {
    
    NSMutableArray *toolbarItemsMutableArray = [[NSMutableArray alloc] init];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            [toolbarItemsMutableArray addObjectsFromArray:@[_downloadBarButtonItem, flexibleItem, _carbonCopyBarButtonItem, flexibleItem, _leaveShareBarButtonItem]];
            break;
        }
            
        case 1: { //Outgoing
            [toolbarItemsMutableArray addObjectsFromArray:@[_getLinkBarButtonItem, flexibleItem, _shareFolderBarButtonItem, flexibleItem, _removeShareBarButtonItem]];
            break;
        }
    }
    
    [_toolbar setItems:toolbarItemsMutableArray];
}

- (UIImage *)permissionsButtonImageFor:(MEGAShareType)shareType {
    UIImage *image;
    switch (shareType) {
        case MEGAShareTypeAccessRead:
            image = [UIImage imageNamed:@"readPermissions"];
            break;
            
        case MEGAShareTypeAccessReadWrite:
            image =  [UIImage imageNamed:@"readWritePermissions"];
            break;
            
        case MEGAShareTypeAccessFull:
            image = [UIImage imageNamed:@"fullAccessPermissions"];
            break;
            
        default:
            image = nil;
            break;
    }
    
    return image;
}

- (void)removeSelectedShares {
    for (MEGAShare *share in _selectedSharesMutableArray) {
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[share nodeHandle]];
        [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:[share user] level:MEGAShareTypeAccessUnkown delegate:self];
    }
}

#pragma mark - IBActions

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"edit"]];
    [self setEditing:value animated:YES];
    
    if (value) {
        _selectedNodesMutableArray = [[NSMutableArray alloc] init];
        _selectedSharesMutableArray = [[NSMutableArray alloc] init];
        
        [self toolbarItemsForSharedItems];
        [self toolbarItemsSetEnabled:NO];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        }
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allNodesSelected = NO;
        [_selectedNodesMutableArray removeAllObjects];
        [_selectedSharesMutableArray removeAllObjects];
        self.navigationItem.leftBarButtonItems = @[];
    }
    
    if (!self.selectedNodesMutableArray) {
        _selectedNodesMutableArray = [[NSMutableArray alloc] init];
        _selectedSharesMutableArray = [[NSMutableArray alloc] init];
        
        [self toolbarItemsSetEnabled:NO];
    }
    
    [self.tabBarController.tabBar addSubview:self.toolbar];
    
    [UIView animateWithDuration:animated ? .33 : 0 animations:^{
        self.toolbar.frame = CGRectMake(0, editing ? 0 : 49 , CGRectGetWidth(self.view.frame), 49);
    }];
    
    isSwipeEditing = NO;
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [_selectedSharesMutableArray removeAllObjects];
    [_selectedNodesMutableArray removeAllObjects];
    
    if (!allNodesSelected) {
        MEGANode *n = nil;
        MEGAShare *s = nil;
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                NSUInteger count = [[_incomingShareList size] unsignedIntegerValue];
                for (NSInteger i = 0; i < count; i++) {
                    s = [_incomingShareList shareAtIndex:i];
                    n = [_incomingNodesMutableArray objectAtIndex:i];
                    [_selectedSharesMutableArray addObject:s];
                    [_selectedNodesMutableArray addObject:n];
                }
                break;
            }
                
            case 1: { //Outgoing
                NSUInteger count = [_outgoingNodesMutableArray count];
                for (NSInteger i = 0; i < count; i++) {
                    n = [_outgoingNodesMutableArray objectAtIndex:i];
                    [_selectedSharesMutableArray addObjectsFromArray:[self outSharesForNode:n]];
                    [_selectedNodesMutableArray addObject:n];
                }
                break;
            }
        }
        allNodesSelected = YES;
    } else {
        allNodesSelected = NO;
    }
    
    if (self.selectedNodesMutableArray.count == 0) {
        [self toolbarItemsSetEnabled:NO];
    } else if (self.selectedNodesMutableArray.count >= 1) {
        [self toolbarItemsSetEnabled:YES];
    }
    
    [self.tableView reloadData];
}

- (IBAction)sharedItemsSegmentedControlValueChanged:(UISegmentedControl *)sender {
    if ([_tableView isEditing]) {
        [_selectedNodesMutableArray removeAllObjects];
        [_selectedSharesMutableArray removeAllObjects];
        
        if (allNodesSelected) {
            [self selectAllAction:_selectAllBarButtonItem];
        }

        [self toolbarItemsForSharedItems];
        [self toolbarItemsSetEnabled:NO];
    }
    
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            [self incomingNodes];
            break;
        }
            
        case 1: { //Outgoing
            [self outgoingNodes];
            break;
        }
    }
    
    [self.tableView reloadData];
}

- (IBAction)permissionsTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                break;
            }
                
            case 1: { //Outgoing
                ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
                [contactsVC setContactsMode:ContactsFolderSharedWith];
                
                CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
                NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
                MEGANode *node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
                [contactsVC setNode:node];
                [contactsVC setNamesMutableDictionary:_namesMutableDictionary];
                [self.navigationController pushViewController:contactsVC animated:YES];
                break;
            }
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = nil;
    MEGAShare *share = nil;
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            node = [_incomingNodesMutableArray objectAtIndex:indexPath.row];
            share = [_incomingShareList shareAtIndex:indexPath.row];
            break;
        }
            
        case 1: { //Outgoing
            node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
            share = [_outgoingSharesMutableArray objectAtIndex:indexPath.row];
            break;
        }
    }
    
    DetailsNodeInfoViewController *detailsNodeInfoVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
    [detailsNodeInfoVC setDisplayMode:DisplayModeSharedItem];
    
    NSString *email = [share user];
    NSString *userName = [_namesMutableDictionary objectForKey:email];
    if (userName == nil) {
        [detailsNodeInfoVC setUserName:email];
    } else {
        [detailsNodeInfoVC setUserName:userName];
    }
    [detailsNodeInfoVC setEmail:email];
    [detailsNodeInfoVC setNode:node];

    [self.navigationController pushViewController:detailsNodeInfoVC animated:YES];
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        for (MEGANode *n in _selectedNodesMutableArray) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:n isFolderLink:NO]) {
                [self setEditing:NO animated:YES];
                return;
            }
        }
        
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
        
        for (MEGANode *n in _selectedNodesMutableArray) {
            [Helper downloadNode:n folderPath:[Helper pathForOffline] isFolderLink:NO];
        }
        
        [self setEditing:NO animated:YES];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
        browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesMutableArray];
        [browserVC setBrowserAction:BrowserActionCopy];
        
        [self setEditing:NO animated:YES];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)leaveShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        _remainingOperations = [_selectedNodesMutableArray count];
        _numberOfShares = _remainingOperations;
        for (NSInteger i = 0; i < self.selectedNodesMutableArray.count; i++) {
            [[MEGASdkManager sharedMEGASdk] removeNode:[_selectedNodesMutableArray objectAtIndex:i] delegate:self];
        }
        
        [self setEditing:NO animated:YES];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        _exportLinksMutableArray = [[NSMutableArray alloc] init];
        _remainingOperations = _selectedNodesMutableArray.count;
        
        for (MEGANode *n in _selectedNodesMutableArray) {
            [[MEGASdkManager sharedMEGASdk] exportNode:n delegate:self];
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)shareFolderAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
        ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
        [contactsVC setContactsMode:ContactsShareFoldersWith];
        [contactsVC setNodesArray:[_selectedNodesMutableArray copy]];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        [self setEditing:NO animated:YES];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)removeShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        _numberOfShares = 0;
        NSUInteger outSharesCount = 0;
        for (MEGANode *node in _selectedNodesMutableArray) {
            NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:node];
            outSharesCount = [outSharesOfNodeMutableArray count];
            if (outSharesCount > 1) {
                _numberOfShares += outSharesCount;
            } else {
                _numberOfShares = outSharesCount;
            }
            
            [_selectedSharesMutableArray addObjectsFromArray:outSharesOfNodeMutableArray];
        }
        
        _remainingOperations = _numberOfShares;
        
        NSString *alertMessage;
        if ((outSharesCount == 1) && ([_selectedNodesMutableArray count] == 1)) {
            alertMessage = AMLocalizedString(@"removeOneShareOneContactMessage", nil);
        } else if ((outSharesCount > 1) && ([_selectedNodesMutableArray count] == 1)) {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeOneShareMultipleContactsMessage", nil), _numberOfShares];
        } else {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeMultipleSharesMultipleContactsMessage", nil), _numberOfShares];
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeSharing", nil) message:alertMessage delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        [alertView setTag:0];
        [alertView setDelegate:self];
        [alertView show];
        
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    switch ([alertView tag]) {
        case 0: {
            if (buttonIndex == 1) {
                if ([MEGAReachabilityManager isReachable]) {
                    [self removeSelectedShares];
                    
                    [self setEditing:NO animated:YES];
                } else {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                numberOfRows = [_incomingNodesMutableArray count];
                break;
            }
                
            case 1:  { //Outgoing
                numberOfRows = [_outgoingNodesMutableArray count];
                break;
            }
        }
    }
    
    if (numberOfRows == 0) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        } else {
            [self setEditing:NO animated:NO];
            [self setNavigationBarButtonItemsEnabled:NO];
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        }
    } else {
        [self setNavigationBarButtonItemsEnabled:YES];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SharedItemsTableViewCell *cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"sharedItemsTableViewCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[SharedItemsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sharedItemsTableViewCell"];
    }
    
    MEGAShare *share = nil;
    MEGANode *node = nil;
    NSUInteger outSharesCount = 1;
    
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            
            share = [_incomingShareList shareAtIndex:indexPath.row];
            node = [_incomingNodesMutableArray objectAtIndex:indexPath.row];
            
            [cell.thumbnailImageView setImage:[Helper incomingFolderImage]];
            
            [cell.nameLabel setText:[node name]];
            
            NSString *userName = [_namesMutableDictionary objectForKey:[share user]];
            if (userName ==  nil) {
                userName = [share user];
                MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:userName];
                [[MEGASdkManager sharedMEGASdk] getUserAttibuteForUser:user type:1 delegate:self];
                [[MEGASdkManager sharedMEGASdk] getUserAttibuteForUser:user type:2 delegate:self];
            }
            
            [cell.infoLabel setText:userName];
            
            [cell.permissionsButton setImage:[self permissionsButtonImageFor:[share access]] forState:UIControlStateNormal];
            
            cell.nodeHandle = [node handle];
            
            break;
        }
            
        case 1: { //Outgoing
            
            share = [_outgoingSharesMutableArray objectAtIndex:indexPath.row];
            node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
            
            [cell.thumbnailImageView setImage:[Helper outgoingFolderImage]];
            
            [cell.nameLabel setText:[node name]];
            
            NSString *userName;
            NSMutableArray *outSharesMutableArray = [self outSharesForNode:node];
            outSharesCount = [outSharesMutableArray count];
            if (outSharesCount > 1) {
                userName = [NSString stringWithFormat:AMLocalizedString(@"sharedWithXContacts", nil), outSharesCount];
            } else {
                userName = [_namesMutableDictionary objectForKey:[share user]];
                if (userName ==  nil) {
                    userName = [share user];
                    if (userName != nil) {
                        MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:userName];
                        [[MEGASdkManager sharedMEGASdk] getUserAttibuteForUser:user type:1 delegate:self];
                        [[MEGASdkManager sharedMEGASdk] getUserAttibuteForUser:user type:2 delegate:self];
                    }
                }
            }
            
            [cell.permissionsButton setImage:[UIImage imageNamed:@"permissions"] forState:UIControlStateNormal];
            
            [cell.infoLabel setText:userName];
            
            cell.nodeHandle = [share nodeHandle];
            
            break;
        }
    }
    
    [cell.thumbnailImageView.layer setCornerRadius:4];
    [cell.thumbnailImageView.layer setMasksToBounds:YES];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    if ([tableView isEditing]) {
        for (MEGANode *n in _selectedNodesMutableArray) {
            if ([n handle] == [node handle]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node;
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            node = [_incomingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
            
        case 1: { //Outgoing
            node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
    }
    
    if (tableView.isEditing) {
        [_selectedNodesMutableArray addObject:node];
        
        [self toolbarItemsSetEnabled:YES];
        
        NSUInteger nodeListSize = 0;
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                nodeListSize = [_incomingNodesMutableArray count];
                break;
            }
                
            case 1: { //Outgoing
                nodeListSize = [_outgoingNodesMutableArray count];
                break;
            }
        }
        
        if (self.selectedNodesMutableArray.count == nodeListSize) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
        
        return;
    }

    switch ([node type]) {
        case MEGANodeTypeFolder: {
            CloudDriveTableViewController *cloudTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            [cloudTVC setParentNode:node];
            [cloudTVC setDisplayMode:DisplayModeCloudDrive];
            [self.navigationController pushViewController:cloudTVC animated:YES];
            break;
        }
        
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node;

    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            node = [_incomingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
            
        case 1: { //Outgoing
            node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
    }
    
    if (tableView.isEditing) {
        
        NSMutableArray *tempNodesMutableArray = [_selectedNodesMutableArray copy];
        for (MEGANode *n in tempNodesMutableArray) {
            if ([n handle] == node.handle) {
                [_selectedNodesMutableArray removeObject:n];
            }
        }
        
        if (self.selectedNodesMutableArray.count == 0) {
            [self toolbarItemsSetEnabled:NO];
        }
        
        allNodesSelected = NO;
        
        return;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = nil;
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            node = [_incomingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
            
        case 1: { //Outgoing
            node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
    }
    
    _selectedNodesMutableArray = [[NSMutableArray alloc] init];
    [_selectedNodesMutableArray addObject:node];
    
    [self toolbarItemsSetEnabled:YES];
    
    isSwipeEditing = YES;
    
    return UITableViewCellEditingStyleDelete;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        text = @" ";
    } else {
        text = AMLocalizedString(@"noInternetConnection",  nil);
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaBlack};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                text = AMLocalizedString(@"noIncomingSharedItemsEmptyState_text", nil);
                break;
            }
                
            case 1: { //Outgoing
                text = AMLocalizedString(@"noOutgoingSharedItemsEmptyState_text", nil);
                break;
            }
        }
    } else {
        text = @"";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0],
                                 NSForegroundColorAttributeName:megaGray,
                                 NSParagraphStyleAttributeName:paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                image = [UIImage imageNamed:@"emptySharedItemsIncoming"];
                break;
            }
                
            case 1: { //Outgoing
                image = [UIImage imageNamed:@"emptySharedItemsOutgoing"];
                break;
            }
        }
    } else {
        image = [UIImage imageNamed:@"noInternetConnection"];
    }
    
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeExport:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudLink"] status:AMLocalizedString(@"generatingLink", nil)];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeExport: {
            _remainingOperations--;
            
            NSString *link = [NSString stringWithFormat:@"%@\n", [request link]];
            [_exportLinksMutableArray addObject:link];
            
            if (_remainingOperations == 0) {
                [SVProgressHUD dismiss];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:_exportLinksMutableArray applicationActivities:nil];
                activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList];
                
                if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                    activityVC.popoverPresentationController.barButtonItem = _getLinkBarButtonItem;
                }
                
                [self presentViewController:activityVC animated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeGetAttrUser: {
            NSString *name;
            switch ([request paramType]) {
                case MEGAUserAttributeFirstname:
                    name = [request text];
                    if (name != nil) {
                        [_namesMutableDictionary setObject:name forKey:[request email]];
                    } else {
                        [_namesMutableDictionary setObject:[request email] forKey:[request email]];
                    }
                    break;
                    
                case MEGAUserAttributeLastname:
                    name = [_namesMutableDictionary objectForKey:[request email]];
                    name = [name stringByAppendingString:[NSString stringWithFormat:@" %@", [request text]]];
                    [_namesMutableDictionary setObject:name forKey:[request email]];
                    break;
            }
            
            [self.tableView reloadData];
            
            break;
        }
            
        case MEGARequestTypeShare: {
            
            _remainingOperations--;
            
            if (_remainingOperations == 0) {
                switch ([request access]) {
                    case MEGAShareTypeAccessUnkown:
                        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"shareRemoved", nil)];
                        [self setEditing:NO animated:YES];
                        break;
                        
                    case MEGAShareTypeAccessRead:
                    case MEGAShareTypeAccessReadWrite:
                    case MEGANodeAccessLevelFull:
                        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"permissionsChanged", nil)];
                        break;
                        
                    default:
                        break;
                }
                
                [self reloadUI];
            }
            
            break;
        }
            
        case MEGARequestTypeRemove: {
            
            _remainingOperations--;
            
            if (_remainingOperations == 0) {
                
                if (_numberOfShares > 1) {
                    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"sharesLeft", nil)];
                } else {
                    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"shareLeft", nil)];
                }
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

@end
