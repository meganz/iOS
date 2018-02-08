#import "SharedItemsViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"
#import "NSMutableArray+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "DetailsNodeInfoViewController.h"
#import "SharedItemsTableViewCell.h"

@interface SharedItemsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate, SharedItemsTableViewCellDelegate, MGSwipeTableCellDelegate> {
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
}

@property (nonatomic) id<UIViewControllerPreviewing> previewingContext;

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

@property (nonatomic) NSIndexPath *indexPath;

@property (nonatomic, strong) MEGAShareList *incomingShareList;
@property (nonatomic, strong) NSMutableArray *incomingNodesMutableArray;

@property (nonatomic, strong) MEGAShareList *outgoingShareList;
@property (nonatomic, strong) NSMutableArray *outgoingSharesMutableArray;
@property (nonatomic, strong) NSMutableArray *outgoingNodesMutableArray;

@property (nonatomic, strong) NSMutableArray *selectedNodesMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedSharesMutableArray;

@property (nonatomic, strong) NSMutableDictionary *incomingNodesForEmailMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *incomingIndexPathsMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *outgoingNodesForEmailMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *outgoingIndexPathsMutableDictionary;

@property (nonatomic) NSMutableArray *searchNodesArray;
@property (nonatomic) UISearchController *searchController;

@property (nonatomic, getter=isPseudoEditing) BOOL pseudoEdit;

@end

@implementation SharedItemsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.navigationController.view setBackgroundColor:[UIColor mnz_grayF9F9F9]];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    self.navigationItem.title = AMLocalizedString(@"sharedItems", @"Title of Shared Items section");
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhone6XPlus]) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    [self.navigationItem setRightBarButtonItems:@[negativeSpaceBarButtonItem, self.editBarButtonItem] animated:YES];
    
    [_sharedItemsSegmentedControl setTitle:AMLocalizedString(@"incoming", nil) forSegmentAtIndex:0];
    [_sharedItemsSegmentedControl setTitle:AMLocalizedString(@"outgoing", nil) forSegmentAtIndex:1];
    
    _incomingNodesForEmailMutableDictionary = [[NSMutableDictionary alloc] init];
    _incomingIndexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    _outgoingNodesForEmailMutableDictionary = [[NSMutableDictionary alloc] init];
    _outgoingIndexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    
    // Long press to select:
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    [self.toolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 49)];
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    if (self.searchController && !self.tableView.tableHeaderView) {
        self.tableView.tableHeaderView = self.searchController.searchBar;
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            if (!self.previewingContext) {
                self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
            }
        } else {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}

#pragma mark - Private

