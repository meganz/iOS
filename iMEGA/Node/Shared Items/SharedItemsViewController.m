#import "SharedItemsViewController.h"

#import "SVProgressHUD.h"
#import "UIApplication+MNZCategory.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"
#import "NSArray+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIViewController+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "EmptyStateView.h"
#import "MEGAPhotoBrowserViewController.h"
#import "NodeTableViewCell.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

@interface SharedItemsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate, NodeInfoViewControllerDelegate, NodeActionViewControllerDelegate, BrowserViewControllerDelegate, TextFileEditable> {
    BOOL allNodesSelected;
}

@property (nonatomic, strong) NSMutableArray *outgoingSharesMutableArray;
@property (nonatomic, strong) NSMutableArray *selectedSharesMutableArray;

@property (nonatomic, strong) NSMutableDictionary *incomingNodesForEmailMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *incomingIndexPathsMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *outgoingNodesForEmailMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *outgoingIndexPathsMutableDictionary;

@end

@implementation SharedItemsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureImages];
    
    self.definesPresentationContext = YES;
    
    [self updateAppearance];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    self.navigationItem.title = LocalizedString(@"sharedItems", @"Title of Shared Items section");
    self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
    
    [self setNavigationBarButtons];
    
    [self.incomingButton setTitle:LocalizedString(@"incoming", @"") forState:UIControlStateNormal];
    [self.outgoingButton setTitle:LocalizedString(@"outgoing", @"") forState:UIControlStateNormal];
    [self.linksButton setTitle:LocalizedString(@"Links", @"") forState:UIControlStateNormal];
    
    self.incomingNodesForEmailMutableDictionary = NSMutableDictionary.alloc.init;
    self.incomingIndexPathsMutableDictionary = NSMutableDictionary.alloc.init;
    self.outgoingNodesForEmailMutableDictionary = NSMutableDictionary.alloc.init;
    self.outgoingIndexPathsMutableDictionary = NSMutableDictionary.alloc.init;
    
    self.outgoingUnverifiedSharesMutableArray = NSMutableArray.alloc.init;
    self.outgoingUnverifiedNodesMutableArray = NSMutableArray.alloc.init;
    [self allOutgoingNodes];
    
    self.incomingUnverifiedSharesMutableArray = NSMutableArray.alloc.init;
    self.incomingUnverifiedNodesMutableArray = NSMutableArray.alloc.init;
    [self incomingUnverifiedNodes];
    
    self.searchUnverifiedNodesArray = NSMutableArray.new;
    self.searchUnverifiedSharesArray = NSMutableArray.new;
    
    [self configSearchController];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.sortOrderType = [NSUserDefaults.standardUserDefaults integerForKey:@"SharedItemsSortOrderType"];
    if (self.sortOrderType == MEGASortOrderTypeNone) {
        self.sortOrderType = MEGASortOrderTypeDefaultAsc;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SharedItemsTableViewCell" bundle:nil] forCellReuseIdentifier:@"sharedItemsTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NodeTableViewCell" bundle:nil] forCellReuseIdentifier:@"nodeCell"];
    
    [self configureButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self addSearchBar];
    
    [self reloadUI];
    
    [self refreshMyAvatar];
    
    [self setBackBarButton];

    // Update the search results when the search controller is active and the keyboard isn't shown.
    if (self.searchController.isActive) {
        [self updateSearchResultsForSearchController:self.searchController];
    }
    
    [self updateMiniPlayerPresenter];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.tableView isEditing]) {
        [self setEditing:NO animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared removeMEGAGlobalDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self configureAds];
    
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self configureAds];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (SharedItemsViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self createSharedItemsViewModel];
    }
    
    return _viewModel;
}

- (void)configureImages {
    [self.incomingButton setImage:[UIImage megaImageWithNamed:@"incomingSegmentControler"] forState:UIControlStateNormal];
    [self.outgoingButton setImage:[UIImage megaImageWithNamed:@"outgoingSegmentControler"] forState:UIControlStateNormal];
    [self.linksButton setImage:[UIImage megaImageWithNamed:@"linksSegmentControler"] forState:UIControlStateNormal];

    self.selectAllBarButtonItem.image = [UIImage megaImageWithNamed:@"selectAllItems"];
    self.downloadBarButtonItem.image = [UIImage megaImageWithNamed:@"offline"];
    self.carbonCopyBarButtonItem.image = [UIImage megaImageWithNamed:@"copy"];
    self.leaveShareBarButtonItem.image = [UIImage megaImageWithNamed:@"leaveShare"];
    self.shareLinkBarButtonItem.image = [UIImage megaImageWithNamed:@"link"];
    self.removeLinkBarButtonItem.image = [UIImage megaImageWithNamed:@"removeLink"];
    self.removeShareBarButtonItem.image = [UIImage megaImageWithNamed:@"removeShare"];
    self.shareFolderBarButtonItem.image = [UIImage megaImageWithNamed:@"shareFolder"];
    self.saveToPhotosBarButtonItem.image = [UIImage megaImageWithNamed:@"saveToPhotos"];
}

