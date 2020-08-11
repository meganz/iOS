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

@interface FolderLinkViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate, NodeActionViewControllerDelegate, UISearchControllerDelegate>

@property (nonatomic, getter=isLoginDone) BOOL loginDone;
@property (nonatomic, getter=isFetchNodesDone) BOOL fetchNodesDone;
@property (nonatomic, getter=isFolderLinkNotValid) BOOL folderLinkNotValid;
@property (nonatomic, getter=isValidatingDecryptionKey) BOOL validatingDecryptionKey;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;
@property (nonatomic, strong) NSArray *nodesArray;
@property (nonatomic, strong) NSArray *searchNodesArray;

@property (nonatomic, strong) NSMutableArray *cloudImages;
@property (nonatomic, strong) NSMutableArray *selectedNodesArray;
@property (nonatomic, getter=areAllNodesSelected) BOOL allNodesSelected;

@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@end

@implementation FolderLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
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
    
    self.navigationItem.title = AMLocalizedString(@"folderLink", nil);
    
    self.moreBarButtonItem.title = nil;
    self.moreBarButtonItem.image = [UIImage imageNamed:@"moreSelected"];
    self.navigationItem.rightBarButtonItems = @[self.moreBarButtonItem];

    self.navigationController.topViewController.toolbarItems = self.toolbar.items;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    self.closeBarButtonItem.title = AMLocalizedString(@"close", @"A button label.");

    if (self.isFolderRootNode) {
        [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:self.publicLinkString delegate:self];

        self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
        
        [self setActionButtonsEnabled:NO];
    } else {
        [self reloadUI];
    }
    
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    self.moreBarButtonItem.accessibilityLabel = AMLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdkFolder] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGARequestDelegate:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.isFetchNodesDone) {
            [self setNavigationBarTitleLabel];
            [self.tableView reloadEmptyDataSet];
        }
        
        if (self.searchController.active) {
            if (UIDevice.currentDevice.iPad) {
                if (self != UIApplication.mnz_visibleViewController) {
                    [Helper resetSearchControllerFrame:self.searchController];
                }
            } else {
                [Helper resetSearchControllerFrame:self.searchController];
            }
        }
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar traitCollection:self.traitCollection];
            
            [self updateAppearance];
            
            [self.tableView reloadData];
        }
    }
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
    
    self.nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:self.parentNode];
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
    
    [self.tableView reloadData];
    
    if (self.nodeList.size.unsignedIntegerValue == 0) {
        [_tableView setTableHeaderView:nil];
    } else {
        [self addSearchBar];
    }
}

- (void)setNavigationBarTitleLabel {
    if (self.tableView.isEditing) {
        self.navigationItem.titleView = nil;
        if (self.selectedNodesArray.count == 0) {
            self.navigationItem.title = AMLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            self.navigationItem.title= (self.selectedNodesArray.count == 1) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), self.selectedNodesArray.count] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), self.selectedNodesArray.count];
        }
    } else {
        if (self.parentNode.name && !self.isFolderLinkNotValid) {
            UILabel *label = [Helper customNavigationBarLabelWithTitle:self.parentNode.name subtitle:AMLocalizedString(@"folderLink", nil)];
            label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
            self.navigationItem.titleView = label;
        } else {
            self.navigationItem.title = AMLocalizedString(@"folderLink", nil);
        }
    }
}

- (void)showUnavailableLinkView {
    [SVProgressHUD dismiss];
    
    [self disableUIItems];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView configureInvalidFolderLink];
    
    [self.tableView setBackgroundView:unavailableLinkView];
}

- (void)disableUIItems {
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self.tableView setBounces:NO];
    [self.tableView setScrollEnabled:NO];
    
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
    
    [self.tableView reloadData];
}

- (void)setToolbarButtonsEnabled:(BOOL)boolValue {
    [self.shareBarButtonItem setEnabled:boolValue];
    [self.importBarButtonItem setEnabled:boolValue];
    self.downloadBarButtonItem.enabled = boolValue;
}