- (void)reloadUI {
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
    
    self.incomingShareList = [[MEGASdkManager sharedMEGASdk] inSharesList];
    NSUInteger count = [[self.incomingShareList size] unsignedIntegerValue];
    for (NSUInteger i = 0; i < count; i++) {
        MEGAShare *share = [self.incomingShareList shareAtIndex:i];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:share.nodeHandle];
        [self.incomingNodesMutableArray addObject:node];
    }
    
    if ([self.incomingNodesMutableArray count] == 0) {
        self.tableView.tableHeaderView = nil;
    } else {
        if (!self.tableView.tableHeaderView) {
            self.tableView.tableHeaderView = self.searchController.searchBar;
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
    
    if ([self.outgoingNodesMutableArray count] == 0) {
        self.tableView.tableHeaderView = nil;
    } else {
        if (!self.tableView.tableHeaderView) {
            self.tableView.tableHeaderView = self.searchController.searchBar;
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

- (void)removeSelectedIncomingShares {
    NSArray *filesAndFolders = self.selectedNodesMutableArray.mnz_numberOfFilesAndFolders;
    MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:DisplayModeSharedItem files:[filesAndFolders[0] unsignedIntegerValue] folders:[filesAndFolders[1] unsignedIntegerValue] completion:nil];
    for (NSInteger i = 0; i < self.selectedNodesMutableArray.count; i++) {
        [[MEGASdkManager sharedMEGASdk] removeNode:[self.selectedNodesMutableArray objectAtIndex:i] delegate:removeRequestDelegate];
    }
    
    [self setEditing:NO animated:YES];
}

- (void)selectedSharesOfSelectedNodes {
    self.selectedSharesMutableArray = [[NSMutableArray alloc] init];
    
    for (MEGANode *node in self.selectedNodesMutableArray) {
        NSMutableArray *outSharesOfNodeMutableArray = [self outSharesForNode:node];
        [self.selectedSharesMutableArray addObjectsFromArray:outSharesOfNodeMutableArray];
    }
}

- (void)removeSelectedOutgoingShares {
    MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:self.selectedSharesMutableArray.count completion:^{
        [self setEditing:NO animated:YES];
        [self reloadUI];
    }];
    
    for (MEGAShare *share in self.selectedSharesMutableArray) {
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[share nodeHandle]];
        [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:share.user level:MEGAShareTypeAccessUnkown delegate:shareRequestDelegate];
    }
    
    [self setEditing:NO animated:YES];
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

- (MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath {
    return self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : self.sharedItemsSegmentedControl.selectedSegmentIndex == 0 ? [self.incomingNodesMutableArray objectAtIndex:indexPath.row] : [self.outgoingNodesMutableArray objectAtIndex:indexPath.row];
}

#pragma mark - Utils

- (void)selectSegment:(NSUInteger)index {
    [self.sharedItemsSegmentedControl setSelectedSegmentIndex:index];
}

#pragma mark - IBActions

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    [self setEditing:enableEditing animated:YES];
    
    if (enableEditing) {
        _selectedNodesMutableArray = [[NSMutableArray alloc] init];
        _selectedSharesMutableArray = [[NSMutableArray alloc] init];
        
        [self toolbarItemsForSharedItems];
        [self toolbarItemsSetEnabled:NO];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    self.pseudoEdit = YES;

    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        }
        
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.tabBar addSubview:self.toolbar];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allNodesSelected = NO;
        [_selectedNodesMutableArray removeAllObjects];
        [_selectedSharesMutableArray removeAllObjects];
        self.navigationItem.leftBarButtonItems = @[];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
    
    if (!self.selectedNodesMutableArray) {
        _selectedNodesMutableArray = [[NSMutableArray alloc] init];
        _selectedSharesMutableArray = [[NSMutableArray alloc] init];
        
        [self toolbarItemsSetEnabled:NO];
    }
    
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
    if (self.tableView.isEditing) {
        return;
    }
    
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
            case 0: { //Incoming
                break;
            }
                
            case 1: { //Outgoing
                ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
                contactsVC.contactsMode = ContactsModeFolderSharedWith;
                
                CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
                NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
                MEGANode *node = [self nodeAtIndexPath:indexPath];
                [contactsVC setNode:node];
                [self.navigationController pushViewController:contactsVC animated:YES];
                break;
            }
        }
    }
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    MEGAShare *share = nil;
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            for (NSUInteger i=0; i<[self.incomingShareList.size unsignedIntegerValue]; i++) {
                MEGAShare *s = [self.incomingShareList shareAtIndex:i];
                if (s.nodeHandle == node.handle) {
                    share = s;
                    break;
                }
            }
            break;
        }
            
        case 1: { //Outgoing
            for (NSUInteger i=0; i<self.outgoingSharesMutableArray.count; i++) {
                MEGAShare *s = self.outgoingSharesMutableArray[i];
                if (s.nodeHandle == node.handle) {
                    share = s;
                    break;
                }
            }
            break;
        }
    }
    
    DetailsNodeInfoViewController *detailsNodeInfoVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
    [detailsNodeInfoVC setDisplayMode:DisplayModeSharedItem];
    
    NSString *email = [share user];
    
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:email];
    
    detailsNodeInfoVC.userName = user.mnz_fullName ? user.mnz_fullName : email;
    detailsNodeInfoVC.email    = email;
    detailsNodeInfoVC.node     = node;

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
        contactsVC.contactsMode = ContactsModeShareFoldersWith;
        [contactsVC setNodesArray:[_selectedNodesMutableArray copy]];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        [self setEditing:NO animated:YES];
    }
}

