#import "BrowserViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "EmptyStateView.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif
#import "NSFileManager+MNZCategory.h"
#import "NSArray+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"
#import "UIViewController+MNZCategory.h"
#import "NodeTableViewCell.h"

@import DZNEmptyDataSet;
@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

@interface BrowserViewController () <UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate, UISearchControllerDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong) MEGANodeList *nodes;
@property (nonatomic, strong) MEGAShareList *shares;

@property (nonatomic) NSUInteger remainingOperations;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectorViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (strong, nonatomic) UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarNewFolderBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarMoveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarSaveInMegaBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarSendBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarSelectBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarAddBarButtonItem;

@property (strong, nonatomic) BrowserViewModel *viewModel;
@property (nonatomic) NSMutableArray *searchNodesArray;
@property (nonatomic) UISearchController *searchController;

@end

@implementation BrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self setupBrowser];
    
    self.navigationController.presentationController.delegate = self;
    self.cloudDriveButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.incomingButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    
    [self navigateToCurrentTargetActionBrowser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared addMEGADelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self addSearchBar];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self updateAppearance];

    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared removeMEGADelegateAsync:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
        if (self.searchController.isActive) {
            float yCorrection = self.selectorView.hidden ? 0 : 44;
            
            self.searchController.view.frame = CGRectMake(0, self.view.safeAreaInsets.top + yCorrection, self.searchController.view.frame.size.width, self.searchController.view.frame.size.height);
            self.searchController.searchBar.superview.frame = CGRectMake(0, 0, self.searchController.searchBar.superview.frame.size.width, self.searchController.searchBar.superview.frame.size.height);
        }
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        [AppearanceManager forceToolbarUpdate:self.navigationController.toolbar traitCollection:self.traitCollection];
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
           backgroundColorWhenDesignTokenEnable:[UIColor searchBarSurface1BackgroundColor]
                                traitCollection:self.traitCollection];
        
        [self updateAppearance];

        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (BrowserViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self makeViewModel];
    }
    return _viewModel;
}

- (void)setupBrowser {
    self.parentBrowser = !self.isChildBrowser;
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    switch (self.browserAction) {
        case BrowserActionCopy: {
            [self setupDefaultElements];
            
            self.toolBarCopyBarButtonItem.title = LocalizedString(@"cloudDrive.browser.paste", @"List option shown on the details of a file or folder after the user has copied it");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarCopyBarButtonItem]];
            break;
        }
            
        case BrowserActionMove: {
            [self setupDefaultElements];
            
            self.toolBarMoveBarButtonItem.title = LocalizedString(@"move", @"Title for the action that allows you to move a file or folder");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarMoveBarButtonItem]];
            break;
        }
            
        case BrowserActionImport:
        case BrowserActionImportFromFolderLink: {
            [self setupDefaultElements];
            
            self.toolBarCopyBarButtonItem.title = LocalizedString(@"Import to Cloud Drive", @"Button title that triggers the importing link action");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarCopyBarButtonItem]];
            break;
        }
            
        case BrowserActionOpenIn: {
            [self setupDefaultElements];
            
            self.toolBarSaveInMegaBarButtonItem.title = LocalizedString(@"upload", @"");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarSaveInMegaBarButtonItem]];
            break;
        }
            
        case BrowserActionShareExtension:
        case BrowserActionNewHomeUpload:
        case BrowserActionNewFileSave: {
            [self setupDefaultElements];
            
            if (self.browserAction == BrowserActionShareExtension) {
                self.navigationItem.rightBarButtonItem = nil;
            }
            self.toolBarSaveInMegaBarButtonItem.title = self.browserAction == BrowserActionNewFileSave ? LocalizedString(@"save", @"") : LocalizedString(@"upload", @"");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarSaveInMegaBarButtonItem]];
            break;
        }
            
        case BrowserActionSendFromCloudDrive: {
            [self setupDefaultElements];
            
            self.toolbarSendBarButtonItem.title = LocalizedString(@"send", @"Label for any 'Send' button, link, text, title, etc. - (String as short as possible).");
            [self setToolbarItems:@[flexibleItem, self.toolbarSendBarButtonItem]];
            
            if (self.isParentBrowser) {
                self.selectedNodesMutableDictionary = [[NSMutableDictionary alloc] init];
            }
            
            [self.tableView setEditing:YES];
            break;
        }
            
        case BrowserActionDocumentProvider: {
            if (self.isChildBrowser) {
                self.selectorViewHeightConstraint.constant = 0;
                [self.selectorView updateConstraintsIfNeeded];
            }
            
            self.navigationController.toolbarHidden = YES;
            break;
        }
        
        case BrowserActionSaveToCloudDrive:
            [self setupDefaultElements];
            self.toolBarSelectBarButtonItem.title = LocalizedString(@"cloudDrive.browser.saveToCloudDrive.title", @"Browser save to cloud drive select button title");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarSelectBarButtonItem]];

            break;
            
        case BrowserActionSelectFolder:
            [self setupDefaultElements];
            self.toolBarSelectBarButtonItem.enabled = self.isChildBrowser && self.parentNode.handle != MEGASdk.shared.rootNode.handle;
            self.toolBarSelectBarButtonItem.title = LocalizedString(@"Select Folder", @"");
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarSelectBarButtonItem]];

            
            break;
            
        case BrowserActionSelectVideo:
            [self setupDefaultElements];
            self.toolBarAddBarButtonItem.title = [self toolBarAddBarButtonItemTitle];
            [self setToolbarItems:@[flexibleItem, self.toolBarAddBarButtonItem]];
            
            if (self.isParentBrowser) {
                self.selectedNodesMutableDictionary = [[NSMutableDictionary alloc] init];
            }
            
            [self.tableView setEditing:YES];
            
            break;

    }
    
    [self addSearchController];
}