- (void)addSearchBar {
    if (self.searchController && !self.tableView.tableHeaderView) {
        self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame));
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
}

- (void)hideSearchBarIfNotActive {
    if (!self.searchController.isActive) {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)showDecryptionAlert {
    UIAlertController *decryptionAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", nil) message:AMLocalizedString(@"decryptionKeyAlertMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = AMLocalizedString(@"decryptionKey", nil);
        [textField addTarget:self action:@selector(decryptionTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
    }];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[MEGASdkManager sharedMEGASdkFolder] logout];
        [decryptionAlertController.textFields.firstObject resignFirstResponder];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"decrypt", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *linkString = [MEGALinkManager buildPublicLink:self.publicLinkString withKey:decryptionAlertController.textFields.firstObject.text isFolder:YES];
        
        self.validatingDecryptionKey = YES;
        
        [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:linkString delegate:self];
    }]];
    
    decryptionAlertController.actions.lastObject.enabled = NO;
    
    [self presentViewController:decryptionAlertController animated:YES completion:nil];
}

- (void)showDecryptionKeyNotValidAlert {
    self.validatingDecryptionKey = NO;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyNotValid", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
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
                    if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
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
    if (decryptionAlertController) {
        UIAlertAction *okAction = decryptionAlertController.actions.lastObject;
        okAction.enabled = !textField.text.mnz_isEmpty;
    }
}

- (void)presentMediaNode:(MEGANode *)node {
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:node.parentHandle];
    MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:parentNode];
    NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaNodesMutableArrayFromNodeList];
    
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdkFolder] displayMode:DisplayModeSharedItem presentingNode:node preferredIndex:0];
    
    [self.navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        for (NodeTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        for (NodeTableViewCell *cell in self.tableView.visibleCells){
            cell.selectedBackgroundView = nil;
        }
    }
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [MEGALinkManager resetUtilsForLinksWithoutSession];
    
    [[MEGASdkManager sharedMEGASdkFolder] logout];
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    if (self.tableView.isEditing) {
        [self setEditing:NO animated:YES];
        return;
    }
    
    if (self.parentNode.name) {
        NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:self.parentNode delegate:self displayMode:DisplayModeFolderLink isIncoming:NO sender:sender];
        [self presentViewController:nodeActions animated:YES completion:nil];
    }
}

