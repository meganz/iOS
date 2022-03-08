#import "FolderLinkViewController.h"

#import "SVProgressHUD.h"
#import "SAMKeychain.h"
#import "UIScrollView+EmptyDataSet.h"

#import "DisplayMode.h"
#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

#import "NSString+MNZCategory.h"
#import "MEGALinkManager.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
#import "EmptyStateView.h"
#import "NodeTableViewCell.h"
#import "MainTabBarController.h"
#import "OnboardingViewController.h"
#import "LoginViewController.h"
#import "LinkOption.h"
#import "SendToViewController.h"
#import "UnavailableLinkView.h"

@interface FolderLinkViewController () <UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate, NodeActionViewControllerDelegate, UISearchControllerDelegate, AudioPlayerPresenterProtocol>

@property (nonatomic, getter=isLoginDone) BOOL loginDone;
@property (nonatomic, getter=isFetchNodesDone) BOOL fetchNodesDone;
@property (nonatomic, getter=isValidatingDecryptionKey) BOOL validatingDecryptionKey;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) FolderLinkTableViewController *flTableView;
@property (nonatomic, strong) FolderLinkCollectionViewController *flCollectionView;

@property (nonatomic, assign) ViewModePreference viewModePreference;

@property (nonatomic, strong) MEGAGenericRequestDelegate* requestDelegate;
@property (nonatomic, strong) GlobalDelegate* globalDelegate;

@end

@implementation FolderLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;

    self.definesPresentationContext = YES;
    
    self.loginDone = NO;
    self.fetchNodesDone = NO;
    
    NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    self.navigationItem.title = NSLocalizedString(@"folderLink", nil);
    
    self.moreBarButtonItem.title = nil;
    self.moreBarButtonItem.image = [UIImage imageNamed:@"moreNavigationBar"];
    self.navigationItem.rightBarButtonItems = @[self.moreBarButtonItem];

    self.navigationController.topViewController.toolbarItems = self.toolbar.items;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    self.closeBarButtonItem.title = NSLocalizedString(@"close", @"A button label.");

    if (self.isFolderRootNode) {
        self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
        
        [self setActionButtonsEnabled:NO];
    } else {
        [self reloadUI];
        [self determineViewMode];
    }
    
    self.moreBarButtonItem.accessibilityLabel = NSLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    [self updateAppearance];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MEGASdk *sdkFolder = MEGASdkManager.sharedMEGASdkFolder;
    [sdkFolder addMEGAGlobalDelegate:self.globalDelegate];
    [sdkFolder addMEGARequestDelegate:self.requestDelegate];
    
    if (!self.loginDone && self.isFolderRootNode) {
        [sdkFolder loginToFolderLink:self.publicLinkString];
    }
    
    self.navigationController.toolbarHidden = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [sdkFolder retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    MEGASdk *sdkFolder = MEGASdkManager.sharedMEGASdkFolder;
    [sdkFolder removeMEGAGlobalDelegate:self.globalDelegate];
    [sdkFolder removeMEGARequestDelegate:self.requestDelegate];
    
    [AudioPlayerManager.shared removeDelegate:self];
    [AudioPlayerManager.shared removeMiniPlayerHandler:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [AudioPlayerManager.shared addDelegate:self];
    [AudioPlayerManager.shared addMiniPlayerHandler:self];
    [self shouldShowMiniPlayer];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.isFetchNodesDone) {
            [self setNavigationBarTitleLabel];
            [self.flTableView.tableView reloadEmptyDataSet];
        }
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar traitCollection:self.traitCollection];
        
        [self updateAppearance];
        
        [self reloadData];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        MEGALinkManager.secondaryLinkURL = nil;
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedElevated:self.traitCollection];
}

- (void)reloadUI {
    if (!self.parentNode) {
        self.parentNode = [[MEGASdkManager sharedMEGASdkFolder] rootNode];
    }
    
    [self setNavigationBarTitleLabel];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];
    if (_nodeList.size.unsignedIntegerValue == 0) {
        [self setActionButtonsEnabled:NO];
    } else {
        [self setActionButtonsEnabled:YES];
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:self.nodeList.size.integerValue];
    for (NSUInteger i = 0; i < self.nodeList.size.integerValue ; i++) {
        [tempArray addObject:[self.nodeList nodeAtIndex:i]];
    }
    
    self.nodesArray = tempArray;
    
    [self reloadData];
    
    if (self.nodeList.size.unsignedIntegerValue == 0) {
        [self.flTableView.tableView setTableHeaderView:nil];
    } else {
        [self addSearchBar];
    }
}