- (void)setupDefaultElements {
    
    if (self.browserAction == BrowserActionSelectVideo) {
        
        self.selectorView.hidden = YES;
        self.tableViewTopConstraint.constant = -self.selectorView.frame.size.height;
        
    } else {
        
        if (self.parentBrowser) {
            [self updateSelector];
            
            [self.incomingButton setTitle:LocalizedString(@"incoming", @"Title of the 'Incoming' Shared Items.") forState:UIControlStateNormal];
            [self.cloudDriveButton setTitle:LocalizedString(@"cloudDrive", @"Title of the Cloud Drive section") forState:UIControlStateNormal];
        } else {
            self.selectorView.hidden = YES;
            self.tableViewTopConstraint.constant = -self.selectorView.frame.size.height;
        }
        
        self.toolBarNewFolderBarButtonItem.title = LocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'");
    }
    
    self.cancelBarButtonItem = [UIBarButtonItem.alloc initWithTitle:LocalizedString(@"cancel", @"")
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = self.cancelBarButtonItem;
}

- (void)reloadUI {
    [self setNavigationBarTitle];
    __weak typeof(self) weakSelf = self;
    [self setNodesWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateSearchBarVisibility];
            [weakSelf reloadToolbarItemsUI];
            [weakSelf.tableView reloadData];
        });
    }];
}

- (void)updateSearchBarVisibility {
    (self.nodes.size == 0 || !MEGAReachabilityManager.isReachable) ? [self hideSearchBarIfNotActive] : [self addSearchBar];
}

- (void)reloadToolbarItemsUI {
    BOOL enableToolbarItems = YES;
    if (self.cloudDriveButton.selected) {
        if (self.browserAction == BrowserActionSendFromCloudDrive || self.browserAction == BrowserActionSelectVideo) {
            enableToolbarItems = self.selectedNodesMutableDictionary.count > 0;
        } else {
            self.parentShareType = [MEGASdk.shared accessLevelForNode:self.parentNode];
            enableToolbarItems = self.parentShareType > MEGAShareTypeAccessRead;
        }
    } else if (self.incomingButton.selected) {
        if (self.browserAction == BrowserActionSendFromCloudDrive) {
            enableToolbarItems = self.selectedNodesMutableDictionary.count > 0;
        } else {
            enableToolbarItems = NO;
        }
    }
    
    [self setToolbarItemsEnabled:enableToolbarItems];
}

