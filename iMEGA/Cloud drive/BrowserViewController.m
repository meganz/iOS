#import "BrowserViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "SVProgressHUD.h"

#import "NSFileManager+MNZCategory.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"

#import "NodeTableViewCell.h"

@interface BrowserViewController () <UIActionSheetDelegate, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate> {
    UIAlertView *folderAlertView;
    NSUInteger remainingOperations;
}

@property (nonatomic, strong) MEGANodeList *nodes;
@property (nonatomic, strong) MEGAShareList *shares;

@property (nonatomic) MEGAShareType parentShareType;

@property (weak, nonatomic) IBOutlet UIView *browserSegmentedControlView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *browserSegmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarNewFolderBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarMoveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarShareFolderBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarSaveInMegaBarButtonItem;

@property (nonatomic, strong) NSMutableDictionary *foldersToImportMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *folderPathsMutableDictionary;

@end

@implementation BrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    if (self.isChildBrowser || self.browserAction == BrowserActionSelectFolderToShare) {
        self.browserSegmentedControlView.hidden = YES;
        self.tableViewTopConstraint.constant = -self.browserSegmentedControlView.frame.size.height;
    } else {
        [self.browserSegmentedControl setTitle:AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section") forSegmentAtIndex:0];
        [self.browserSegmentedControl setTitle:AMLocalizedString(@"incoming", @"Title of the 'Incoming' Shared Items.") forSegmentAtIndex:1];
    }
    
    [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
    
    [_toolBarNewFolderBarButtonItem setTitle:AMLocalizedString(@"newFolder", @"New Folder")];
    [self.toolBarNewFolderBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
    
    [self setupBrowser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.isChildBrowser && (self.parentShareType != MEGAShareTypeAccessOwner)) {
            [self setNavigationBarTitleLabel];
        }
        
        [self.tableView reloadEmptyDataSet];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - Private

- (void)setupBrowser {
    switch (self.browserAction) {
        case BrowserActionCopy: {
            [_toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"copy", nil)];
            [self.toolBarCopyBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarCopyBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionMove: {
            [_toolBarMoveBarButtonItem setTitle:AMLocalizedString(@"move", nil)];
            [self.toolBarMoveBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarMoveBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionImport:
        case BrowserActionImportFromFolderLink: {
            [_toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"import", nil)];
            [self.toolBarCopyBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]}  forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarCopyBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            
            if (self.browserAction == BrowserActionImportFromFolderLink) {
                _foldersToImportMutableDictionary = [[NSMutableDictionary alloc] init];
                _folderPathsMutableDictionary = [[NSMutableDictionary alloc] init];
            }
            break;
        }
            
        case BrowserActionSelectFolderToShare: {
            [_toolBarShareFolderBarButtonItem setTitle:AMLocalizedString(@"shareFolder", nil)];
            [self.toolBarShareFolderBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarShareFolderBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionOpenIn: {
            [_toolBarSaveInMegaBarButtonItem setTitle:AMLocalizedString(@"upload", nil)];
            [self.toolBarSaveInMegaBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarSaveInMegaBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
    }
}

- (void)reloadUI {
    switch (self.browserSegmentedControl.selectedSegmentIndex) {
        case 0: { //Cloud Drive
            if (!self.isChildBrowser) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            
            if ([self.parentNode.name isEqualToString:[[[MEGASdkManager sharedMEGASdk] rootNode] name]]) {
                [self.navigationItem setTitle:AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section")];
                self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
            } else {
                [self.navigationItem setTitle:[self.parentNode name]];
                self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
            }
            
            self.parentShareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
            if (self.parentShareType == MEGAShareTypeAccessOwner) {
                [self setToolbarItemsEnabled:YES];
            } else {
                [self setNavigationBarTitleLabel];
                (self.parentShareType == MEGAShareTypeAccessRead) ? [self setToolbarItemsEnabled:NO] : [self setToolbarItemsEnabled:YES];
            }
            break;
        }
            
        case 1: { //Incoming
            [self.navigationItem setTitle:AMLocalizedString(@"sharedItems", @"Title of Shared Items section")];
            self.parentNode = nil;
            self.nodes = [[MEGASdkManager sharedMEGASdk] inShares];
            self.shares = [[MEGASdkManager sharedMEGASdk] inSharesList];
            
            [self setToolbarItemsEnabled:NO];
            break;
        }
    }
    
    if ((self.browserAction == BrowserActionImport) || (self.browserAction == BrowserActionImportFromFolderLink)) {
        NSString *importTitle = AMLocalizedString(@"importTitle", nil);
        importTitle = [NSString stringWithFormat:@"%@ %@", importTitle, [self.navigationItem title]];
        [self.navigationItem setTitle:importTitle];
    }
    
    [self.tableView reloadData];
}

- (void)importFolderFromLink:(MEGANode *)nodeToImport inParent:(MEGANode *)parentNode {
    [self setFolderToImport:nodeToImport inParent:parentNode];
    [[MEGASdkManager sharedMEGASdk] createFolderWithName:nodeToImport.name parent:parentNode];
}

- (void)setFolderToImport:(MEGANode *)nodeToImport inParent:(MEGANode *)parentNode {
    id folderNodeToImport = [_foldersToImportMutableDictionary objectForKey:parentNode.base64Handle];
    if (folderNodeToImport == nil) {
        [_foldersToImportMutableDictionary setObject:nodeToImport forKey:parentNode.base64Handle];
    } else {
        NSMutableArray *folderNodesToImportMutableArray;
        if ([folderNodeToImport isKindOfClass:[MEGANode class]]) {
            MEGANode *previousNodeToImport = folderNodeToImport;
            folderNodesToImportMutableArray = [[NSMutableArray alloc] initWithObjects:previousNodeToImport, nodeToImport, nil];
        } else if ([folderNodeToImport isKindOfClass:[NSMutableArray class]]) {
            folderNodesToImportMutableArray = folderNodeToImport;
            [folderNodesToImportMutableArray addObject:nodeToImport];
        }
        [_foldersToImportMutableDictionary setObject:folderNodesToImportMutableArray forKey:parentNode.base64Handle];
    }
    
    NSString *nodePathOnFolderLink = [[MEGASdkManager sharedMEGASdkFolder] nodePathForNode:nodeToImport];
    [_folderPathsMutableDictionary setObject:nodePathOnFolderLink forKey:nodeToImport.base64Handle];
}

- (void)importRelatedNodeToNewFolder:(MEGANode *)newFolderNode inParent:(MEGANode *)parentNode {
    id folderNodeToImport = [_foldersToImportMutableDictionary objectForKey:parentNode.base64Handle];
    if (folderNodeToImport != nil) {
        if ([folderNodeToImport isKindOfClass:[MEGANode class]]) {
            MEGANode *nodeToImport = folderNodeToImport;
            [self importNodeContents:nodeToImport inParent:newFolderNode];
            
            [_foldersToImportMutableDictionary removeObjectForKey:parentNode.base64Handle];
            [_folderPathsMutableDictionary removeObjectForKey:nodeToImport.base64Handle];
        } else if ([folderNodeToImport isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *folderNodesToImportMutableArray = folderNodeToImport;
            MEGANode *nodeToImport;
            for (MEGANode *node in folderNodesToImportMutableArray) {
                NSString *pathOfNode = [_folderPathsMutableDictionary objectForKey:node.base64Handle];
                if (pathOfNode != nil) {
                    if ([newFolderNode.name isEqualToString:[pathOfNode lastPathComponent]]) {
                        nodeToImport = node;
                        [self importNodeContents:node inParent:newFolderNode];
                        
                        NSMutableArray *tempArray = [folderNodesToImportMutableArray copy];
                        for (MEGANode *tempNode in tempArray) {
                            if (nodeToImport.handle == tempNode.handle) {
                                [folderNodesToImportMutableArray removeObject:tempNode];
                                break;
                            }
                        }
                        if (folderNodesToImportMutableArray.count == 0) {
                            [_foldersToImportMutableDictionary removeObjectForKey:parentNode.base64Handle];
                        }
                        [_folderPathsMutableDictionary removeObjectForKey:nodeToImport.base64Handle];
                        break;
                    }
                }
            }
        }
    }
}

- (void)importNodeContents:(MEGANode *)nodeToImport inParent:(MEGANode *)parentNode {
    MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:nodeToImport];
    NSUInteger count = nodeList.size.unsignedIntegerValue;
    for (NSUInteger i = 0; i < count; i++) {
        MEGANode *node = [nodeList nodeAtIndex:i];
        if ([node isFolder]) {
            [self importFolderFromLink:node inParent:parentNode];
        } else {
            remainingOperations++;
            [[MEGASdkManager sharedMEGASdk] copyNode:[[MEGASdkManager sharedMEGASdkFolder] authorizeNode:node] newParent:parentNode];
        }
    }
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
            message = AMLocalizedString(@"copyFolderMessage", nil);
        } else { //folders > 1
            message = [NSString stringWithFormat:AMLocalizedString(@"copyFoldersMessage", nil), folders];
        }
    } else if (files == 1) {
        if (folders == 0) {
            message = AMLocalizedString(@"copyFileMessage", nil);
        } else if (folders == 1) {
            message = AMLocalizedString(@"copyFileFolderMessage", nil);
        } else {
            message = [NSString stringWithFormat:AMLocalizedString(@"copyFileFoldersMessage", nil), folders];
        }
    } else {
        if (folders == 0) {
            message = [NSString stringWithFormat:AMLocalizedString(@"copyFilesMessage", nil), files];
        } else if (folders == 1) {
            message = [NSString stringWithFormat:AMLocalizedString(@"copyFilesFolderMessage", nil), files];
        } else {
            message = AMLocalizedString(@"copyFilesFoldersMessage", nil);
            NSString *filesString = [NSString stringWithFormat:@"%ld", (long)files];
            NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)folders];
            message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
            message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
        }
    }
    
    return message;
}

- (void)setToolbarItemsEnabled:(BOOL)boolValue {
    self.toolBarNewFolderBarButtonItem.enabled = boolValue;
    
    self.toolBarMoveBarButtonItem.enabled = boolValue;
    self.toolBarCopyBarButtonItem.enabled = boolValue;
    self.toolBarShareFolderBarButtonItem.enabled = boolValue;
    self.toolBarSaveInMegaBarButtonItem.enabled = boolValue;
}

- (void)setNodeTableViewCell:(NodeTableViewCell *)cell enabled:(BOOL)boolValue {
    cell.userInteractionEnabled = boolValue;
    cell.nameLabel.enabled = boolValue;
    cell.infoLabel.enabled = boolValue;
    boolValue ? (cell.thumbnailImageView.alpha = 1.0) : (cell.thumbnailImageView.alpha = 0.5);
}

- (void)setNavigationBarTitleLabel {
    NSString *accessTypeString;
    switch (self.parentShareType) {
        case MEGAShareTypeAccessRead:
            accessTypeString = AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
            break;
            
        case MEGAShareTypeAccessReadWrite:
            accessTypeString = AMLocalizedString(@"readAndWrite", @"Permissions given to the user you share your folder with");
            break;
            
        case MEGAShareTypeAccessFull:
            accessTypeString = AMLocalizedString(@"fullAccess", @"Permissions given to the user you share your folder with");
            break;
            
        default:
            accessTypeString = @"";
            break;
    }
    
    if ([self.parentNode name] != nil) {
        UILabel *label = [Helper customNavigationBarLabelWithTitle:self.parentNode.name subtitle:accessTypeString];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        [self.navigationItem setTitleView:label];
    } else {
        [self.navigationItem setTitle:[NSString stringWithFormat:@"(%@)", accessTypeString]];
    }
}

#pragma mark - IBActions

- (IBAction)browserSegmentedControl:(UISegmentedControl *)sender {
    [self reloadUI];
}

- (IBAction)moveNode:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        remainingOperations = self.selectedNodesArray.count;
        
        for (MEGANode *n in self.selectedNodesArray) {
            [[MEGASdkManager sharedMEGASdk] moveNode:n newParent:self.parentNode];
        }
    }
}

- (IBAction)copyNode:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD show];
        for (MEGANode *node in self.selectedNodesArray) {
            if ([node isFolder] && (self.browserAction == BrowserActionImportFromFolderLink)) {
                [self importFolderFromLink:node inParent:self.parentNode];
            } else {
                remainingOperations++;
                [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.parentNode];
            }
        }
    }
}