- (void)setNavigationBarTitleLabel {
    if (self.flTableView.tableView.isEditing || self.flCollectionView.collectionView.allowsMultipleSelection) {
        self.navigationItem.titleView = nil;
        if (self.selectedNodesArray.count == 0) {
            self.navigationItem.title = NSLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            self.navigationItem.title= (self.selectedNodesArray.count == 1) ? [NSString stringWithFormat:NSLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), self.selectedNodesArray.count] : [NSString stringWithFormat:NSLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), self.selectedNodesArray.count];
        }
    } else {
        if (self.parentNode.name && !self.isFolderLinkNotValid) {
            UILabel *label = [Helper customNavigationBarLabelWithTitle:self.parentNode.name subtitle:NSLocalizedString(@"folderLink", nil)];
            label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
            self.navigationItem.titleView = label;
        } else {
            self.navigationItem.title = NSLocalizedString(@"folderLink", nil);
        }
    }
}

- (void)showUnavailableLinkViewWithError:(UnavailableLinkError)error {
    [SVProgressHUD dismiss];
    
    self.navigationItem.titleView = [Helper customNavigationBarLabelWithTitle:NSLocalizedString(@"folderLink", nil) subtitle:NSLocalizedString(@"Unavailable", @"Text used to show the user that some resource is not available")];
    
    [self disableUIItems];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    switch (error) {
        case UnavailableLinkErrorGeneric:
            [unavailableLinkView configureInvalidFolderLink];
            break;
            
        case UnavailableLinkErrorETDDown:
            [unavailableLinkView configureInvalidFolderLinkByETD];
            break;
            
        case UnavailableLinkErrorUserETDSuspension:
            [unavailableLinkView configureInvalidFolderLinkByUserETDSuspension];
            break;
            
        case UnavailableLinkErrorUserCopyrightSuspension:
            [unavailableLinkView configureInvalidFolderLinkByUserCopyrightSuspension];
            break;
    }
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.flTableView.tableView setBackgroundView:unavailableLinkView];
    } else {
        [self.flCollectionView.collectionView setBackgroundView:unavailableLinkView];
    }
}

- (void)disableUIItems {
    self.flTableView.tableView.emptyDataSetSource = nil;
    self.flTableView.tableView.emptyDataSetDelegate = nil;
    [self.flTableView.tableView setSeparatorColor:[UIColor clearColor]];
    [self.flTableView.tableView setBounces:NO];
    [self.flTableView.tableView setScrollEnabled:NO];
    
    [self setActionButtonsEnabled:NO];
}

- (void)setActionButtonsEnabled:(BOOL)boolValue {
    [_moreBarButtonItem setEnabled:boolValue];
    [self setToolbarButtonsEnabled:boolValue];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setActionButtonsEnabled:boolValue];
    
    boolValue ? [self addSearchBar] : [self hideSearchBarIfNotActive];
    
    [self reloadData];
}

- (void)setToolbarButtonsEnabled:(BOOL)boolValue {
    [self.shareLinkBarButtonItem setEnabled:boolValue];
    [self.importBarButtonItem setEnabled:boolValue];
    self.downloadBarButtonItem.enabled = boolValue;
}

- (void)addSearchBar {
    self.navigationItem.searchController = self.searchController;
}

- (void)hideSearchBarIfNotActive {
    self.searchController.active = false;
    self.navigationItem.searchController = nil;
}
    
