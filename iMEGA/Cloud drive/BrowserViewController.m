#import "BrowserViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "SVProgressHUD.h"

#import "NSFileManager+MNZCategory.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"

#import "NodeTableViewCell.h"

@interface BrowserViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate>

@property (nonatomic, getter=isParentBrowser) BOOL parentBrowser;

@property (nonatomic, strong) MEGANodeList *nodes;
@property (nonatomic, strong) MEGAShareList *shares;

@property (nonatomic) MEGAShareType parentShareType;

@property (nonatomic) NSUInteger remainingOperations;

@property (nonatomic, strong) NSArray *selectedUsersArray;

@property (weak, nonatomic) IBOutlet UIView *browserSegmentedControlView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *browserSegmentedControl;

@property (weak, nonatomic) IBOutlet UIView *extendedNavigationBar_view;
@property (weak, nonatomic) IBOutlet UIButton *extendedNavigationBar_backButton;
@property (weak, nonatomic) IBOutlet UILabel *extendedNavigationBar_label;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarNewFolderBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarMoveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarShareFolderBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarSaveInMegaBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarSendBarButtonItem;

@end

@implementation BrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self setupBrowser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
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

- (void)setupBrowser {
    self.parentBrowser = !self.isChildBrowser;
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", nil);
    [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    switch (self.browserAction) {
        case BrowserActionCopy: {
            [self setupDefaultElements];
            
            self.toolBarCopyBarButtonItem.title = AMLocalizedString(@"copy", @"List option shown on the details of a file or folder");
            [self.toolBarCopyBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f]} forState:UIControlStateNormal];
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarCopyBarButtonItem]];
            break;
        }
            
        case BrowserActionMove: {
            [self setupDefaultElements];
            
            self.toolBarMoveBarButtonItem.title = AMLocalizedString(@"move", @"Title for the action that allows you to move a file or folder");
            [self.toolBarMoveBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f]} forState:UIControlStateNormal];
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarMoveBarButtonItem]];
            break;
        }
            
        case BrowserActionImport:
        case BrowserActionImportFromFolderLink: {
            [self setupDefaultElements];
            
            self.toolBarCopyBarButtonItem.title = AMLocalizedString(@"import", @"Button title that triggers the importing link action");
            [self.toolBarCopyBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f]}  forState:UIControlStateNormal];
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarCopyBarButtonItem]];
            break;
        }
            
        case BrowserActionOpenIn: {
            [self setupDefaultElements];
            
            self.toolBarSaveInMegaBarButtonItem.title = AMLocalizedString(@"upload", nil);
            [self.toolBarSaveInMegaBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f]} forState:UIControlStateNormal];
            [self setToolbarItems:@[self.toolBarNewFolderBarButtonItem, flexibleItem, self.toolBarSaveInMegaBarButtonItem]];
            break;
        }

        case BrowserActionSendFromCloudDrive: {
            [self setupDefaultElements];
            
            self.browserSegmentedControlView.hidden = YES;
            self.tableViewTopConstraint.constant = -self.browserSegmentedControlView.frame.size.height;
            
            self.toolbarSendBarButtonItem.title = AMLocalizedString(@"send", @"Label for any 'Send' button, link, text, title, etc. - (String as short as possible).");
            [self.toolbarSendBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f]} forState:UIControlStateNormal];
             [self setToolbarItems:@[flexibleItem, self.toolbarSendBarButtonItem]];
            
            if (self.isParentBrowser) {
                self.selectedNodesMutableDictionary = [[NSMutableDictionary alloc] init];
            }
            break;
        }
            
        case BrowserActionDocumentProvider: {
            if (self.isChildBrowser) {
                [self.browserSegmentedControlView addSubview:self.extendedNavigationBar_view];
            }
            
            self.navigationController.toolbarHidden = YES;
            break;
        }
    }
}