- (IBAction)removeShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self selectedSharesOfSelectedNodes];
        
        NSMutableArray *usersMutableArray = [[NSMutableArray alloc] init];
        if (self.selectedSharesMutableArray != nil) {
            for (MEGAShare *share in self.selectedSharesMutableArray) {
                if (![usersMutableArray containsObject:share.user]) {
                    [usersMutableArray addObject:share.user];
                }
            }
        }
        
        NSString *alertMessage;
        if ((usersMutableArray.count == 1) && ([self.selectedNodesMutableArray count] == 1)) {
            alertMessage = AMLocalizedString(@"removeOneShareOneContactMessage", nil);
        } else if ((usersMutableArray.count > 1) && ([self.selectedNodesMutableArray count] == 1)) {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeOneShareMultipleContactsMessage", nil), usersMutableArray.count];
        } else {
            alertMessage = [NSString stringWithFormat:AMLocalizedString(@"removeMultipleSharesMultipleContactsMessage", nil), usersMutableArray.count];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            numberOfRows = self.searchNodesArray.count;
        } else {
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
        }
    }
    
    if (numberOfRows == 0) {
        [self setEditing:NO animated:NO];
        [self setNavigationBarButtonItemsEnabled:NO];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
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
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    NSUInteger outSharesCount = 1;
    
    switch (_sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            for (NSUInteger i=0; i<[self.incomingShareList.size unsignedIntegerValue]; i++) {
                MEGAShare *s = [self.incomingShareList shareAtIndex:i];
                if (s.nodeHandle == node.handle) {
                    share = s;
                    break;
                }
            }
            
            NSString *userEmail = [share user];
            [self.incomingNodesForEmailMutableDictionary setObject:userEmail forKey:node.base64Handle];
            [_incomingIndexPathsMutableDictionary setObject:indexPath forKey:node.base64Handle];
            
            [cell.thumbnailImageView setImage:[Helper incomingFolderImage]];
            
            [cell.nameLabel setText:[node name]];
            
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:userEmail];
            NSString *userName = user.mnz_fullName ? user.mnz_fullName : userEmail;
            
            NSString *infoLabelText = userName;
            [cell.infoLabel setText:infoLabelText];
            
            MEGAShareType shareType = [share access];
            [cell.permissionsButton setImage:[Helper permissionsButtonImageForShareType:shareType] forState:UIControlStateNormal];
            
            cell.nodeHandle = [node handle];
            
            break;
        }
            
        case 1: { //Outgoing
            for (NSUInteger i=0; i<self.outgoingSharesMutableArray.count; i++) {
                MEGAShare *s = self.outgoingSharesMutableArray[i];
                if (s.nodeHandle == node.handle) {
                    share = s;
                    break;
                }
            }
            
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
                MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[[outSharesMutableArray objectAtIndex:0] user]];
                userName = user.mnz_fullName ? user.mnz_fullName : user.email;
            }
            
            [cell.permissionsButton setImage:[UIImage imageNamed:@"permissions"] forState:UIControlStateNormal];
            
            [cell.infoLabel setText:userName];
            
            cell.nodeHandle = [share nodeHandle];
            
            break;
        }
    }
    
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
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    cell.delegate = self;
    cell.customEditDelegate = self;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    
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
            cloudTVC.incomingShareChildView = (self.sharedItemsSegmentedControl.selectedSegmentIndex == 0);
            
            [self.navigationController pushViewController:cloudTVC animated:YES];
            break;
        }
        
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    SharedItemsTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.isSwiping = YES;
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    self.selectedNodesMutableArray = [[NSMutableArray alloc] initWithObjects:node, nil];
    if (self.sharedItemsSegmentedControl.selectedSegmentIndex == 0) { //incoming
        UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self leaveShareAction:nil];
            [self setEditing:NO animated:YES];
        }];
        shareAction.image = [UIImage imageNamed:@"leaveShare"];
        shareAction.backgroundColor = [UIColor colorWithRed:1.0 green:0.64 blue:0 alpha:1];
        return [UISwipeActionsConfiguration configurationWithActions:@[shareAction]];
    } else { //outcoming
        UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self removeShareAction:nil];
            [self setEditing:NO animated:YES];
        }];
        shareAction.image = [UIImage imageNamed:@"removeShare"];
        shareAction.backgroundColor = [UIColor colorWithRed:1.0 green:0.64 blue:0 alpha:1];
        return [UISwipeActionsConfiguration configurationWithActions:@[shareAction]];
    }
}