- (void)showDecryptionAlert {
    UIAlertController *decryptionAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"decryptionKeyAlertTitle", nil) message:NSLocalizedString(@"decryptionKeyAlertMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"decryptionKey", nil);
        [textField addTarget:self action:@selector(decryptionTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
    }];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[MEGASdkManager sharedMEGASdkFolder] logout];
        [decryptionAlertController.textFields.firstObject resignFirstResponder];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"decrypt", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *linkString = [MEGALinkManager buildPublicLink:self.publicLinkString withKey:decryptionAlertController.textFields.firstObject.text isFolder:YES];
        
        self.validatingDecryptionKey = YES;
        
        [MEGASdkManager.sharedMEGASdkFolder loginToFolderLink:linkString];
    }]];
    
    decryptionAlertController.actions.lastObject.enabled = NO;
    
    [self presentViewController:decryptionAlertController animated:YES completion:nil];
}

- (void)showDecryptionKeyNotValidAlert {
    self.validatingDecryptionKey = NO;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"decryptionKeyNotValid", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self showDecryptionAlert];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)navigateToNodeWithBase64Handle:(NSString *)base64Handle {
    if (self.isFolderRootNode) {
        // Push folders to go to the selected subfolder:
        MEGANode *targetNode = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:[MEGASdk handleForBase64Handle:base64Handle]];
        if (targetNode) {
            MEGANode *tempNode = targetNode;
            NSMutableArray *nodesToPush = [NSMutableArray new];
            while (tempNode.handle != self.parentNode.handle) {
                [nodesToPush insertObject:tempNode atIndex:0];
                tempNode = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:tempNode.parentHandle];
            }
            
            for (MEGANode *node in nodesToPush) {
                if (node.type == MEGANodeTypeFolder) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Links" bundle:nil];
                    FolderLinkViewController *folderLinkVC = [storyboard instantiateViewControllerWithIdentifier:@"FolderLinkViewControllerID"];
                    [folderLinkVC setParentNode:node];
                    [folderLinkVC setIsFolderRootNode:NO];
                    folderLinkVC.publicLinkString = self.publicLinkString;
                    [self.navigationController pushViewController:folderLinkVC animated:NO];

                } else {
                    if (node.name.mnz_isVisualMediaPathExtension) {
                        [self presentMediaNode:node];
                    } else {
                        [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil];
                    }
                }
            }
        }
    }
}

- (void)decryptionTextFieldDidChange:(UITextField *)textField {
    UIAlertController *decryptionAlertController = (UIAlertController *)self.presentedViewController;
    if ([decryptionAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *okAction = decryptionAlertController.actions.lastObject;
        okAction.enabled = !textField.text.mnz_isEmpty;
    }
}

- (void)presentMediaNode:(MEGANode *)node {
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:node.parentHandle];
    MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:parentNode];
    NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaAuthorizeNodesMutableArrayFromNodeListWithSdk:MEGASdkManager.sharedMEGASdkFolder];
    
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdkFolder] displayMode:DisplayModeNodeInsideFolderLink presentingNode:node preferredIndex:0];
    
    [self.navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
}

- (void)reloadData {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.flTableView.tableView reloadData];
    } else {
        [self.flCollectionView reloadData];
    }
}

- (void)presentSortByActionSheet {
    MEGASortOrderType sortType = [Helper sortTypeFor:self.parentNode];
    
    UIImageView *checkmarkImageView = [UIImageView.alloc initWithImage:[UIImage imageNamed:@"turquoise_checkmark"]];
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"nameAscending", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeDefaultAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"ascending"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeDefaultAsc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"nameDescending", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeDefaultDesc ? checkmarkImageView : nil image:[UIImage imageNamed:@"descending"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeDefaultDesc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"largest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeSizeDesc ? checkmarkImageView : nil image:[UIImage imageNamed:@"largest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeSizeDesc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"smallest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeSizeAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"smallest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeSizeAsc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"newest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeModificationDesc ? checkmarkImageView : nil image:[UIImage imageNamed:@"newest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeModificationDesc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"oldest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeModificationAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"oldest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeModificationAsc for:self.parentNode];
        [self reloadUI];
    }]];
    
    ActionSheetViewController *sortByActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:self.navigationItem.rightBarButtonItems.firstObject];
    [self presentViewController:sortByActionSheet animated:YES completion:nil];
}