- (void)setupDefaultElements {
    if (self.parentBrowser) {
        [self.browserSegmentedControl setTitle:AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section") forSegmentAtIndex:0];
        [self.browserSegmentedControl setTitle:AMLocalizedString(@"incoming", @"Title of the 'Incoming' Shared Items.") forSegmentAtIndex:1];
    } else {
        self.browserSegmentedControlView.hidden = YES;
        self.tableViewTopConstraint.constant = -self.browserSegmentedControlView.frame.size.height;
    }
    
    self.toolBarNewFolderBarButtonItem.title = AMLocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'");
    [self.toolBarNewFolderBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
}

- (void)reloadUI {
    switch (self.browserSegmentedControl.selectedSegmentIndex) {
        case 0: { //Cloud Drive
            [self setParentNodeForBrowserAction];
            
            self.parentShareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
            (self.parentShareType == MEGAShareTypeAccessRead) ? [self setToolbarItemsEnabled:NO] : [self setToolbarItemsEnabled:YES];
            
            [self setNavigationBarTitle];
            break;
        }
            
        case 1: { //Incoming
            [self setParentNodeForBrowserAction];
            
            [self setNavigationBarTitle];
            
            [self setToolbarItemsEnabled:NO];
            break;
        }
    }
    
    [self.tableView reloadData];
}

- (void)setParentNodeForBrowserAction {
    switch (self.browserSegmentedControl.selectedSegmentIndex) {
        case 0: { //Cloud Drive
            if (self.isParentBrowser) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
                self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
            } else {
                self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
            }
            break;
        }
            
        case 1: { //Incoming
            if (self.isParentBrowser) {
                self.parentNode = nil;
                self.nodes = [[MEGASdkManager sharedMEGASdk] inShares];
                self.shares = [[MEGASdkManager sharedMEGASdk] inSharesList];
            } else {
                self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
            }
            break;
        }
    }
}

- (void)setNavigationBarTitle {
    [self updatePromptTitle];
    
    if (self.isParentBrowser) {
        if (self.browserAction == BrowserActionDocumentProvider) {
            self.navigationItem.title = @"MEGA";
            self.extendedNavigationBar_label.text = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
        } else {
            self.navigationItem.title = (self.browserSegmentedControl.selectedSegmentIndex == 0) ? AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section") : AMLocalizedString(@"sharedItems", @"Title of Shared Items section");
        }
    } else {
        if (self.isChildBrowserFromIncoming) {
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
                self.navigationItem.titleView = label;
            } else {
                self.navigationItem.title = [NSString stringWithFormat:@"(%@)", accessTypeString];
            }
        } else {
            if (self.browserAction == BrowserActionDocumentProvider) {
                self.navigationItem.title = @"MEGA";
                self.extendedNavigationBar_label.text = self.parentNode.name;
            } else {
                self.navigationItem.title = self.parentNode.name;
            }
        }
    }
}

- (void)updatePromptTitle {
    if (self.browserAction == BrowserActionSendFromCloudDrive) {
        NSString *promptString;
        NSUInteger selectedNodesCount = self.selectedNodesMutableDictionary.count;
        if (selectedNodesCount == 0) {
            promptString = AMLocalizedString(@"selectFiles", @"Text of the button for user to select files in MEGA.");
        } else {
            promptString = (selectedNodesCount <= 1) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), selectedNodesCount] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), selectedNodesCount];
        }
        self.navigationItem.prompt = promptString;
    } else if (self.browserAction != BrowserActionDocumentProvider) {
        self.navigationItem.prompt = AMLocalizedString(@"selectDestination", @"Title shown on the navigation bar to explain that you have to choose a destination for the files and/or folders in case you copy, move, import or do some action with them.");
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
    self.toolbarSendBarButtonItem.enabled = boolValue;
}

- (void)setNodeTableViewCell:(NodeTableViewCell *)cell enabled:(BOOL)boolValue {
    cell.userInteractionEnabled = boolValue;
    cell.nameLabel.enabled = boolValue;
    cell.infoLabel.enabled = boolValue;
    boolValue ? (cell.thumbnailImageView.alpha = 1.0) : (cell.thumbnailImageView.alpha = 0.5);
}

- (void)setNodeTableViewCell:(NodeTableViewCell *)cell selected:(BOOL)boolValue {
    cell.checkImageView.hidden = boolValue ? NO : YES;
    cell.backgroundColor = boolValue ? [UIColor mnz_grayF9F9F9] : nil;
}

- (void)pushBrowserWithParentNode:(MEGANode *)parentNode {
    BrowserViewController *browserVC = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewControllerID"];
    browserVC.browserAction = self.browserAction;
    browserVC.childBrowser = YES;
    browserVC.childBrowserFromIncoming = ((self.browserSegmentedControl.selectedSegmentIndex == 1) || self.isChildBrowserFromIncoming) ? YES : NO;
    browserVC.localpath = self.localpath;
    browserVC.parentNode = parentNode;
    browserVC.selectedNodesMutableDictionary = self.selectedNodesMutableDictionary;
    browserVC.selectedNodesArray = self.selectedNodesArray;
    browserVC.selectedUsersArray = self.selectedUsersArray;
    
    [self.navigationController pushViewController:browserVC animated:YES];
}

- (void)attachNodes {
    self.selectedNodes(self.selectedNodesMutableDictionary.allValues.copy);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareNodesWithLevel:(MEGAShareType)shareType {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    self.remainingOperations = self.selectedUsersArray.count;
    
    for (MEGAUser *user in self.selectedUsersArray) {
        [[MEGASdkManager sharedMEGASdk] shareNode:self.parentNode withUser:user level:shareType];
    }
}

- (void)alertControllerShouldEnableDefaultButtonForTextField:(UITextField *)sender {
    UIAlertController *addContactFromEmailAlertController = (UIAlertController *)self.presentedViewController;
    if (addContactFromEmailAlertController) {
        UITextField *textField = addContactFromEmailAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = addContactFromEmailAlertController.actions.lastObject;
        rightButtonAction.enabled = (textField.text.length > 0);
    }
}

#pragma mark - IBActions

- (IBAction)browserSegmentedControl:(UISegmentedControl *)sender {
    [self reloadUI];
}

- (IBAction)moveNode:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        self.remainingOperations = self.selectedNodesArray.count;
        
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
            self.remainingOperations++;
            MEGANode *tempNode = (self.browserAction == BrowserActionImportFromFolderLink) ? [[MEGASdkManager sharedMEGASdkFolder] authorizeNode:node] : node;
            [[MEGASdkManager sharedMEGASdk] copyNode:tempNode newParent:self.parentNode];
        }
    }
}