- (IBAction)editAction:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    [self setEditing:enableEditing animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self setTableViewEditing:editing animated:YES];
    
    [self setNavigationBarTitleLabel];

    [self setToolbarButtonsEnabled:!editing];
    
    if (editing) {
        self.moreBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
        self.moreBarButtonItem.image = nil;

        [self.navigationItem setLeftBarButtonItem:_selectAllBarButtonItem];
    } else {
        self.moreBarButtonItem.title = nil;
        self.moreBarButtonItem.image = [UIImage imageNamed:@"moreSelected"];

        [self setAllNodesSelected:NO];
        _selectedNodesArray = nil;

        if (self.isFolderRootNode) {
            [self.navigationItem setLeftBarButtonItem:_closeBarButtonItem];
        } else {
            [self.navigationItem setLeftBarButtonItem:nil];
        }
    }
    
    if (!_selectedNodesArray) {
        _selectedNodesArray = [NSMutableArray new];
    }
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [_selectedNodesArray removeAllObjects];
    
    if (![self areAllNodesSelected]) {
        MEGANode *node = nil;
        NSInteger nodeListSize = [[_nodeList size] integerValue];
        for (NSInteger i = 0; i < nodeListSize; i++) {
            node = [_nodeList nodeAtIndex:i];
            [_selectedNodesArray addObject:node];
        }
        
        [self setAllNodesSelected:YES];
    } else {
        [self setAllNodesSelected:NO];
    }
    
    (self.selectedNodesArray.count == 0) ? [self setToolbarButtonsEnabled:NO] : [self setToolbarButtonsEnabled:YES];
    
    [self setNavigationBarTitleLabel];
    
    [_tableView reloadData];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodeList nodeAtIndex:indexPath.row];
        
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node delegate:self displayMode:DisplayModeNodeInsideFolderLink isIncoming:NO sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
    activityVC.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)importAction:(UIBarButtonItem *)sender {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [self dismissViewControllerAnimated:YES completion:^{
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
        }];
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
    if (self.selectedNodesArray.count != 0) {
        for (MEGANode *node in _selectedNodesArray) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                [self setEditing:NO animated:YES];
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
                [Helper downloadNode:node folderPath:Helper.relativePathForOffline isFolderLink:YES shouldOverwrite:NO];
            }
        } else {
            [Helper downloadNode:self.parentNode folderPath:Helper.relativePathForOffline isFolderLink:YES shouldOverwrite:NO];
        }
        
        //FIXME: Temporal fix. This lets the SDK process some transfers before going back to the Transfers view (In case it is on the navigation stack)
        [SVProgressHUD show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } else {
        if (self.selectedNodesArray.count != 0) {
            [MEGALinkManager.nodesFromLinkMutableArray addObjectsFromArray:self.selectedNodesArray];
        } else {
            [MEGALinkManager.nodesFromLinkMutableArray addObject:self.parentNode];
        }
        
        MEGALinkManager.selectedOption = LinkOptionDownloadFolderOrNodes;
        
        [self.navigationController pushViewController:[OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault] animated:YES];
    }
}