- (void)configSearchController {
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
       backgroundColorWhenDesignTokenEnable:[UIColor pageBackgroundColor]];
    
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.contentOffset = CGPointZero;
    });
}

- (void)reloadUI {
    if (self.incomingButton.selected) {
        [self incomingVerifiedNodes];
        [self incomingUnverifiedNodes];
    } else if (self.outgoingButton.selected) {
        [self allOutgoingNodes];
    } else if (self.linksButton.selected) {
        [self publicLinks];
    }
    
    [self updateNavigationBarTitle];
    [self configNavigationBarButtonItems];
    
    [self.tableView reloadData];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue || self.tableView.isEditing];
    [self toolbarItemsSetEnabled:boolValue];
    
    boolValue ? [self addSearchBar] : [self hideSearchBarIfNotActive];
    
    [self.tableView reloadData];
}

- (void)toolbarItemsSetEnabled:(BOOL)boolValue {
    [self updateToolbarButtonsEnabled: boolValue selectedNodesArray:_selectedNodesMutableArray];
}

- (void)addSearchBar {
    if (self.searchController) {
        if (!self.tableView.tableHeaderView) {
            self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame));
        }
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
}

- (void)hideSearchBarIfNotActive {
    if (!self.searchController.isActive) {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)incomingVerifiedNodes {
    [_incomingNodesForEmailMutableDictionary removeAllObjects];
    [_incomingIndexPathsMutableDictionary removeAllObjects];
    
    self.incomingNodesMutableArray = NSMutableArray.alloc.init;
    
    self.incomingShareList = [MEGASdk.shared inSharesList:self.sortOrderType];
    NSInteger count = self.incomingShareList.size;
    for (NSInteger i = 0; i < count; i++) {
        MEGAShare *share = [self.incomingShareList shareAtIndex:i];
        MEGANode *node = [MEGASdk.shared nodeForHandle:share.nodeHandle];
        [self.incomingNodesMutableArray addObject:node];
    }
    
    [self addInShareSearchBarIfNeeded];
}

- (void)allOutgoingNodes {
    [_outgoingNodesForEmailMutableDictionary removeAllObjects];
    [_outgoingIndexPathsMutableDictionary removeAllObjects];
    
    _outgoingShareList = [MEGASdk.shared outShares:self.sortOrderType];
    self.outgoingSharesMutableArray = NSMutableArray.alloc.init;
    self.outgoingUnverifiedSharesMutableArray = NSMutableArray.alloc.init;
    
    NSString *lastBase64Handle = @"";
    self.outgoingNodesMutableArray = NSMutableArray.alloc.init;
    NSString *beforeUpdateMsg = [NSString stringWithFormat:@"Before - %ld", self.outgoingUnverifiedNodesMutableArray.count];
    [CrashlyticsLogger logWithCategory:LogCategorySharedItems msg:beforeUpdateMsg file:@(__FILE__) function:@(__FUNCTION__)];
    
    self.outgoingUnverifiedNodesMutableArray = NSMutableArray.alloc.init;
    
    NSInteger count = self.outgoingShareList.size;
    for (NSInteger i = 0; i < count; i++) {
        MEGAShare *share = [_outgoingShareList shareAtIndex:i];
        if ([share user] != nil) {
            [_outgoingSharesMutableArray addObject:share];
            
            MEGANode *node = [MEGASdk.shared nodeForHandle:share.nodeHandle];

            if (![lastBase64Handle isEqualToString:node.base64Handle]) {
                lastBase64Handle = node.base64Handle;
                [_outgoingNodesMutableArray addObject:node];
            }

            if ([self isContactVerificationEnabled] && !share.isVerified) {
                [self addToUnverifiedOutSharesWithShare:share node:node];
            }
        }
    }
    
    [self configUnverifiedOutShareBadge];

    if (self.outgoingNodesMutableArray.count == 0) {
        self.tableView.tableHeaderView = nil;
    } else {
        [self addSearchBar];
    }
    
    NSString *afterUpdateMsg = [NSString stringWithFormat:@"After - %ld", self.outgoingUnverifiedNodesMutableArray.count];
    [CrashlyticsLogger logWithCategory:LogCategorySharedItems msg:afterUpdateMsg file:@(__FILE__) function:@(__FUNCTION__)];
}

- (void)publicLinks {
    [self.outgoingNodesForEmailMutableDictionary removeAllObjects];
    [self.outgoingIndexPathsMutableDictionary removeAllObjects];
    
    self.publicLinksArray = [MEGASdk.shared publicLinks:self.sortOrderType].mnz_nodesArrayFromNodeList;
    
    if (self.publicLinksArray.count == 0) {
        self.tableView.tableHeaderView = nil;
    } else {
        [self addSearchBar];
    }
}

- (void)configToolbarItemsForSharedItems {
    
    NSMutableArray *toolbarItemsMutableArray = NSMutableArray.alloc.init;
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (self.incomingButton.selected) {
        [toolbarItemsMutableArray addObjectsFromArray:@[self.downloadBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.leaveShareBarButtonItem]];
    } else if (self.outgoingButton.selected) {
        [toolbarItemsMutableArray addObjectsFromArray:@[self.shareLinkBarButtonItem, flexibleItem, self.shareFolderBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.removeShareBarButtonItem]];
    } else if (self.linksButton.selected) {
        [toolbarItemsMutableArray addObjectsFromArray:@[self.shareLinkBarButtonItem, flexibleItem, self.downloadBarButtonItem]];
        if ([self.viewModel areMediaNodes:self.selectedNodesMutableArray]) {
            [toolbarItemsMutableArray addObjectsFromArray:@[flexibleItem, self.saveToPhotosBarButtonItem]];
        }
        [toolbarItemsMutableArray addObjectsFromArray:@[flexibleItem, self.removeLinkBarButtonItem]];
    }
    
    [_toolbar setItems:toolbarItemsMutableArray];
}

- (void)removeSelectedIncomingShares {
    NSArray *filesAndFolders = self.selectedNodesMutableArray.mnz_numberOfFilesAndFolders;
    MEGARemoveRequestDelegate *removeRequestDelegate = [MEGARemoveRequestDelegate.alloc initWithMode:DisplayModeSharedItem files:[filesAndFolders.firstObject unsignedIntegerValue] folders:[filesAndFolders[1] unsignedIntegerValue] completion:nil];
    for (NSInteger i = 0; i < self.selectedNodesMutableArray.count; i++) {
        [MEGASdk.shared removeNode:[self.selectedNodesMutableArray objectAtIndex:i] delegate:removeRequestDelegate];
    }
    
    [self endEditingMode];
}

- (void)selectedSharesOfSelectedNodes {
    self.selectedSharesMutableArray = NSMutableArray.alloc.init;
    
    for (MEGANode *node in self.selectedNodesMutableArray) {
        NSMutableArray *outSharesOfNodeMutableArray = node.outShares;
        [self.selectedSharesMutableArray addObjectsFromArray:outSharesOfNodeMutableArray];
    }
}

- (void)removeSelectedOutgoingShares {
    MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:self.selectedSharesMutableArray.count completion:^{
        [self endEditingMode];
        [self reloadUI];
    }];
    
    for (MEGAShare *share in self.selectedSharesMutableArray) {
        MEGANode *node = [MEGASdk.shared nodeForHandle:[share nodeHandle]];
        [MEGASdk.shared shareNode:node withEmail:share.user level:MEGAShareTypeAccessUnknown delegate:shareRequestDelegate];
    }
    
    [self endEditingMode];
}