- (IBAction)newFolder:(UIBarButtonItem *)sender {
    folderAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"newFolder", @"New Folder") message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"createFolderButton", @"Create"), nil];
    [folderAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [folderAlertView textFieldAtIndex:0].placeholder = AMLocalizedString(@"newFolderMessage", nil);
    [folderAlertView show];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        [folderAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    if (self.browserAction == BrowserActionOpenIn) {
        NSError *error = nil;
        NSString *inboxDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Inbox"];
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxDirectory error:&error]) {
            error = nil;
            if ([[NSFileManager defaultManager] removeItemAtPath:[inboxDirectory stringByAppendingPathComponent:file] error:&error]) {
                MEGALogError(@"Remove item at path failed with error: %@", error)
            }
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shareFolder:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:AMLocalizedString(@"permissions", nil)
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"readOnly", nil), AMLocalizedString(@"readAndWrite", nil), AMLocalizedString(@"fullAccess", nil), nil];
        if ([[UIDevice currentDevice] iPadDevice]) {
            [actionSheet showInView:self.view];
        } else {
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
}

- (IBAction)uploadToMega:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSError *error = nil;
        NSString *localFilePath = [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:self.localpath.lastPathComponent];
        if (![[NSFileManager defaultManager] moveItemAtPath:self.localpath toPath:localFilePath error:&error]) {
            MEGALogError(@"Move item at path failed with error: %@", error);
        }
        
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"uploadStarted_Message", nil)];
        if (isImage(self.localpath.pathExtension)) {
            [[MEGASdkManager sharedMEGASdk] createThumbnail:localFilePath destinatioPath:[self.localpath stringByAppendingString:@"_thumbnail"]];
            [[MEGASdkManager sharedMEGASdk] createPreview:localFilePath destinatioPath:[self.localpath stringByAppendingString:@"_preview"]];
        }
        [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:[localFilePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""] parent:self.parentNode appData:nil isSourceTemporary:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger level;
    switch (buttonIndex) {
        case 0:
            level = 0;
            break;
            
        case 1:
            level = 1;
            break;
            
        case 2:
            level = 2;
            break;
            
        default:
            return;
    }
    
    remainingOperations = self.selectedUsersArray.count;
    
    for (MEGAUser *u in self.selectedUsersArray) {
        [[MEGASdkManager sharedMEGASdk] shareNode:self.parentNode withUser:u level:level];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:[[folderAlertView textFieldAtIndex:0] text] parent:self.parentNode];
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
        numberOfRows = self.nodes.size.integerValue;
    }
    
    if (numberOfRows == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier;
    if (self.browserSegmentedControl.selectedSegmentIndex == 0) {
        cellIdentifier = @"nodeCell";
    } else if (self.browserSegmentedControl.selectedSegmentIndex == 1) {
        cellIdentifier = @"incomingNodeCell";
    }
    
    NodeTableViewCell *cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    MEGANode *node = [self.nodes nodeAtIndex:indexPath.row];
    MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
    
    if (node.isFile) {
        if ([node hasThumbnail]) {
            cell.nodeHandle = [node handle];
            [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
        } else {
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
        [self setNodeTableViewCell:cell enabled:NO];
    } else {
        (shareType == MEGAShareTypeAccessRead) ? [self setNodeTableViewCell:cell enabled:NO] : [self setNodeTableViewCell:cell enabled:YES];
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    }
    
    cell.nameLabel.text = [node name];
    
    if (self.browserSegmentedControl.selectedSegmentIndex == 0) {
        if (node.isFile) {
            cell.infoLabel.text = [Helper sizeAndDateForNode:node api:[MEGASdkManager sharedMEGASdk]];
        } else {
            cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
        }
    } else if (self.browserSegmentedControl.selectedSegmentIndex == 1) {
        MEGAShare *share = [self.shares shareAtIndex:indexPath.row];
        cell.infoLabel.text = [share user];
        [cell.cancelButton setImage:[Helper permissionsButtonImageForShareType:shareType] forState:UIControlStateNormal];
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *newParent = [self.nodes nodeAtIndex:indexPath.row];
    
    BrowserViewController *browserVC = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewControllerID"];
    [browserVC setParentNode:newParent];
    [browserVC setSelectedNodesArray:self.selectedNodesArray];
    
    if (self.selectedUsersArray) {
        [browserVC setSelectedUsersArray:self.selectedUsersArray];
    }
    
    if (self.localpath) {
        [browserVC setLocalpath:self.localpath];
    }
    
    [browserVC setBrowserAction:self.browserAction];
    browserVC.childBrowser = YES;

    [self.navigationController pushViewController:browserVC animated:YES];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if ((self.browserSegmentedControl.selectedSegmentIndex == 1) && !self.isChildBrowser) {
            text = AMLocalizedString(@"noIncomingSharedItemsEmptyState_text", @"Title shown when there's no incoming Shared Items");
        } else {
            text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"Text shown on the app when you don't have connection to the internet or when you have lost it");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if ((self.browserSegmentedControl.selectedSegmentIndex == 1) && !self.isChildBrowser) {
            image = [UIImage imageNamed:@"emptySharedItemsIncoming"];
        } else {
            image = [UIImage imageNamed:@"emptyFolder"];
        }
    } else {
        image = [UIImage imageNamed:@"noInternetConnection"];
    }
    
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:NO];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeCopy:
        case MEGARequestTypeMove: {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([request type] == MEGARequestTypeMove || [request type] == MEGARequestTypeCopy) {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD showErrorWithStatus:error.name];
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeMove: {
            remainingOperations--;
            
            if (remainingOperations == 0) {
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
                        message = AMLocalizedString(@"moveFolderMessage", nil);
                    } else { //folders > 1
                        message = [NSString stringWithFormat:AMLocalizedString(@"moveFoldersMessage", nil), folders];
                    }
                } else if (files == 1) {
                    if (folders == 0) {
                        message = AMLocalizedString(@"moveFileMessage", nil);
                    } else if (folders == 1) {
                        message = AMLocalizedString(@"moveFileFolderMessage", nil);
                    } else {
                        message = [NSString stringWithFormat:AMLocalizedString(@"moveFileFoldersMessage", nil), folders];
                    }
                } else {
                    if (folders == 0) {
                        message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesMessage", nil), files];
                    } else if (folders == 1) {
                        message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesFolderMessage", nil), files];
                    } else {
                        message = AMLocalizedString(@"moveFilesFoldersMessage", nil);
                        NSString *filesString = [NSString stringWithFormat:@"%ld", (long)files];
                        NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)folders];
                        message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                        message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                    }
                }
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showSuccessWithStatus:message];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
        
        case MEGARequestTypeCopy: {
            remainingOperations--;
            
            if (remainingOperations == 0) {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                
                if (self.browserAction == BrowserActionCopy) {
                    NSString *message = [self successMessageForCopyAction];
                    [SVProgressHUD showSuccessWithStatus:message];
                } else if (self.browserAction == BrowserActionImport) {
                    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"fileImported", @"Message shown when a file has been imported")];
                } else if (self.browserAction == BrowserActionImportFromFolderLink) {
                    if ((_selectedNodesArray.count == 1) && ([[_selectedNodesArray objectAtIndex:0] isFile])) {
                        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"fileImported", @"Message shown when a file has been imported")];
                    } else {
                        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"filesImported", @"Message shown when some files have been imported")];
                    }
                    
                    [_foldersToImportMutableDictionary removeAllObjects];
                    [_folderPathsMutableDictionary removeAllObjects];
                    
                    [[MEGASdkManager sharedMEGASdkFolder] logout];
                }
                
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeShare: {
            remainingOperations--;
            
            if (remainingOperations == 0) {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudSharedFolder"] status:AMLocalizedString(@"sharedFolder_success", nil)];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeCreateFolder: {
            if (self.browserAction == BrowserActionImportFromFolderLink) {
                MEGANode *newFolderNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.parentHandle];
                [self importRelatedNodeToNewFolder:newFolderNode inParent:parentNode];
            }
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in [self.tableView visibleCells]) {
                if ([request nodeHandle] == [nodeTableViewCell nodeHandle]) {
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
    [self reloadUI];
}

@end