- (GlobalDelegate *)globalDelegate {
    if (_globalDelegate == nil) {
        __weak __typeof__(self) weakSelf = self;
        _globalDelegate = [GlobalDelegate.alloc initOnNodesUpdateCompletion:^(MEGANodeList * _Nullable nodeList) {
            [weakSelf onNodesUpdate:MEGASdkManager.sharedMEGASdkFolder nodeList:nodeList];
        }];
    }
    return _globalDelegate;
}

- (MEGAGenericRequestDelegate *)requestDelegate {
    if (_requestDelegate == nil) {
        __weak __typeof__(self) weakSelf = self;
        MEGASdk *sdkFolder = MEGASdkManager.sharedMEGASdkFolder;
        _requestDelegate = [MEGAGenericRequestDelegate.alloc initWithStart:^(MEGARequest * _Nonnull request) {
            [weakSelf onRequestStart:sdkFolder request:request];
        } completion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            [weakSelf onRequestFinish:sdkFolder request:request error:error];
        }];
    }
    return _requestDelegate;
}

#pragma mark - Layout

- (void)determineViewMode {
    NSInteger nodesWithThumbnail = 0;
    NSInteger nodesWithoutThumbnail = 0;

    for (MEGANode *node in self.nodesArray) {
        if (node.hasThumbnail) {
            nodesWithThumbnail = nodesWithThumbnail + 1;
        } else {
            nodesWithoutThumbnail = nodesWithoutThumbnail + 1;
        }
    }
    
    if (nodesWithThumbnail > nodesWithoutThumbnail) {
        [self initCollection];
    } else {
        [self initTable];
    }
}
    
- (void)initTable {
    [self.flCollectionView willMoveToParentViewController:nil];
    [self.flCollectionView.view removeFromSuperview];
    [self.flCollectionView removeFromParentViewController];
    self.flCollectionView = nil;
    
    self.viewModePreference = ViewModePreferenceList;
    
    self.flTableView = [FolderLinkTableViewController instantiateWithFolderLink:self];
    [self addChildViewController:self.flTableView];
    self.flTableView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.flTableView.view];
    [self. flTableView didMoveToParentViewController:self];
    
    self.flTableView.tableView.emptyDataSetSource = self;
    self.flTableView.tableView.emptyDataSetDelegate = self;
}
    
- (void)initCollection {
    [self.flTableView willMoveToParentViewController:nil];
    [self.flTableView.view removeFromSuperview];
    [self.flTableView removeFromParentViewController];
    self.flTableView = nil;

    self.viewModePreference = ViewModePreferenceThumbnail;

    self.flCollectionView = [FolderLinkCollectionViewController instantiateWithFolderLink:self];
    [self addChildViewController:self.flCollectionView];
    self.flCollectionView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.flCollectionView.view];
    [self.flCollectionView didMoveToParentViewController:self];

    self.flCollectionView.collectionView.emptyDataSetDelegate = self;
    self.flCollectionView.collectionView.emptyDataSetSource = self;
}
    
- (void)changeViewModePreference {
    self.viewModePreference = (self.viewModePreference == ViewModePreferenceList) ? ViewModePreferenceThumbnail : ViewModePreferenceList;
    
    if (self.viewModePreference == ViewModePreferenceThumbnail) {
        [self initCollection];
    } else {
        [self initTable];
    }
}
- (void)didDownloadTransferFinish:(MEGANode *)node {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.flTableView reloadWithNode:node];
    } else {
        [self.flCollectionView reloadWithNode:node];
    }
}
    
#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [MEGALinkManager resetUtilsForLinksWithoutSession];
    
    if (!AudioPlayerManager.shared.isPlayerAlive) {
        [[MEGASdkManager sharedMEGASdkFolder] logout];
    }
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    if (self.flTableView.tableView.isEditing || self.flCollectionView.collectionView.allowsMultipleSelection) {
        [self setEditMode:NO];
        return;
    }
    
    if (self.parentNode.name) {
        NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:self.parentNode delegate:self displayMode:DisplayModeFolderLink viewMode:self.viewModePreference sender:sender];
        [self presentViewController:nodeActions animated:YES completion:nil];
    }
}