- (MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.isActive) {
        if (self.linksButton.selected || indexPath.section == 1) {
            if (self.searchNodesArray.count > indexPath.row) {
                return self.searchNodesArray[indexPath.row];
            }
        }
        
        if (self.searchUnverifiedNodesArray.count > indexPath.row) {
            return self.searchUnverifiedNodesArray[indexPath.row];
            
        }
        return nil;
    } else {
        if (self.incomingButton.selected) {
            if (indexPath.section == 0) {
                return self.incomingUnverifiedNodesMutableArray[indexPath.row];
            }
            return self.incomingNodesMutableArray[indexPath.row];
        } else if (self.outgoingButton.selected) {
            if (indexPath.section == 0) {
                if (0 <= indexPath.row && indexPath.row < self.outgoingUnverifiedNodesMutableArray.count) {
                    return self.outgoingUnverifiedNodesMutableArray[indexPath.row];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"%ld", self.outgoingUnverifiedNodesMutableArray.count];
                    [CrashlyticsLogger logWithCategory:LogCategorySharedItems msg:msg file:@(__FILE__) function:@(__FUNCTION__)];
                    return nil;
                }
            }
            return self.outgoingNodesMutableArray[indexPath.row];
        } else if (self.linksButton.selected) {
            return self.publicLinksArray[indexPath.row];
        } else {
            return nil;
        }
    }
}

- (void)showNodeInfo:(MEGANode *)node from:(UIButton *)sender {
    NSIndexPath *indexPath = [self indexPathFromSender:sender];
    if (indexPath == nil) {
        return;
    }

    BOOL isNodeUndecryptedFolder = self.incomingButton.selected && indexPath.section == 0;
    NodeInfoViewModel *viewModel = [self createNodeInfoViewModelWithNode:node
                                                 isNodeUndecryptedFolder:isNodeUndecryptedFolder];
    MEGANavigationController *nodeInfoNavigation = [NodeInfoViewController instantiateWithViewModel:viewModel delegate:self];
    [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.tableView.isEditing) {
        navigationTitle = [self selectedCountTitle];
    } else {
        navigationTitle = LocalizedString(@"sharedItems", @"Title of Shared Items section");
    }
    
    self.navigationItem.title = navigationTitle;
}