- (void)setNodesWithCompletion:(void (^)(void))completion {
    if (self.incomingButton.selected && self.isParentBrowser) {
        self.parentNode = nil;
        self.nodes = MEGASdk.shared.inShares;
        self.shares = [MEGASdk.shared inSharesList:MEGASortOrderTypeNone];
        completion();
    } else {
        __weak typeof(self) weakSelf = self;
        [self.viewModel nodesForParentWithCompletionHandler:^(MEGANodeList * _Nonnull nodeList) {
            weakSelf.nodes = nodeList;
            completion();
        }];
    }
}

- (void)updatePromptTitle {
    if (self.browserAction == BrowserActionSelectVideo) {
        self.navigationItem.prompt = [self promptForSelectedCount:self.selectedNodesMutableDictionary.count];
    } else if (self.browserAction == BrowserActionSendFromCloudDrive) {
        self.navigationItem.prompt = [self promptForSelectedCount:self.selectedNodesMutableDictionary.count];
    } else if (self.browserAction != BrowserActionDocumentProvider
               && self.browserAction != BrowserActionShareExtension
               && self.browserAction != BrowserActionSelectFolder
               && self.browserAction != BrowserActionSelectVideo
               && self.browserAction != BrowserActionNewHomeUpload
               && self.browserAction != BrowserActionNewFileSave) {
        self.navigationItem.prompt = LocalizedString(@"selectDestination", @"Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.");
    }
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

- (void)internetConnectionChanged {
    [self reloadUI];
}

- (NSString *)successMessageForCopyAction {
    NSInteger files = 0;
    NSInteger folders = 0;
    for (MEGANode *n in self.selectedNodesArray) {
        if ([n type] == MEGANodeTypeFolder) {
            folders++;
        } else {
            files++;
        }
    }
    
    NSString *message;
    if (files == 0) {
        if (folders == 1) {
            message = LocalizedString(@"copyFolderMessage", @"");
        } else { //folders > 1
            message = [NSString stringWithFormat:LocalizedString(@"copyFoldersMessage", @""), folders];
        }
    } else if (files == 1) {
        if (folders == 0) {
            message = LocalizedString(@"copyFileMessage", @"");
        } else if (folders == 1) {
            message = LocalizedString(@"copyFileFolderMessage", @"");
        } else {
            message = [NSString stringWithFormat:LocalizedString(@"copyFileFoldersMessage", @""), folders];
        }
    } else {
        if (folders == 0) {
            message = [NSString stringWithFormat:LocalizedString(@"copyFilesMessage", @""), files];
        } else if (folders == 1) {
            message = [NSString stringWithFormat:LocalizedString(@"copyFilesFolderMessage", @""), files];
        } else {
            message = LocalizedString(@"copyFilesFoldersMessage", @"");
            NSString *filesString = [NSString stringWithFormat:@"%ld", (long)files];
            NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)folders];
            message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
            message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
        }
    }
    
    return message;
}

- (void)setToolbarItemsEnabled:(BOOL)boolValue {
    boolValue = boolValue && [MEGAReachabilityManager isReachable];
    
    MEGANode *firstNode = self.selectedNodesArray.firstObject;
    self.toolBarMoveBarButtonItem.enabled = self.browserAction == BrowserActionMove && self.parentNode.handle != firstNode.parentHandle;
    self.toolBarCopyBarButtonItem.enabled = boolValue;
    self.toolBarNewFolderBarButtonItem.enabled = boolValue;
    self.toolBarSaveInMegaBarButtonItem.enabled = boolValue;
    self.toolbarSendBarButtonItem.enabled = boolValue;
    self.toolBarAddBarButtonItem.enabled = boolValue;
}

- (void)setNodeTableViewCell:(NodeTableViewCell *)cell enabled:(BOOL)boolValue {
    cell.userInteractionEnabled = boolValue;
    cell.nameLabel.enabled = boolValue;
    cell.infoLabel.enabled = boolValue;
    boolValue ? (cell.thumbnailImageView.alpha = 1.0) : (cell.thumbnailImageView.alpha = 0.5);
}