- (IBAction)editAction:(UIBarButtonItem *)sender {
    BOOL enableEditing = self.viewModePreference == ViewModePreferenceList ? !self.flTableView.tableView.isEditing : !self.flCollectionView.collectionView.allowsMultipleSelection;
    [self setEditMode:enableEditing];
}

- (void)setViewEditing:(BOOL)editing {    
    [self setNavigationBarTitleLabel];

    [self setToolbarButtonsEnabled:!editing];
    
    if (editing) {
        self.moreBarButtonItem.title = NSLocalizedString(@"cancel", @"Button title to cancel something");
        self.moreBarButtonItem.image = nil;

        [self.navigationItem setLeftBarButtonItem:self.selectAllBarButtonItem];
    } else {
        self.moreBarButtonItem.title = nil;
        self.moreBarButtonItem.image = [UIImage imageNamed:@"moreNavigationBar"];

        [self setAllNodesSelected:NO];
        self.selectedNodesArray = nil;

        if (self.isFolderRootNode) {
            [self.navigationItem setLeftBarButtonItem:self.closeBarButtonItem];
        } else {
            [self.navigationItem setLeftBarButtonItem:nil];
        }
    }
    
    if (!self.selectedNodesArray) {
        self.selectedNodesArray = [NSMutableArray new];
    }
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared playerHidden:editing presenter:self];
    }
    
    [self reloadData];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [_selectedNodesArray removeAllObjects];
    
    if (![self areAllNodesSelected]) {
        BOOL isSearchActive = self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty;
        NSArray *nodesArray = isSearchActive ? self.searchNodesArray : [self.nodeList mnz_nodesArrayFromNodeList];
        self.selectedNodesArray = nodesArray.mutableCopy;
        [self setAllNodesSelected:YES];
    } else {
        [self setAllNodesSelected:NO];
    }
    
    (self.selectedNodesArray.count == 0) ? [self setToolbarButtonsEnabled:NO] : [self setToolbarButtonsEnabled:YES];
    
    [self setNavigationBarTitleLabel];
    
    [self reloadData];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
    if (link != nil) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
        activityVC.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

- (IBAction)importAction:(UIBarButtonItem *)sender {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
        if (self.selectedNodesArray.count != 0) {
            browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesArray];
        } else {
            if (self.parentNode == nil) {
                return;
            }
            browserVC.selectedNodesArray = [NSArray arrayWithObject:self.parentNode];
        }
        
        [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    } else {
        if (self.selectedNodesArray.count != 0) {
            [MEGALinkManager.nodesFromLinkMutableArray addObjectsFromArray:self.selectedNodesArray];
        } else {
            if (self.parentNode == nil) {
                return;
            }
            [MEGALinkManager.nodesFromLinkMutableArray addObject:self.parentNode];
        }
        
        MEGALinkManager.selectedOption = LinkOptionImportFolderOrNodes;
        
        [self.navigationController pushViewController:[OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault] animated:YES];
    }
    
    return;
}
    
- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    //TODO: If documents have been opened for preview and the user download the folder link after that, move the dowloaded documents to Offline and avoid re-downloading.
    [self reloadData];
    if (self.selectedNodesArray.count != 0) {
        for (MEGANode *node in _selectedNodesArray) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                [self setEditMode:NO];
                return;
            }
        }
    } else {
        if (![Helper isFreeSpaceEnoughToDownloadNode:_parentNode isFolderLink:YES]) {
            return;
        }
    }
    
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        if (self.selectedNodesArray.count) {
            for (MEGANode *node in self.selectedNodesArray) {
                [Helper downloadNode:node folderPath:Helper.relativePathForOffline isFolderLink:YES];
            }
        } else {
            [Helper downloadNode:self.parentNode folderPath:Helper.relativePathForOffline isFolderLink:YES];
        }
        
        //FIXME: Temporal fix. This lets the SDK process some transfers before going back to the Transfers view (In case it is on the navigation stack)
        [SVProgressHUD show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
        });
    } else {
        if (self.selectedNodesArray.count != 0) {
            [MEGALinkManager.nodesFromLinkMutableArray addObjectsFromArray:self.selectedNodesArray];
        } else {
            if (self.parentNode == nil) {
                return;
            }
            
            [MEGALinkManager.nodesFromLinkMutableArray addObject:self.parentNode];
        }
        
        MEGALinkManager.selectedOption = LinkOptionDownloadFolderOrNodes;
        
        [self.navigationController pushViewController:[OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault] animated:YES];
    }
}