- (SharedItemsTableViewCell *)incomingSharedCellAtIndexPath:(NSIndexPath *)indexPath forNode:(MEGANode *)node {
    SharedItemsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"sharedItemsTableViewCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [SharedItemsTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sharedItemsTableViewCell"];
    }
    
    cell.delegate = self;
    
    MEGAShare *share = nil;
    for (NSUInteger i = 0; i < self.incomingShareList.size; i++) {
        MEGAShare *s = [self.incomingShareList shareAtIndex:i];
        if (s.nodeHandle == node.handle) {
            share = s;
            break;
        }
    }
    
    NSString *userEmail = share.user;
    if (node.base64Handle) {
        self.incomingNodesForEmailMutableDictionary[node.base64Handle] = userEmail;
        self.incomingIndexPathsMutableDictionary[node.base64Handle] = indexPath;
    }

    cell.thumbnailImageView.image = UIImage.mnz_incomingFolderImage;

    [cell configureNodeWithName:node.name searchText: self.searchController.searchBar.text isTakenDown:node.isTakenDown];
    [self setupLabelAndFavouriteForNode:node cell:cell];
    
    MEGAUser *user = [MEGASdk.shared contactForEmail:userEmail];

    NSString *userDisplayName = user.mnz_displayName;
    cell.infoLabel.text = (userDisplayName != nil) ? userDisplayName : userEmail;

    [cell.permissionsButton setImage:[UIImage mnz_permissionsButtonImageForShareType:share.access] forState:UIControlStateNormal];
    cell.permissionsButton.hidden = NO;

    cell.nodeHandle = node.handle;
    
    [self configureSelectionForCell:cell atIndexPath:indexPath forNode:node];
    [self configureAccessibilityForCell:cell];
    [self configureContactNotVerifiedImageVisibilityFor:cell with:user tab:SharedItemsTabIncomingShares];
    [self configureCellDescription:cell for:node];
    [self configureCellTags:cell for:node];

    return cell;
}

- (SharedItemsTableViewCell *)outgoingSharedCellAtIndexPath:(NSIndexPath *)indexPath forNode:(MEGANode *)node {
    SharedItemsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"sharedItemsTableViewCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [SharedItemsTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sharedItemsTableViewCell"];
    }
    
    cell.delegate = self;
    
    NSUInteger outSharesCount = 1;
    MEGAShare *share = nil;
    for (NSUInteger i = 0; i < self.outgoingSharesMutableArray.count; i++) {
        MEGAShare *s = self.outgoingSharesMutableArray[i];
        if (s.nodeHandle == node.handle) {
            share = s;
            break;
        }
    }
    
    self.outgoingNodesForEmailMutableDictionary[node.base64Handle] = share.user;
    self.outgoingIndexPathsMutableDictionary[node.base64Handle] = indexPath;
    
    cell.thumbnailImageView.image = UIImage.mnz_outgoingFolderImage;
    [cell configureNodeWithName:node.name searchText: self.searchController.searchBar.text isTakenDown:node.isTakenDown];
    [self setupLabelAndFavouriteForNode:node cell:cell];
    
    NSString *userName;
    NSArray *outshares = node.outShares;
    outSharesCount = outshares.count;
    if (outSharesCount > 1) {
        userName = [NSString stringWithFormat:LocalizedString(@"sharedWithXContacts", @""), outSharesCount];
    } else {
        userName = [self userDisplayNameFor:[outshares.firstObject user]];
    }
    
    cell.permissionsButton.hidden = YES;
    
    cell.infoLabel.text = userName;
    
    cell.nodeHandle = share.nodeHandle;
    
    [self configureSelectionForCell:cell atIndexPath:indexPath forNode:node];
    [self configureAccessibilityForCell:cell];
    [self configureContactNotVerifiedImageVisibilityFor:cell with:nil tab:SharedItemsTabOutgoingShares];
    [self configureCellDescription:cell for:node];
    [self configureCellTags:cell for:node];
    return cell;
}

- (NodeTableViewCell *)linkSharedCellAtIndexPath:(NSIndexPath *)indexPath forNode:(MEGANode *)node {
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    cell.cellFlavor = NodeTableViewCellFlavorSharedLink;
    [cell configureCellFor:node searchText:self.searchController.searchBar.text shouldApplySensitiveBehaviour:NO api:MEGASdk.shared];
    //We are on the Shared Items - Links tab, no need to show any icon next to the thumbnail.
    cell.linkImageView.hidden = YES;
    
    __weak typeof(self) weakself = self;
    cell.moreButtonAction = ^(UIButton * moreButton) {
        if (moreButton) {
            [weakself showNodeActions:moreButton];
        }
    };
    
    [self configureSelectionForCell:cell atIndexPath:indexPath forNode:node];

    return cell;
}

- (void)setupLabelAndFavouriteForNode:(MEGANode *)node cell:(SharedItemsTableViewCell *)cell {
    cell.favouriteView.hidden = !node.isFavourite;
    cell.labelView.hidden = (node.label == MEGANodeLabelUnknown);
    if (node.label != MEGANodeLabelUnknown) {
        NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
        cell.labelImageView.image = [UIImage megaImageWithNamed:labelString];
    }
}