- (void)pushBrowserWithParentNode:(MEGANode *)parentNode {
    BrowserViewController *browserVC = [self browserControllerFor:parentNode isCurrentTargetNode:NO];
    [self.navigationController pushViewController:browserVC animated:YES];
}

- (void)attachNodes {
    [self dismissAndSelectNodesIfNeeded:YES completion:nil];
}

- (void)newFolderAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if ([alertController isKindOfClass:UIAlertController.class]) {
        BOOL containsInvalidChars = textField.text.mnz_containsInvalidChars;
        textField.textColor = containsInvalidChars ? UIColor.systemRedColor : UIColor.labelColor;
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty && !containsInvalidChars;
    }
}

- (void)addSearchController {
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    [self addSearchBar];
    self.definesPresentationContext = YES;
}

- (MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath {
    return self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
}

- (void)dismissAndSelectNodesIfNeeded:(BOOL)selectNodes completion:(void (^ __nullable)(void))completion {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    if (selectNodes) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.selectedNodes(self.selectedNodesMutableDictionary.allValues.copy);
            if (completion) {
                completion();
            }
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            if (completion) {
                completion();
            }
        }];
    }
}

- (CancellableTransfer *)transferToUpload {
    if (self.localpath) {
        NSString *appData = [[NSString new] mnz_appDataToSaveCoordinates:self.localpath.mnz_coordinatesOfPhotoOrVideo];
        return [CancellableTransfer.alloc initWithHandle:MEGAInvalidHandle parentHandle:self.parentNode.handle fileLinkURL:nil localFileURL:[NSURL fileURLWithPath:self.localpath] name:nil appData:appData priority:NO isFile:YES type:CancellableTransferTypeUpload];
    } else {
        return nil;
    }
}

#pragma mark - IBActions

- (IBAction)moveNode:(UIBarButtonItem *)sender {
#ifdef MAIN_APP_TARGET
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self.browserViewControllerDelegate nodeEditCompleted:YES];
        [self dismissAndSelectNodesIfNeeded:NO completion:^{
            [self updateActionTargetNode:self.parentNode];
            [[NameCollisionRouterOCWrapper.alloc init] moveNodes:self.selectedNodesArray to:self.parentNode presenter:UIApplication.mnz_presentingViewController];
        }];
    }
#endif
}

- (IBAction)copyNode:(UIBarButtonItem *)sender {
#ifdef MAIN_APP_TARGET
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self.browserViewControllerDelegate nodeEditCompleted:YES];
        if (self.browserAction == BrowserActionImport && [MEGASdk.shared accessLevelForNode:self.selectedNodesArray[0]] == MEGAShareTypeAccessUnknown) {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            [self updateActionTargetNode:self.parentNode];
            for (MEGANode *node in self.selectedNodesArray) {
                self.remainingOperations++;
                [MEGASdk.shared copyNode:node newParent:self.parentNode];
            }
        } else {
            [self dismissAndSelectNodesIfNeeded:NO completion:^{
                [self updateActionTargetNode:self.parentNode];
                [[NameCollisionRouterOCWrapper.alloc init] copyNodes:self.selectedNodesArray to:self.parentNode isFolderLink:self.browserAction == BrowserActionImportFromFolderLink presenter:UIApplication.mnz_presentingViewController];
            }];
        }
    }
#endif
}

