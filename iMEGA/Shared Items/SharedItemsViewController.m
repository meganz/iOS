#import "SharedItemsViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "DetailsNodeInfoViewController.h"
#import "SharedItemsTableViewCell.h"

@interface SharedItemsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate> {
    
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *sharedItemsSegmentedControlView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sharedItemsSegmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leaveShareBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
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

@property (nonatomic, strong) NSMutableArray *userNamesRequestedMutableArray;
@property (nonatomic, strong) NSMutableDictionary *incomingNodesForEmailMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *incomingIndexPathsMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *outgoingNodesForEmailMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *outgoingIndexPathsMutableDictionary;

@end

@implementation SharedItemsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    _namesMutableDictionary = [[NSMutableDictionary alloc] init];
    
    [self.navigationController.view setBackgroundColor:[UIColor mnz_grayF9F9F9]];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    if (self.sharedItemsMode == SharedItemsModeDefault) {
        self.navigationItem.title = AMLocalizedString(@"sharedItems", nil);
    } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
        self.navigationItem.title = [self.user email];
        
        self.sharedItemsSegmentedControlView.hidden = YES;
        self.tableViewTopConstraint.constant = -self.sharedItemsSegmentedControlView.frame.size.height;
    }
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhone6XPlus]) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    [self.navigationItem setRightBarButtonItems:@[negativeSpaceBarButtonItem, self.editBarButtonItem] animated:YES];
    
    [_sharedItemsSegmentedControl setTitle:AMLocalizedString(@"incoming", nil) forSegmentAtIndex:0];
    [_sharedItemsSegmentedControl setTitle:AMLocalizedString(@"outgoing", nil) forSegmentAtIndex:1];
    
    _userNamesRequestedMutableArray = [[NSMutableArray alloc] init];
    _incomingNodesForEmailMutableDictionary = [[NSMutableDictionary alloc] init];
    _incomingIndexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    _outgoingNodesForEmailMutableDictionary = [[NSMutableDictionary alloc] init];
    _outgoingIndexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    
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
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - Private

- (void)reloadUI {
    if (self.sharedItemsMode == SharedItemsModeDefault) {
        switch (self.sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: {
                [self incomingNodes];
                break;
            }
                
            case 1: {
                [self outgoingNodes];
                break;
            }
        }
    } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
        [self incomingNodes];
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
    
    [self.shareBarButtonItem setEnabled:((self.selectedNodesMutableArray.count < 100) ? boolValue : NO)];
    [_shareFolderBarButtonItem setEnabled:boolValue];
    [_removeShareBarButtonItem setEnabled:boolValue];
}

- (void)incomingNodes {
    [_incomingNodesForEmailMutableDictionary removeAllObjects];
    [_incomingIndexPathsMutableDictionary removeAllObjects];
    
    self.incomingNodesMutableArray = [[NSMutableArray alloc] init];
    
    if (self.sharedItemsMode == SharedItemsModeDefault) {
        self.incomingShareList = [[MEGASdkManager sharedMEGASdk] inSharesList];
        NSUInteger count = [[self.incomingShareList size] unsignedIntegerValue];
        for (NSUInteger i = 0; i < count; i++) {
            MEGAShare *share = [self.incomingShareList shareAtIndex:i];
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:share.nodeHandle];
            [self.incomingNodesMutableArray addObject:node];
        }
    } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
        MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdk] inSharesForUser:self.user];
        NSUInteger count = nodeList.size.unsignedIntegerValue;
        for (NSUInteger i = 0; i < count; i++) {
            MEGANode *node = [nodeList nodeAtIndex:i];
            [self.incomingNodesMutableArray addObject:node];
        }
    }
}

- (void)outgoingNodes {
    [_outgoingNodesForEmailMutableDictionary removeAllObjects];
    [_outgoingIndexPathsMutableDictionary removeAllObjects];
    
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
            [toolbarItemsMutableArray addObjectsFromArray:@[self.shareBarButtonItem, flexibleItem, _shareFolderBarButtonItem, flexibleItem, _carbonCopyBarButtonItem, flexibleItem, _removeShareBarButtonItem]];
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

- (void)removeSelectedIncomingShares {
    self.remainingOperations = [self.selectedNodesMutableArray count];
    self.numberOfShares = self.remainingOperations;
    for (NSInteger i = 0; i < self.selectedNodesMutableArray.count; i++) {
        [[MEGASdkManager sharedMEGASdk] removeNode:[self.selectedNodesMutableArray objectAtIndex:i] delegate:self];
    }
    
    [self setEditing:NO animated:YES];
}

- (void)selectedSharesOfSelectedNodes {
    self.numberOfShares = 0;
    self.selectedSharesMutableArray = [[NSMutableArray alloc] init];
    for (MEGANode *node in self.selectedNodesMutableArray) {
        NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:node];
        self.numberOfShares += [outSharesOfNodeMutableArray count];
        [self.selectedSharesMutableArray addObjectsFromArray:outSharesOfNodeMutableArray];
    }
    
    self.remainingOperations = self.numberOfShares;
}