- (void)openNode:(MEGANode *)node {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (node.name.mnz_isVisualMediaPathExtension) {
            [self presentMediaNode:node];
        } else {
            [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil];
        }
    }
}

- (void)sendFolderLinkToChat {
    UIStoryboard *chatStoryboard = [UIStoryboard storyboardWithName:@"Chat" bundle:[NSBundle bundleForClass:SendToViewController.class]];
    SendToViewController *sendToViewController = [chatStoryboard instantiateViewControllerWithIdentifier:@"SendToViewControllerID"];
    sendToViewController.sendMode = SendModeFileAndFolderLink;
    self.sendLinkDelegate = [SendLinkToChatsDelegate.alloc initWithLink:self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString navigationController:self.navigationController];
    sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate;
    [self.navigationController pushViewController:sendToViewController animated:YES];
}

#pragma mark - Public

- (void)showActionsForNode:(MEGANode *)node from:(UIButton *)sender {
     NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node delegate:self displayMode:DisplayModeNodeInsideFolderLink isIncoming:NO sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}
    
- (void)didSelectNode:(MEGANode *)node {
    switch (node.type) {
        case MEGANodeTypeFolder: {
            FolderLinkViewController *folderLinkVC = [self folderLinkViewControllerFromNode:node];
            [self.navigationController pushViewController:folderLinkVC animated:YES];
            break;
        }

        case MEGANodeTypeFile: {
            if (node.name.mnz_isVisualMediaPathExtension) {
                [self presentMediaNode:node];
            } else {
                [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil];
            }
            break;
        }
        
        default:
            break;
    }
}

- (void)setEditMode:(BOOL)editMode {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.flTableView setTableViewEditing:editMode animated:YES];
    } else {
        [self.flCollectionView setCollectionViewEditing:editMode animated:YES];
    }
}