- (void)startEditingModeAtIndex:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [self configToolbarItemsForSharedItems];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self audioPlayerHidden:YES];
}

- (void)endEditingMode {
    [self setEditing:NO animated:YES];
    [self audioPlayerHidden:NO];
}

- (void)audioPlayerHidden:(BOOL)hidden {
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared playerHidden:hidden presenter:self];
    }
}

#pragma mark - Utils

- (void)selectSegment:(NSUInteger)index {
    if (index == 0) {
        [self incomingTouchUpInside:self.incomingButton];
    } else if (index == 1) {
        [self outgoingTouchUpInside:self.outgoingButton];
    } else if (index == 2) {
        [self linksTouchUpInside:self.linksButton];
    }
}

- (MEGAPhotoBrowserViewController *)photoBrowserForMediaNode:(MEGANode *)node {
    NSArray *nodesArray = (self.searchController.isActive ? self.searchNodesArray : self.publicLinksArray);
    NSMutableArray<MEGANode *> *mediaNodesArray = NSMutableArray.alloc.init;
    for (MEGANode *node in nodesArray) {
        if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
            [mediaNodesArray addObject:node];
        }
    }
    
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:MEGASdk.shared displayMode:DisplayModeCloudDrive isFromSharedItem:YES presentingNode:node];
    
    return photoBrowserVC;
}

- (void)nodesSortTypeHasChanged {
    [self updateSearchResultsWithSearchString:_searchController.searchBar.text showsHUD:YES];
}

#pragma mark - IBActions

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    if (self.tableView.isEditing) {
        [self endEditingMode];
    }
}

- (void)didTapSelect {
    [self setEditing:YES animated:YES];
    
    self.selectedNodesMutableArray = NSMutableArray.alloc.init;
    self.selectedSharesMutableArray = NSMutableArray.alloc.init;
    
    [self configToolbarItemsForSharedItems];
    [self configNavigationBarButtonItems];
    [self toolbarItemsSetEnabled:NO];
    [self audioPlayerHidden:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:animated];
    
    [self updateNavigationBarTitle];
    
    [self setNavigationBarButtons];
    
    if (editing) {
        if (![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            [self.toolbar setAlpha:0.0];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor surface1Background]];
            
            NSLayoutAnchor *bottomAnchor  = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];

            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        }
        
        for (SharedItemsTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = UIView.alloc.init;
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        allNodesSelected = NO;
        [_selectedNodesMutableArray removeAllObjects];
        [_selectedSharesMutableArray removeAllObjects];
        self.navigationItem.leftBarButtonItems = @[self.myAvatarManager.myAvatarBarButton];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
        
        for (SharedItemsTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectedBackgroundView = nil;
        }
    }
    
    if (!self.selectedNodesMutableArray) {
        self.selectedNodesMutableArray = NSMutableArray.alloc.init;
        self.selectedSharesMutableArray = NSMutableArray.alloc.init;
        
        [self toolbarItemsSetEnabled:NO];
    }
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [_selectedSharesMutableArray removeAllObjects];
    [_selectedNodesMutableArray removeAllObjects];
    
    if (!allNodesSelected) {
        MEGANode *n = nil;
        MEGAShare *s = nil;
        if (self.incomingButton.selected) {
            NSInteger count = self.incomingShareList.size;
            for (NSInteger i = 0; i < count; i++) {
                s = [self.incomingShareList shareAtIndex:i];
                n = [self.incomingNodesMutableArray objectAtIndex:i];
                [self.selectedSharesMutableArray addObject:s];
                [self.selectedNodesMutableArray addObject:n];
            }
        } else if (self.outgoingButton.selected) {
            NSUInteger count = self.outgoingNodesMutableArray.count;
            for (NSInteger i = 0; i < count; i++) {
                n = [self.outgoingNodesMutableArray objectAtIndex:i];
                [self.selectedSharesMutableArray addObjectsFromArray:n.outShares];
                [self.selectedNodesMutableArray addObject:n];
            }
        } else if (self.linksButton.selected) {
            NSUInteger count = self.publicLinksArray.count;
            for (NSInteger i = 0; i < count; i++) {
                [self.selectedNodesMutableArray addObject:self.publicLinksArray[i]];
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
    
    [self updateNavigationBarTitle];
    [self updateToolbarItemsIfNeeded];
    
    [self.tableView reloadData];
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:self.selectedNodesMutableArray presenter:self isFolderLink:NO];
        [self endEditingMode];
    }
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    [self showNodeActions:sender];
}