#pragma clang diagnostic pop

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
    self.sharedItemsSegmentedControl.enabled = YES;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            if (self.sharedItemsSegmentedControl.selectedSegmentIndex == 0) {
                self.searchNodesArray = self.incomingNodesMutableArray;
            } else {
                self.searchNodesArray = self.outgoingNodesMutableArray;
            }
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", searchString];
            if (self.sharedItemsSegmentedControl.selectedSegmentIndex == 0) {
                self.searchNodesArray = [[self.incomingNodesMutableArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
            } else {
                self.searchNodesArray = [[self.outgoingNodesMutableArray filteredArrayUsingPredicate:resultPredicate] mutableCopy];
            }
        }
        self.sharedItemsSegmentedControl.enabled = NO;
    }
    
    [self.tableView reloadData];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    CGPoint rowPoint = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rowPoint];
    if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section]) {
        return nil;
    }
    
    previewingContext.sourceRect = [self.tableView convertRect:[self.tableView cellForRowAtIndexPath:indexPath].frame toView:self.view];
    
    MEGANode *node;
    switch (self.sharedItemsSegmentedControl.selectedSegmentIndex) {
        case 0: { //Incoming
            node = [self.incomingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
            
        case 1: { //Outgoing
            node = [self.outgoingNodesMutableArray objectAtIndex:indexPath.row];
            break;
        }
    }
    
    CloudDriveTableViewController *cloudDriveTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
    cloudDriveTVC.parentNode = node;
    cloudDriveTVC.displayMode = DisplayModeCloudDrive;
    cloudDriveTVC.incomingShareChildView = (self.sharedItemsSegmentedControl.selectedSegmentIndex == 0);
    
    return cloudDriveTVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressGestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        
        if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section]) {
            return;
        }
        
        if (self.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedNodesMutableArray.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedNodesMutableArray.count == 1) {
                MEGANode *nodeSelected = self.selectedNodesMutableArray.firstObject;
                MEGANode *nodePressed = self.sharedItemsSegmentedControl.selectedSegmentIndex == 0 ? [self.incomingNodesMutableArray objectAtIndex:indexPath.row] : [self.outgoingNodesMutableArray objectAtIndex:indexPath.row];
                if (nodeSelected.handle == nodePressed.handle) {
                    [self setEditing:NO animated:YES];
                }
            }
        } else {
            [self setEditing:YES animated:YES];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            [self toolbarItemsForSharedItems];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
            }
        } else {
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
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  nil);
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"emptySearch"];
            } else {
                return nil;
            }
        } else {
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

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:self.searchController.isActive];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    [self reloadUI];
}


#pragma mark - Swipe Delegate

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction {
    if (@available(iOS 11.0, *)) {
        return NO;
    }
    
    if (self.isEditing) {
        return NO;
    }
    
    if (direction == MGSwipeDirectionLeftToRight) {
        return NO;
    }
    
    return YES;
}

-(NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
    expansionSettings.fillOnTrigger = NO;
    expansionSettings.threshold = 2;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    self.selectedNodesMutableArray = [[NSMutableArray alloc] initWithObjects:[self nodeAtIndexPath:indexPath], nil];
    
    if (direction == MGSwipeDirectionRightToLeft) {
        
        if (self.sharedItemsSegmentedControl.selectedSegmentIndex == 0) { //incoming
            MGSwipeButton *shareButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"leaveShare"] backgroundColor:[UIColor colorWithRed:1.0 green:0.64 blue:0 alpha:1.0] padding:50 callback:^BOOL(MGSwipeTableCell *sender) {
                [self leaveShareAction:nil];
                return YES;
            }];
            [shareButton iconTintColor:[UIColor whiteColor]];
            
            return @[shareButton];
        } else { //outcoming
            MGSwipeButton *shareButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"removeShare"] backgroundColor:[UIColor colorWithRed:1.0 green:0.64 blue:0 alpha:1.0] padding:50 callback:^BOOL(MGSwipeTableCell *sender) {
                [self removeShareAction:nil];
                return YES;
            }];
            [shareButton iconTintColor:[UIColor whiteColor]];
            
            return @[shareButton];
        }
        
    }
    else {
        return nil;
    }
}

@end