- (IBAction)newFolder:(UIBarButtonItem *)sender {
    UIAlertController *newFolderAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    __weak __typeof__(self) weakSelf = self;
    [newFolderAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        
        textField.placeholder = LocalizedString(@"newFolderMessage", @"Hint text shown on the create folder alert.");
        [textField addTarget:strongSelf action:@selector(newFolderAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return (!textField.text.mnz_isEmpty && !textField.text.mnz_containsInvalidChars);
        };
    }];
    
    [newFolderAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *createFolderAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"createFolderButton", @"Title button for the create folder alert.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = [[newFolderAlertController textFields] firstObject];
            MEGANode *childrenNode = [MEGASdk.shared childNodeForParent:strongSelf.parentNode name:textField.text];
            if (childrenNode.isFolder) {
                [SVProgressHUD showErrorWithStatus:LocalizedString(@"There is already a folder with the same name", @"A tooltip message which is shown when a folder name is duplicated during renaming or creation.")];
            } else {
                MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                    MEGANode *newFolderNode = [MEGASdk.shared nodeForHandle:request.nodeHandle];
                    [strongSelf pushBrowserWithParentNode:newFolderNode];
                }];
                
                [MEGASdk.shared createFolderWithName:textField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds parent:strongSelf.parentNode delegate:createFolderRequestDelegate];
            }
        }
    }];
    createFolderAlertAction.enabled = NO;
    [newFolderAlertController addAction:createFolderAlertAction];
    
    [self presentViewController:newFolderAlertController animated:YES completion:nil];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    if (self.browserAction == BrowserActionOpenIn) {
        NSString *inboxDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Inbox"];
        [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:inboxDirectory];
    }
    
    [self dismissAndSelectNodesIfNeeded:NO completion:nil];
}

- (IBAction)uploadToMega:(UIBarButtonItem *)sender {
    if (self.browserAction == BrowserActionOpenIn) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [self dismissAndSelectNodesIfNeeded:NO completion:^{
                CancellableTransfer *cancellableTransfer = [self transferToUpload];
                if (cancellableTransfer) {
                    [NameCollisionRouterOCWrapper.alloc.init uploadFiles:@[cancellableTransfer] presenter: UIApplication.mnz_visibleViewController type: CancellableTransferTypeUpload];
                }
            }];
        }
    } else if (self.browserAction == BrowserActionShareExtension
               || self.browserAction == BrowserActionNewHomeUpload
               || self.browserAction == BrowserActionNewFileSave) {
        [self.browserViewControllerDelegate uploadToParentNode:self.parentNode];
    }
}

- (IBAction)sendNodes:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.selectedNodesMutableDictionary.count > 0) {
            if (self.isParentBrowser) {
                [self attachNodes];
            } else {
                BrowserViewController *browserVC = self.navigationController.viewControllers.firstObject;
                [browserVC attachNodes];
            }
        }
    }
}

- (IBAction)addNodes:(UIBarButtonItem *)sender {
    [self handleAddNodesWithIsReachableHUDIfNot:[MEGAReachabilityManager isReachableHUDIfNot]];
}

- (IBAction)cloudDriveTouchUpInside:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    
    sender.selected = !sender.selected;
    self.incomingButton.selected = !self.incomingButton.selected;
    
    [self updateSelector];
    
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    [self reloadUI];
}

- (IBAction)incomingTouchUpInside:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    
    sender.selected = !sender.selected;
    self.cloudDriveButton.selected = !self.cloudDriveButton.selected;
    
    [self updateSelector];
    
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    [self reloadUI];
}