- (void)removeSelectedOutgoingShares {
    for (MEGAShare *share in _selectedSharesMutableArray) {
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[share nodeHandle]];
        [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:[share user] level:MEGAShareTypeAccessUnkown delegate:self];
    }
    
    [self setEditing:NO animated:YES];
}

- (void)requestUserName:(NSString *)userEmail {
    
    BOOL isUserNameAlreadyRequested = [_userNamesRequestedMutableArray containsObject:userEmail];
    if (!isUserNameAlreadyRequested) {
        MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:userEmail];
        [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeFirstname delegate:self];
        [[MEGASdkManager sharedMEGASdk] getUserAttributeForUser:user type:MEGAUserAttributeLastname delegate:self];
        [_userNamesRequestedMutableArray addObject:userEmail];
    }
}

- (NSArray *)indexPathsForUserEmail:(NSString *)email {
    NSMutableArray *indexPathsMutableArray = [[NSMutableArray alloc] init];
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            NSArray *base64HandleArray = [_incomingNodesForEmailMutableDictionary allKeysForObject:email];
            indexPathsMutableArray = [[_incomingIndexPathsMutableDictionary objectsForKeys:base64HandleArray notFoundMarker:[NSNull null]] mutableCopy];
            break;
        }
            
        case 1: { //Outgoing
            NSArray *base64HandleArray = [_outgoingNodesForEmailMutableDictionary allKeysForObject:email];
            indexPathsMutableArray = [[_outgoingIndexPathsMutableDictionary objectsForKeys:base64HandleArray notFoundMarker:[NSNull null]] mutableCopy];
            break;
        }
    }
    
    [indexPathsMutableArray removeObjectsInArray:[NSArray arrayWithObject:[NSNull null]]];
    
    return indexPathsMutableArray;
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
    [super setEditing:editing animated:animated];
    
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
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
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
    
    NSString *email = (self.sharedItemsMode == SharedItemsModeDefault) ? [share user] : [self.user email];
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
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        for (MEGANode *n in _selectedNodesMutableArray) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:n isFolderLink:NO]) {
                [self setEditing:NO animated:YES];
                return;
            }
        }
        
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
        
        for (MEGANode *n in _selectedNodesMutableArray) {
            [Helper downloadNode:n folderPath:[Helper relativePathForOffline] isFolderLink:NO];
        }
        
        [self setEditing:NO animated:YES];
    }
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
        browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesMutableArray];
        [browserVC setBrowserAction:BrowserActionCopy];
        
        [self setEditing:NO animated:YES];
    }
}

- (IBAction)leaveShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertMessage = (_selectedNodesMutableArray.count > 1) ? AMLocalizedString(@"leaveSharesAlertMessage", @"Alert message shown when the user tap on the leave share action selecting multipe inshares") : AMLocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"leaveFolder", nil) message:alertMessage delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        alertView.tag = 0;
        [alertView show];
    }
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:self.selectedNodesMutableArray button:self.shareBarButtonItem];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)shareFolderAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
        ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
        [contactsVC setContactsMode:ContactsShareFoldersWith];
        [contactsVC setNodesArray:[_selectedNodesMutableArray copy]];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        [self setEditing:NO animated:YES];
    }
}