- (IBAction)newFolder:(UIBarButtonItem *)sender {
    UIAlertController *newFolderAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [newFolderAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = AMLocalizedString(@"newFolderMessage", @"Hint text shown on the create folder alert.");
        [textField addTarget:self action:@selector(alertControllerShouldEnableDefaultButtonForTextField:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [newFolderAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [newFolderAlertController dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *createFolderAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"createFolderButton", @"Title button for the create folder alert.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = [[newFolderAlertController textFields] firstObject];
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:textField.text parent:self.parentNode];
            [newFolderAlertController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    createFolderAlertAction.enabled = NO;
    [newFolderAlertController addAction:createFolderAlertAction];
    
    [self presentViewController:newFolderAlertController animated:YES completion:nil];
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
        UIAlertController *shareFolderAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"permissions", @"Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [shareFolderAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        UIAlertAction *fullAccessAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"fullAccess", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self shareNodesWithLevel:MEGAShareTypeAccessFull];
        }];
        [fullAccessAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
        [shareFolderAlertController addAction:fullAccessAlertAction];
        
        UIAlertAction *readAndWritetAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readAndWrite", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self shareNodesWithLevel:MEGAShareTypeAccessReadWrite];
        }];
        [readAndWritetAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
        [shareFolderAlertController addAction:readAndWritetAlertAction];
        
        UIAlertAction *readOnlyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self shareNodesWithLevel:MEGAShareTypeAccessRead];
        }];
        [readOnlyAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
        [shareFolderAlertController addAction:readOnlyAlertAction];
        
        shareFolderAlertController.modalPresentationStyle = UIModalPresentationPopover;
        shareFolderAlertController.popoverPresentationController.sourceRect = self.view.frame;
        shareFolderAlertController.popoverPresentationController.sourceView = self.view;
        
        [self presentViewController:shareFolderAlertController animated:YES completion:nil];
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

- (IBAction)extendedNavigationBar_backButtonTapped:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    
    if (self.browserAction == BrowserActionSendFromCloudDrive) {
        if (node.isFolder) {
            [self setNodeTableViewCell:cell selected:NO];
        } else {
            ([self.selectedNodesMutableDictionary objectForKey:node.base64Handle] != nil) ? [self setNodeTableViewCell:cell selected:YES] : [self setNodeTableViewCell:cell selected:NO];
        }
    } else if (self.browserAction == BrowserActionDocumentProvider) {
        //TODO: Document Provider
    } else {
        if (node.isFile) {
            [self setNodeTableViewCell:cell enabled:NO];
        } else {
            (shareType == MEGAShareTypeAccessRead) ? [self setNodeTableViewCell:cell enabled:NO] : [self setNodeTableViewCell:cell enabled:YES];
        }
    }
    
    if ([node hasThumbnail]) {
        cell.nodeHandle = [node handle];
        [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
    } else {
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
    MEGANode *selectedNode = [self.nodes nodeAtIndex:indexPath.row];
    
    if (selectedNode.isFolder) {
        [self pushBrowserWithParentNode:selectedNode];
    } else {
        switch (self.browserAction) {
            case BrowserActionSendFromCloudDrive: {
                NodeTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell.checkImageView.hidden) {
                    [self.selectedNodesMutableDictionary setObject:selectedNode forKey:selectedNode.base64Handle];
                    [self setNodeTableViewCell:cell selected:YES];
                } else {
                    [self.selectedNodesMutableDictionary removeObjectForKey:selectedNode.base64Handle];
                    [self setNodeTableViewCell:cell selected:NO];
                }
                
                [self updatePromptTitle];
                break;
            }
                
            case BrowserActionDocumentProvider: {
                //TODO: Document Provider
                break;
            }
                
            default:
                break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if ((self.browserSegmentedControl.selectedSegmentIndex == 1) && self.isParentBrowser) {
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
        if ((self.browserSegmentedControl.selectedSegmentIndex == 1) && self.isParentBrowser) {
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
            self.remainingOperations--;
            
            if (self.remainingOperations == 0) {
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
            self.remainingOperations--;
            
            if (self.remainingOperations == 0) {
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
                    
                    [[MEGASdkManager sharedMEGASdkFolder] logout];
                }
                
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeShare: {
            self.remainingOperations--;
            
            if (self.remainingOperations == 0) {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudSharedFolder"] status:AMLocalizedString(@"sharedFolder_success", nil)];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeCreateFolder: {
            MEGANode *newFolderNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            [self pushBrowserWithParentNode:newFolderNode];
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