- (void)showNodeActions:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    NSIndexPath *indexPath = [self indexPathFromSender:sender];
    if (indexPath == nil) {
        return;
    }
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    BOOL isBackupNode = [[[BackupsOCWrapper alloc] init] isBackupNode:node];
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node delegate:self displayMode:self.linksButton.selected ? DisplayModeCloudDrive : DisplayModeSharedItem isIncoming:self.incomingButton.selected isBackupNode:isBackupNode isFromSharedItem:YES sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.browserViewControllerDelegate = self;
        browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesMutableArray];
        [browserVC setBrowserAction:BrowserActionCopy];
    }
}

- (IBAction)leaveShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertMessage = (_selectedNodesMutableArray.count > 1) ? LocalizedString(@"leaveSharesAlertMessage", @"Alert message shown when the user tap on the leave share action selecting multipe inshares") : LocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"leaveFolder", @"") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self removeSelectedIncomingShares];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    [self presentGetLinkFor:self.selectedNodesMutableArray];
    
    [self setEditing:NO animated:YES];
}

- (IBAction)shareFolderAction:(UIBarButtonItem *)sender {
    [self shareFolder];
}

- (IBAction)removeShareAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self selectedSharesOfSelectedNodes];
        
        NSMutableArray *usersMutableArray = NSMutableArray.alloc.init;
        if (self.selectedSharesMutableArray != nil) {
            for (MEGAShare *share in self.selectedSharesMutableArray) {
                if (![usersMutableArray containsObject:share.user]) {
                    [usersMutableArray addObject:share.user];
                }
            }
        }
        
        NSString *alertMessage;
        if ((usersMutableArray.count == 1) && (self.selectedNodesMutableArray.count == 1)) {
            alertMessage = LocalizedString(@"removeOneShareOneContactMessage", @"");
        } else if ((usersMutableArray.count > 1) && (self.selectedNodesMutableArray.count == 1)) {
            alertMessage = [NSString stringWithFormat:LocalizedString(@"removeOneShareMultipleContactsMessage", @""), usersMutableArray.count];
        } else {
            alertMessage = [NSString stringWithFormat:LocalizedString(@"removeMultipleSharesMultipleContactsMessage", @""), usersMutableArray.count];
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"removeSharing", @"") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self removeSelectedOutgoingShares];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)incomingTouchUpInside:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    
    sender.selected = !sender.selected;
    self.outgoingButton.selected = self.linksButton.selected = NO;

    [self updateTabSelection];

    [self disableSearchAndSelection];
    
    [self incomingVerifiedNodes];
    [self incomingUnverifiedNodes];
    [self reloadAndScrollToTop];
}

- (IBAction)outgoingTouchUpInside:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    
    sender.selected = !sender.selected;
    self.incomingButton.selected = self.linksButton.selected = NO;
    
    [self updateTabSelection];
    
    [self disableSearchAndSelection];
    
    [self allOutgoingNodes];
    [self reloadAndScrollToTop];
}

- (IBAction)linksTouchUpInside:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    
    sender.selected = !sender.selected;
    self.incomingButton.selected = self.outgoingButton.selected = NO;
    
    [self updateTabSelection];
    
    [self disableSearchAndSelection];
    
    [self publicLinks];
    [self reloadAndScrollToTop];
}

- (IBAction)removeLinkAction:(UIBarButtonItem *)sender {
    [self showRemoveLinkWarning:self.selectedNodesMutableArray];
}

- (IBAction)saveToPhotosAction:(UIBarButtonItem *)sender {
    [self saveSelectedNodesToPhotos];
}

- (void)disableSearchAndSelection {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
        [self searchBarCancelButtonClicked:self.searchController.searchBar];
    }
    
    if (self.tableView.isEditing) {
        [self.selectedNodesMutableArray removeAllObjects];
        [self.selectedSharesMutableArray removeAllObjects];
        
        [self updateNavigationBarTitle];
        
        [self configToolbarItemsForSharedItems];
        [self toolbarItemsSetEnabled:NO];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.linksButton.selected || section == 1) {
                numberOfRows = self.searchNodesArray.count;
            } else {
                numberOfRows = self.searchUnverifiedNodesArray.count;
            }
        } else {
            if (self.incomingButton.selected) {
                if (section == 0) {
                    numberOfRows = self.incomingUnverifiedNodesMutableArray.count;
                } else {
                    numberOfRows = self.incomingNodesMutableArray.count;
                }
            } else if (self.outgoingButton.selected) {
                if (section == 0) {
                    numberOfRows = self.outgoingUnverifiedNodesMutableArray.count;
                    NSString *msg = [NSString stringWithFormat:@"%ld", self.outgoingUnverifiedNodesMutableArray.count];
                    [CrashlyticsLogger logWithCategory:LogCategorySharedItems msg:msg file:@(__FILE__) function:@(__FUNCTION__)];
                } else {
                    numberOfRows = self.outgoingNodesMutableArray.count;
                }
            } else if (self.linksButton.selected) {
                numberOfRows = self.publicLinksArray.count;
            }
        }
    }
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    
    if (self.incomingButton.selected) {
        if (indexPath.section == 0) {
            return [self unverifiedIncomingSharedCellAtIndexPath:indexPath node:node searchText: self.searchController.searchBar.text];
        }
        return [self isSharedItemsRootNode:node] ? [self incomingSharedCellAtIndexPath:indexPath forNode:node] : [self nodeCellAtIndexPath:indexPath node:node];
    } else if (self.outgoingButton.selected) {
        if (indexPath.section == 0) {
            return [self unverifiedOutgoingSharedCellAtIndexPath:indexPath node:node searchText: self.searchController.searchBar.text];
        }
        return [self isSharedItemsRootNode:node] ? [self outgoingSharedCellAtIndexPath:indexPath forNode:node] : [self nodeCellAtIndexPath:indexPath node:node];
    } else {
        return [self linkSharedCellAtIndexPath:indexPath forNode:node];
    }
}