- (void)openNode:(MEGANode *)node {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            numberOfRows = self.searchNodesArray.count;
        } else {
            if (self.isFolderLinkNotValid) {
                numberOfRows = 0;
            } else {
                numberOfRows = self.nodeList.size.integerValue;
            }
        }
    }
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodeList nodeAtIndex:indexPath.row];
    
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGroupedElevated:self.traitCollection];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
    }
    
    if (node.isFile) {
        if (node.hasThumbnail) {
            [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdkFolder] cell:cell];
        } else {
            [cell.thumbnailImageView mnz_imageForNode:node];
        }
        
        cell.infoLabel.text = [Helper sizeAndModicationDateForNode:node api:[MEGASdkManager sharedMEGASdkFolder]];
    } else if (node.isFolder) {
        [cell.thumbnailImageView mnz_imageForNode:node];
        
        cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdkFolder]];
    }
    cell.thumbnailPlayImageView.hidden = !node.name.mnz_isVideoPathExtension;
    
    cell.nameLabel.text = node.name;
    
    cell.node = node;
    
    if (tableView.isEditing) {
        for (MEGANode *n in _selectedNodesArray) {
            if (n.handle == node.handle) {
                [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    } else {
        cell.selectedBackgroundView = nil;
    }
    
    cell.separatorView.layer.borderColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection].CGColor;
    cell.separatorView.layer.borderWidth = 0.5;
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodeList nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        [_selectedNodesArray addObject:node];
        
        [self setNavigationBarTitleLabel];

        [self setToolbarButtonsEnabled:YES];
        
        if ([_selectedNodesArray count] == [_nodeList.size integerValue]) {
            [self setAllNodesSelected:YES];
        } else {
            [self setAllNodesSelected:NO];
        }
        
        return;
    }

    switch ([node type]) {
        case MEGANodeTypeFolder: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Links" bundle:[NSBundle bundleForClass:self.class]];
            FolderLinkViewController *folderLinkVC = [storyboard instantiateViewControllerWithIdentifier:@"FolderLinkViewControllerID"];
            [folderLinkVC setParentNode:node];
            [folderLinkVC setIsFolderRootNode:NO];
            folderLinkVC.publicLinkString = self.publicLinkString;
            [self.navigationController pushViewController:folderLinkVC animated:YES];
            break;
        }

        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                [self presentMediaNode:node];
            } else {
                [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil];
            }
            break;
        }
        
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [_nodeList nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        NSMutableArray *tempArray = [_selectedNodesArray copy];
        for (MEGANode *n in tempArray) {
            if (n.handle == node.handle) {
                [_selectedNodesArray removeObject:n];
            }
        }
        
        [self setNavigationBarTitleLabel];
        
        (self.selectedNodesArray.count == 0) ? [self setToolbarButtonsEnabled:NO] : [self setToolbarButtonsEnabled:YES];
        
        [self setAllNodesSelected:NO];
        
        return;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
    
    if (!MEGAReachabilityManager.isReachable) {
        self.tableView.tableHeaderView = nil;
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
    [self.tableView reloadData];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    if (UIDevice.currentDevice.iPhoneDevice && UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
        [Helper resetSearchControllerFrame:searchController];
    }
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
            if (self.selectedNodesArray.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedNodesArray.count == 1) {
                MEGANode *nodeSelected = self.selectedNodesArray.firstObject;
                MEGANode *nodePressed = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodeList nodeAtIndex:indexPath.row];
                if (nodeSelected.handle == nodePressed.handle) {
                    [self setEditing:NO animated:YES];
                }
            }
        } else {
            [self setEditing:YES animated:YES];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
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
                text = AMLocalizedString(@"linkNotValid", nil);
            } else {
                text = @"";
            }
        } else {
            if (self.searchController.isActive) {
                text = AMLocalizedString(@"noResults", nil);
            } else {
                text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
            }
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
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
        text = AMLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
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
        switch (error.type) {
            case MEGAErrorTypeApiEArgs: {
                if (request.type == MEGARequestTypeLogin) {
                    if (self.isValidatingDecryptionKey) { //If the user have written the key
                        [self showDecryptionKeyNotValidAlert];
                    } else {
                        [self showUnavailableLinkView];
                    }
                } else if (request.type == MEGARequestTypeFetchNodes) {
                    [self showUnavailableLinkView];
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                if (request.type == MEGARequestTypeFetchNodes) {
                    [self showUnavailableLinkView];
                }
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                [self showDecryptionAlert];
                break;
            }
                
            default: {
                if (request.type == MEGARequestTypeLogin) {
                    [self showUnavailableLinkView];
                } else if (request.type == MEGARequestTypeFetchNodes) {
                    [api logout];
                    [self showUnavailableLinkView];
                }
                break;
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
                    [self showUnavailableLinkView];
                }
                return;
            }
            
            self.fetchNodesDone = YES;
            
            [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:request.nodeHandle] forKey:MEGALastPublicHandleAccessed];
            [NSUserDefaults.standardUserDefaults setInteger:AffiliateTypeFileFolder forKey:MEGALastPublicTypeAccessed];
            [NSUserDefaults.standardUserDefaults setDouble:NSDate.date.timeIntervalSince1970 forKey:MEGALastPublicTimestampAccessed];
            if (@available(iOS 12.0, *)) {} else {
                [NSUserDefaults.standardUserDefaults synchronize];
            }
            
            [self reloadUI];
            
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
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in self.tableView.visibleCells) {
                if (request.nodeHandle == nodeTableViewCell.node.handle) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    [Helper setThumbnailForNode:node api:api cell:nodeTableViewCell reindexNode:NO];
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
            BOOL enableEditing = !self.tableView.isEditing;
            [self setEditing:enableEditing animated:YES];
            break;
        }
            
        case MegaNodeActionTypeShare:
            [self shareAction:self.moreBarButtonItem];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [node mnz_saveToPhotosWithApi:[MEGASdkManager sharedMEGASdkFolder]];
            break;
            
        case MegaNodeActionTypeSendToChat:
            [self sendFolderLinkToChat];
            break;
            
        default:
            break;
    }
}

@end