- (IBAction)selectBarButtonPressed:(UIBarButtonItem *)sender {
    [self.browserViewControllerDelegate didSelectNode:self.parentNode];
    [self dismissAndSelectNodesIfNeeded:NO completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        numberOfRows = self.searchController.isActive ? self.searchNodesArray.count : self.nodes.size;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
    if (self.cloudDriveButton.selected) {
        cellIdentifier = @"nodeCell";
    } else {
        cellIdentifier = @"incomingNodeCell";
    }
    
    NodeTableViewCell *cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    [self setCellBackgroundColor: cell];

    MEGANode *node = [self nodeAtIndexPath:indexPath];
    MEGAShareType shareType = [MEGASdk.shared accessLevelForNode:node];
    
    if (self.browserAction == BrowserActionSendFromCloudDrive || self.browserAction == BrowserActionSelectVideo) {
        [self.selectedNodesMutableDictionary objectForKey:node.base64Handle] ? [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone] : [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    } else if (self.browserAction != BrowserActionDocumentProvider) {
        if (node.isFile || (self.browserAction == BrowserActionMove && [self.selectedNodesArray containsObject:node])) {
            [self setNodeTableViewCell:cell enabled:NO];
        } else {
            [self setNodeTableViewCell:cell enabled:YES];
        }
    }
    
    [cell bindWithViewModel:[cell createViewModelWithNode:node
                            shouldApplySensitiveBehaviour:self.cloudDriveButton.selected]];
    
    if (![FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
        cell.thumbnailPlayImageView.hidden = YES;
    }
    
    cell.nameLabel.text = node.name;
    cell.favouriteView.hidden = !node.isFavourite;
    cell.labelView.hidden = (node.label == MEGANodeLabelUnknown);
    if (node.label != MEGANodeLabelUnknown) {
        NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
        cell.labelImageView.image = [UIImage imageNamed:labelString];
    }
    
    cell.node = node;
    
    cell.infoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    if (self.cloudDriveButton.selected) {
        if (node.isFile) {
            cell.infoLabel.text = [Helper sizeAndModificationDateForNode:node api:MEGASdk.shared];
        } else {
            cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:MEGASdk.shared];
        }
    } else if (self.incomingButton.selected) {
        MEGAShare *share = [self.shares shareAtIndex:indexPath.row];
        cell.infoLabel.text = [share user];
        [cell.incomingPermissionButton setImage:[UIImage mnz_permissionsButtonImageForShareType:shareType] forState:UIControlStateNormal];
    }
    
    cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    if (tableView.isEditing) {
        UIView *view = UIView.alloc.init;
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
    
    if (node.isTakenDown) {
        cell.infoLabel.enabled = node.isFolder;
        cell.nameLabel.attributedText = [node attributedTakenDownName];
        cell.nameLabel.textColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
        cell.userInteractionEnabled = node.isFolder;
        cell.thumbnailImageView.alpha = node.isFolder ? 1.0 : 0.5;
    } else {
        cell.infoLabel.enabled = YES;
        cell.nameLabel.textColor = UIColor.labelColor;
        cell.subtitleLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
        cell.userInteractionEnabled = YES;
        cell.thumbnailImageView.alpha = 1.0;
    }
    
    cell.isNodeInBrowserView = YES;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.browserAction == BrowserActionSendFromCloudDrive || self.browserAction == BrowserActionSelectVideo) {
        MEGANode *node = [self nodeAtIndexPath:indexPath];
        return node.isFile;
    } else {
        return YES;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *selectedNode = [self nodeAtIndexPath:indexPath];
    
    if (selectedNode.isFolder) {
        [self pushBrowserWithParentNode:selectedNode];
    } else {
        switch (self.browserAction) {
            case BrowserActionSendFromCloudDrive: {
                [self.selectedNodesMutableDictionary setObject:selectedNode forKey:selectedNode.base64Handle];
                [self updatePromptTitle];
                [self setToolbarItemsEnabled:YES];
                return;
            }
                
            case BrowserActionSelectVideo: {
                [self.selectedNodesMutableDictionary setObject:selectedNode forKey:selectedNode.base64Handle];
                [self updatePromptTitle];
                [self setToolbarItemsEnabled:YES];
                return;
            }
                
            case BrowserActionDocumentProvider: {
                [SVProgressHUD setViewForExtension:self.view];
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                [SVProgressHUD show];
                [self.browserViewControllerDelegate didSelectNode:selectedNode];
                break;
            }
                
            default:
                break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (self.browserAction == BrowserActionSendFromCloudDrive || self.browserAction == BrowserActionSelectVideo) {
        MEGANode *deselectedNode = [self nodeAtIndexPath:indexPath];
        if ([self.selectedNodesMutableDictionary objectForKey:deselectedNode.base64Handle]) {
            [self.selectedNodesMutableDictionary removeObjectForKey:deselectedNode.base64Handle];
            [self updatePromptTitle];
            [self setToolbarItemsEnabled:self.selectedNodesMutableDictionary.count];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.browserAction == BrowserActionSendFromCloudDrive || self.browserAction == BrowserActionSelectVideo) {
        MEGANode *node = [self nodeAtIndexPath:indexPath];
        return node.isFile;
    } else {
        return YES;
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
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            self.searchNodesArray = [self.nodes.mnz_nodesArrayFromNodeList mutableCopy];
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", searchString];
            self.searchNodesArray = [[self.nodes.mnz_nodesArrayFromNodeList filteredArrayUsingPredicate:resultPredicate] mutableCopy];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    float yPosition = self.selectorView.hidden ? 0 : self.selectorViewHeightConstraint.constant;
    self.searchController.searchBar.superview.frame = CGRectMake(0, yPosition, self.searchController.searchBar.superview.frame.size.width, self.searchController.searchBar.superview.frame.size.height);
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    return NO;
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    if (self.cancelBarButtonItem == nil) {
        return;
    }
    
    UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:self.cancelBarButtonItem withConfirmAction:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:confirmDismissAlert animated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                text = LocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
            }
        } else {
            if (self.incomingButton.selected && self.isParentBrowser) {
                text = LocalizedString(@"noIncomingSharedItemsEmptyState_text", @"Title shown when there's no incoming Shared Items");
            } else {
                text = LocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
            }
        }
    } else {
        text = LocalizedString(@"noInternetConnection",  @"Text shown on the app when you don't have connection to the internet or when you have lost it");
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
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"searchEmptyState"];
            } else {
                return nil;
            }
        } else {
            if (self.incomingButton.selected && self.isParentBrowser) {
                if ([UIColor isDesignTokenEnabled]) {
                    image = [UIImage imageNamed:@"incomingEmptyState"];
                } else {
                    image = [[UIImage imageNamed:@"incomingEmptyState"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                }
            } else {
                image = [UIImage imageNamed:@"folderEmptyState"];
            }
        }
    } else {
        image = [UIImage imageNamed:@"noInternetEmptyState"];
    }
    
    return image;
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Turn Mobile Data on", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [self openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeCopy: {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            if (self.browserAction != BrowserActionSendFromCloudDrive && self.browserAction != BrowserActionSelectFolder && self.browserAction != BrowserActionSelectVideo) {

                [SVProgressHUD show];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if (request.type == MEGARequestTypeCopy) {
            if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
                [SVProgressHUD dismiss];
            } else {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:LocalizedString(error.name, @"")];
            }
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCopy: {
            self.remainingOperations--;
            
            if (self.remainingOperations == 0) {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                
                if (self.browserAction == BrowserActionCopy) {
                    NSString *message = [self successMessageForCopyAction];
                    [SVProgressHUD showSuccessWithStatus:message];
                } else if (self.browserAction == BrowserActionImport || self.browserAction == BrowserActionImportFromFolderLink) {
                    if ((self.selectedNodesArray.count == 1) && [self.selectedNodesArray.firstObject isFile]) {
                        [SVProgressHUD showSuccessWithStatus:LocalizedString(@"fileImported", @"Message shown when a file has been imported")];
                    } else {
                        [SVProgressHUD showSuccessWithStatus:LocalizedString(@"filesImported", @"Message shown when some files have been imported")];
                    }
                }
                
                [self dismissAndSelectNodesIfNeeded:NO completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in self.tableView.visibleCells) {
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

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    BOOL shouldProcessOnNodesUpdate = NO;
    if (self.cloudDriveButton.selected) {
        shouldProcessOnNodesUpdate = [self shouldProcessOnNodesUpdateWith:nodeList childNodes:self.nodes.mnz_nodesArrayFromNodeList parentNode:self.parentNode];
    } else if (self.incomingButton.selected) {
        if (self.isParentBrowser) {
            shouldProcessOnNodesUpdate = [nodeList mnz_shouldProcessOnNodesUpdateInSharedForNodes:self.nodes.mnz_nodesArrayFromNodeList itemSelected:0];
        } else {
            shouldProcessOnNodesUpdate = [self shouldProcessOnNodesUpdateWith:nodeList childNodes:self.nodes.mnz_nodesArrayFromNodeList parentNode:self.parentNode];
        }
    }
    
    if (shouldProcessOnNodesUpdate) {
        [self reloadUI];
    }
}

@end