- (IBAction)removeShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self selectedSharesOfSelectedNodes];
        
        NSString *alertMessage;
        if ((self.numberOfShares == 1) && ([_selectedNodesMutableArray count] == 1)) {
            alertMessage = AMLocalizedString(@"removeOneShareOneContactMessage", nil);
        } else if ((self.numberOfShares > 1) && ([_selectedNodesMutableArray count] == 1)) {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeOneShareMultipleContactsMessage", nil), _numberOfShares];
        } else {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeMultipleSharesMultipleContactsMessage", nil), _numberOfShares];
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeSharing", nil) message:alertMessage delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        alertView.tag = 1;
        [alertView show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch ([alertView tag]) {
            case 0: {
                if (buttonIndex == 1) {
                    [self removeSelectedIncomingShares];
                }
                break;
            }
                
            case 1: {
                if (buttonIndex == 1) {
                    [self removeSelectedOutgoingShares];
                }
                break;
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.sharedItemsMode == SharedItemsModeDefault) {
            switch (self.sharedItemsSegmentedControl.selectedSegmentIndex) {
                case 0: { //Incoming
                    numberOfRows = [self.incomingNodesMutableArray count];
                    break;
                }
                    
                case 1:  { //Outgoing
                    numberOfRows = [self.outgoingNodesMutableArray count];
                    break;
                }
            }
        } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
            numberOfRows = [self.incomingNodesMutableArray count];
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
            
            NSString *userEmail = (self.sharedItemsMode == SharedItemsModeDefault) ? [share user] : [self.user email];
            [self.incomingNodesForEmailMutableDictionary setObject:userEmail forKey:node.base64Handle];
            [_incomingIndexPathsMutableDictionary setObject:indexPath forKey:node.base64Handle];
            
            [cell.thumbnailImageView setImage:[Helper incomingFolderImage]];
            
            [cell.nameLabel setText:[node name]];
            
            NSString *userName = [self.namesMutableDictionary objectForKey:userEmail];
            if (userName ==  nil) {
                userName = userEmail;
                [self requestUserName:userName];
            }
            
            NSString *infoLabelText = (self.sharedItemsMode == SharedItemsModeDefault) ? userName : [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
            [cell.infoLabel setText:infoLabelText];
            
            MEGAShareType shareType = (self.sharedItemsMode == SharedItemsModeDefault) ? [share access] : [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
            [cell.permissionsButton setImage:[self permissionsButtonImageFor:shareType] forState:UIControlStateNormal];
            
            cell.nodeHandle = [node handle];
            
            break;
        }
            
        case 1: { //Outgoing
            
            share = [_outgoingSharesMutableArray objectAtIndex:indexPath.row];
            node = [_outgoingNodesMutableArray objectAtIndex:indexPath.row];
            
            [_outgoingNodesForEmailMutableDictionary setObject:[share user] forKey:node.base64Handle];
            [_outgoingIndexPathsMutableDictionary setObject:indexPath forKey:node.base64Handle];
            
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
                        [self requestUserName:userName];
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
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (self.sharedItemsMode == SharedItemsModeDefault) {
            switch (self.sharedItemsSegmentedControl.selectedSegmentIndex) {
                case 0: { //Incoming
                    [self removeSelectedIncomingShares];
                    break;
                }
                    
                case 1: { //Outgoing
                    [self selectedSharesOfSelectedNodes];
                    [self removeSelectedOutgoingShares];
                    break;
                }
            }
        } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
            [self removeSelectedIncomingShares];
        }
    }
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
        if (node != nil) {
            [_selectedNodesMutableArray addObject:node];
        }
        
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

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self toolbarItemsForSharedItems];
    [self setEditing:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setEditing:NO animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = nil;
    if (self.sharedItemsMode == SharedItemsModeDefault) {
        switch (self.sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: //Incoming
                node = [self.incomingNodesMutableArray objectAtIndex:indexPath.row];
                break;
                
            case 1: //Outgoing
                node = [self.outgoingNodesMutableArray objectAtIndex:indexPath.row];
                break;
        }
    } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
        node = [self.incomingNodesMutableArray objectAtIndex:indexPath.row];
    }
    
    self.selectedNodesMutableArray = [[NSMutableArray alloc] init];
    if (node != nil) {
        [self.selectedNodesMutableArray addObject:node];
    }
    
    [self toolbarItemsSetEnabled:YES];
    
    isSwipeEditing = YES;
    
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *titleForDeleteConfirmationButton;
    if (self.sharedItemsMode == SharedItemsModeDefault) {
        switch (self.sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: //Incoming
                titleForDeleteConfirmationButton = AMLocalizedString(@"leaveFolder", nil);
                break;
                
            case 1: //Outgoing
                titleForDeleteConfirmationButton = AMLocalizedString(@"removeSharing", nil);
                break;
        }
    } else if (self.sharedItemsMode == SharedItemsModeInSharesForUser) {
        titleForDeleteConfirmationButton = AMLocalizedString(@"leaveFolder", nil);
    }
    
    return titleForDeleteConfirmationButton;
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
        text = AMLocalizedString(@"noInternetConnection",  nil);
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
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

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    for (NSInteger i = 0 ; i < userList.size.integerValue ; i++) {
        NSString *userEmail = [[userList userAtIndex:i] email];
        [self.namesMutableDictionary removeObjectForKey:userEmail];
    }
    [self reloadUI];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrUser: {
            NSString *name;
            NSString *email = [request email];
            switch ([request paramType]) {
                case MEGAUserAttributeFirstname: {
                    name = [request text];
                    if (name != nil) {
                        [_namesMutableDictionary setObject:name forKey:email];
                    } else {
                        [_namesMutableDictionary setObject:email forKey:email];
                    }
                    break;
                }
                    
                case MEGAUserAttributeLastname: {
                    name = [_namesMutableDictionary objectForKey:email];
                    BOOL isNameEmpty = NO;
                    if (name != nil) {
                        name = [name stringByAppendingString:[NSString stringWithFormat:@" %@", [request text]]];
                        isNameEmpty = [[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
                        if (isNameEmpty) {
                            name = email;
                        }
                        [_namesMutableDictionary setObject:name forKey:email];
                    } else {
                        [_namesMutableDictionary setObject:email forKey:email];
                    }
                    
                    [_userNamesRequestedMutableArray removeObject:email];
                    
                    NSArray *indexPathsArray = [self indexPathsForUserEmail:email];
                    if (indexPathsArray != nil && !isNameEmpty) {
                        [self.tableView reloadRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationNone];
                    }
                    break;
                }
            }
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

@end