- (FolderLinkViewController *)folderLinkViewControllerFromNode:(MEGANode *)node {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Links" bundle:[NSBundle bundleForClass:self.class]];
    FolderLinkViewController *folderLinkVC = [storyboard instantiateViewControllerWithIdentifier:@"FolderLinkViewControllerID"];
    [folderLinkVC setParentNode:node];
    [folderLinkVC setIsFolderRootNode:NO];
    folderLinkVC.publicLinkString = self.publicLinkString;
    return folderLinkVC;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
    
    if (!MEGAReachabilityManager.isReachable) {
        self.flTableView.tableView.tableHeaderView = nil;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if ([searchString isEqualToString:@""]) {
        self.searchNodesArray = self.nodesArray;
    } else {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", searchString];
        self.searchNodesArray = [self.nodesArray filteredArrayUsingPredicate:resultPredicate];
    }
    [self reloadData];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.isFetchNodesDone && self.isFolderRootNode) {
            if (self.isFolderLinkNotValid) {
                text = NSLocalizedString(@"linkNotValid", nil);
            } else {
                text = @"";
            }
        } else {
            if (self.searchController.isActive) {
                text = NSLocalizedString(@"noResults", nil);
            } else {
                text = NSLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
            }
        }
    } else {
        text = NSLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = NSLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.isFetchNodesDone && self.isFolderRootNode) {
            if (self.isFolderLinkNotValid) {
                return [UIImage imageNamed:@"invalidFolderLink"];
            }
            return nil;
        }
        
         if (self.searchController.isActive) {
             return [UIImage imageNamed:@"searchEmptyState"];
         }
        
        return [UIImage imageNamed:@"folderEmptyState"];
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = NSLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if ([nodeList mnz_shouldProcessOnNodesUpdateForParentNode:self.parentNode childNodesArray:self.nodesArray]) {
        [self reloadUI];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            self.folderLinkNotValid = NO;
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [SVProgressHUD show];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (error.hasExtraInfo) {
            if (error.linkStatus == MEGALinkErrorCodeDownETD) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorETDDown];
            } else if (error.userStatus == MEGAUserErrorCodeETDSuspension) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorUserETDSuspension];
            } else if (error.userStatus == MEGAUserErrorCodeCopyrightSuspension) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorUserCopyrightSuspension];
            } else {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
            }
        } else {
            switch (error.type) {
                case MEGAErrorTypeApiEArgs: {
                    if (request.type == MEGARequestTypeLogin) {
                        if (self.isValidatingDecryptionKey) { //If the user have written the key
                            [self showDecryptionKeyNotValidAlert];
                        } else {
                            [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                        }
                    } else if (request.type == MEGARequestTypeFetchNodes) {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
                    
                case MEGAErrorTypeApiENoent: {
                    if (request.type == MEGARequestTypeFetchNodes) {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
                    
                case MEGAErrorTypeApiEIncomplete: {
                    [self showDecryptionAlert];
                    break;
                }
                    
                default: {
                    if (request.type == MEGARequestTypeLogin) {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    } else if (request.type == MEGARequestTypeFetchNodes) {
                        [api logout];
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
            }
        }
        
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeLogin: {
            self.loginDone = YES;
            self.fetchNodesDone = NO;
            [api fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            
            if (request.flag) { //Invalid key
                [api logout];
                
                [SVProgressHUD dismiss];
                
                if (self.isValidatingDecryptionKey) { //Link without key, after entering a bad one
                    [self showDecryptionKeyNotValidAlert];
                } else { //Link with invalid key
                    [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                }
                return;
            }
            
            self.fetchNodesDone = YES;
            
            [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:request.nodeHandle] forKey:MEGALastPublicHandleAccessed];
            [NSUserDefaults.standardUserDefaults setInteger:AffiliateTypeFileFolder forKey:MEGALastPublicTypeAccessed];
            [NSUserDefaults.standardUserDefaults setDouble:NSDate.date.timeIntervalSince1970 forKey:MEGALastPublicTimestampAccessed];
            
            [self reloadUI];
            
            [self determineViewMode];
            
            NSArray *componentsArray = [self.publicLinkString componentsSeparatedByString:@"!"];
            if (componentsArray.count == 4) {
                [self navigateToNodeWithBase64Handle:componentsArray.lastObject];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [api pauseTransfers:YES];
            }
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeLogout: {
            self.loginDone = NO;
            self.fetchNodesDone = NO;
            [api removeMEGAGlobalDelegate:self];
            [api removeMEGARequestDelegate:self];
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in self.flTableView.tableView.visibleCells) {
                if (request.nodeHandle == nodeTableViewCell.node.handle) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    [Helper setThumbnailForNode:node api:api cell:nodeTableViewCell];
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeDownload:
            self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
            [self downloadAction:nil];
            break;
            
        case MegaNodeActionTypeImport:
            if (node.handle != self.parentNode.handle) {
                self.selectedNodesArray = [NSMutableArray arrayWithObject:node];
            }
            [self importAction:nil];
            break;
            
        case MegaNodeActionTypeSelect: {
            BOOL enableEditing = self.viewModePreference == ViewModePreferenceList ? !self.flTableView.tableView.isEditing : !self.flCollectionView.collectionView.allowsMultipleSelection;
            [self setEditMode:enableEditing];
            break;
        }
            
        case MegaNodeActionTypeShareLink:
            [self shareLinkAction:self.moreBarButtonItem];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            node = [MEGASdkManager.sharedMEGASdkFolder authorizeNode:node];
            [node mnz_saveToPhotos];
            break;
            
        case MegaNodeActionTypeSendToChat:
            [self sendFolderLinkToChat];
            break;
            
        case MegaNodeActionTypeList:
        case MegaNodeActionTypeThumbnail:
            [self changeViewModePreference];
            break;
            
        case MegaNodeActionTypeSort:
            [self presentSortByActionSheet];
            break;
            
        default:
            break;
    }
}

#pragma mark - AudioPlayerPresenterProtocol

- (void)updateContentView:(CGFloat)height {
    if (self.viewModePreference == ViewModePreferenceList) {
        self.flTableView.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
    } else {
        self.flCollectionView.collectionView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
    }
}

@end