- (void)configureSelectionForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forNode:(MEGANode *)node {
    if (self.tableView.isEditing) {
        for (MEGANode *n in self.selectedNodesMutableArray) {
            if ([n handle] == [node handle]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = UIView.alloc.init;
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
}

- (void)configureAccessibilityForCell:(SharedItemsTableViewCell *)cell {
    cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    
    if (tableView.isEditing) {
        for (MEGANode *tempNode in self.selectedNodesMutableArray) {
            if (tempNode.handle == node.handle) {
                return;
            }
        }
        
        if (node != nil) {
            [_selectedNodesMutableArray addObject:node];
        }
        
        [self updateNavigationBarTitle];
        [self updateToolbarItemsIfNeeded];
        [self toolbarItemsSetEnabled:YES];
        
        NSUInteger nodeListSize = 0;
        if (self.incomingButton.selected) {
            nodeListSize = self.incomingNodesMutableArray.count;
        } else if (self.outgoingButton.selected) {
            nodeListSize = self.outgoingNodesMutableArray.count;
        } else if (self.linksButton.selected) {
            nodeListSize = self.publicLinksArray.count;
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
            if ([self shouldShowContactVerificationOnTapForIndexPath:indexPath node:node]) {
                [self showContactVerificationViewForIndexPath:indexPath];
            } else {
                [self showCloudDriveFromNode:node];
            }
            break;
        }
        
        case MEGANodeTypeFile: {
            [self shouldProcessTapOn:node.handle completionHandler:^(BOOL allowed) {
                if (allowed) {
                    if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
                        [self.navigationController presentViewController:[self photoBrowserForMediaNode:node] animated:YES completion:nil];
                    } else {
                        [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO fileLink:nil messageId:nil chatId:nil isFromSharedItem:YES allNodes: nil];
                    }
                } else {
                    [self showTakenDownAlert];
                }
            }];
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
                
        [self updateNavigationBarTitle];
        if (self.selectedNodesMutableArray.count == 0) {
            [self toolbarItemsSetEnabled:NO];
        } else {
            [self updateToolbarItemsIfNeeded];
            [self updateToolbarButtonsEnabled:YES selectedNodesArray:_selectedNodesMutableArray];
        }
        
        allNodesSelected = NO;
        
        return;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self startEditingModeAtIndex:indexPath];
}
    
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    if (self.incomingButton.selected) {
        UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [node mnz_leaveSharingInViewController:self completion:nil];
            [self endEditingMode];
        }];
        shareAction.image = [[UIImage megaImageWithNamed:@"leaveShare"] imageWithTintColor:[self tintColorForImage]];
        shareAction.backgroundColor = [self backgroundColorWhenTrailingSwipe];
        return [UISwipeActionsConfiguration configurationWithActions:@[shareAction]];
    } else if (self.outgoingButton.selected) {
        UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [node mnz_removeSharingWithCompletion:nil];
            [self endEditingMode];
        }];
        shareAction.image = [[UIImage megaImageWithNamed:@"removeShare"] imageWithTintColor:[self tintColorForImage]];
        shareAction.backgroundColor = [self backgroundColorWhenTrailingSwipe];
        return [UISwipeActionsConfiguration configurationWithActions:@[shareAction]];
    } else if (self.linksButton.selected) {
        UIContextualAction *removeLinkAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self showRemoveLinkWarning:@[node]];
        }];
        removeLinkAction.image = [[UIImage megaImageWithNamed:@"removeLink"] imageWithTintColor:[self tintColorForImage]];
        removeLinkAction.backgroundColor = [self backgroundColorWhenTrailingSwipe];
        return [UISwipeActionsConfiguration configurationWithActions:@[removeLinkAction]];
    } else {
        return [UISwipeActionsConfiguration configurationWithActions:@[]];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    return [self tableView:tableView contextMenuConfigurationForRowAt:indexPath node:node];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
         animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    [self willPerformPreviewActionForMenuWithAnimator:animator];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self updateSearchResultsWithSearchString:searchString showsHUD:YES];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.searchController.searchBar.superview.frame = CGRectMake(0, self.selectorView.frame.size.height + self.navigationController.navigationBar.frame.size.height, self.searchController.searchBar.superview.frame.size.width, self.searchController.searchBar.superview.frame.size.height);
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    NSInteger itemSelected;
    NSArray *nodesToCheckArray;
  
    if (self.searchController.isActive) {
        [self updateSearchResultsWithSearchString: self.searchController.searchBar.text showsHUD:NO];
        return;
    } else if (self.incomingButton.selected) {
        itemSelected = 0;
        nodesToCheckArray = self.incomingNodesMutableArray;
    } else if (self.outgoingButton.selected) {
        itemSelected = 1;
        nodesToCheckArray = self.outgoingNodesMutableArray;
    } else {
        itemSelected = 2;
        nodesToCheckArray = self.publicLinksArray;
    }
    
    if ([nodeList mnz_shouldProcessOnNodesUpdateInSharedForNodes:nodesToCheckArray itemSelected:itemSelected]) {
        [self reloadUI];
    }
}

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    [self reloadUI];
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(UIButton *)sender {
    switch (action) {
        case MegaNodeActionTypeEditTextFile: {
            [node mnz_editTextFileInViewController:self];
            break;
        }
            
        case MegaNodeActionTypeDownload:
            if (node != nil) {
                [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:@[node] presenter:self isFolderLink:NO];
            }
            break;
            
        case MegaNodeActionTypeRename:
            [node mnz_renameNodeInViewController:self];
            break;
            
        case MegaNodeActionTypeExportFile:
            [self exportFileFrom:node sender:sender];
            break;
            
        case MegaNodeActionTypeShareFolder:
            self.selectedNodesMutableArray = @[node].mutableCopy;
            [self shareFolder];
            break;
            
        case MegaNodeActionTypeManageShare: {
            ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            contactsVC.node = node;
            contactsVC.contactsMode = ContactsModeFolderSharedWith;
            [self.navigationController pushViewController:contactsVC animated:YES];
            break;
        }
            
        case MegaNodeActionTypeInfo:
            [self showNodeInfo:node from:sender];
            break;
            
        case MegaNodeActionTypeFavourite: {
            [MEGASdk.shared setNodeFavourite:node favourite:!node.isFavourite];
            break;
        }
            
        case MegaNodeActionTypeLabel:
            [node mnz_labelActionSheetInViewController:self];
            break;
            
        case MegaNodeActionTypeLeaveSharing:
            [node mnz_leaveSharingInViewController:self completion:nil];
            break;
            
        case MegaNodeActionTypeRemoveSharing:
            [node mnz_removeSharingWithCompletion:nil];
            break;
            
        case MegaNodeActionTypeShareLink:
        case MegaNodeActionTypeManageLink: {
            [self presentGetLinkFor:@[node]];
            break;
        }
            
        case MegaNodeActionTypeRemoveLink: {
            [self showRemoveLinkWarning:@[node]];
            break;
        }

        case MegaNodeActionTypeMoveToRubbishBin:
            [[self viewModel] moveNodeToRubbishBin:node];
            break;
            
        case MegaNodeActionTypeSendToChat:
            [node mnz_sendToChatInViewController:self];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [SaveMediaToPhotosUseCaseOCWrapper.alloc.init saveToPhotosWithNodes:@[node] isFolderLink:NO];
            break;
            
        case MegaNodeActionTypeMove:
            [node mnz_moveInViewController:self];
            break;
            
        case MegaNodeActionTypeCopy:
            [node mnz_copyInViewController:self];
            break;
            
        case MegaNodeActionTypeVerifyContact: {
            NSIndexPath *indexPath = [self indexPathFromSender:sender];
            [self showContactVerificationViewForIndexPath:indexPath];
            break;
        }
            
        case MegaNodeActionTypeViewVersions:
            [node mnz_showNodeVersionsInViewController:self];
            break;
            
        case MegaNodeActionTypeDisputeTakedown:
            [self presentDisputeInSafari];
            break;
        default:
            break;
    }
}

- (void)showNodeContextMenu:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    NSIndexPath *indexPath = [self indexPathFromSender:sender];
    if (indexPath == nil) {
        return;
    }
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    MEGAShare *share = [self shareAtIndexPath:indexPath];
    
    BOOL isBackupNode = [[[BackupsOCWrapper alloc] init] isBackupNode:node];
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node
                                                                                delegate:self
                                                                             displayMode:self.linksButton.selected ? DisplayModeCloudDrive : DisplayModeSharedItem
                                                                              isIncoming:self.incomingButton.selected
                                                                            isBackupNode:isBackupNode
                                                                            sharedFolder:share
                                                                 shouldShowVerifyContact:indexPath.section == 0
                                                                                  sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

#pragma mark - NodeInfoViewControllerDelegate

- (void)nodeInfoViewController:(NodeInfoViewController *)nodeInfoViewController presentParentNode:(MEGANode *)node {
    [node navigateToParentAndPresent];
}

#pragma mark - BrowserViewControllerDelegate, ContactsViewControllerDelegate

- (void)nodeEditCompleted:(BOOL)complete {
    [self setEditing:!complete animated:NO];
}

@end
