/**
 * @file MoveNodeTableViewController.m
 * @brief View controller to select the destination folder for a moved node.
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

#import "MEGAReachabilityManager.h"

#import "BrowserViewController.h"
#import "NodeTableViewCell.h"
#import "Helper.h"
#import "SVProgressHUD.h"

@interface BrowserViewController () <UIAlertViewDelegate> {
    UIAlertView *folderAlertView;
    NSUInteger remainingOperations;
}

@property (nonatomic, strong) MEGANodeList *nodes;
@property (nonatomic, strong) NSMutableArray *folderNodes;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

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
    
    [_cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    [_cancelBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_cancelBarButtonItem.tag] forState:UIControlStateNormal];
    
    [_toolBarNewFolderBarButtonItem setTitle:AMLocalizedString(@"newFolder", @"New Folder")];
    [_toolBarNewFolderBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarNewFolderBarButtonItem.tag] forState:UIControlStateNormal];
    
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

#pragma mark - Private

- (void)setupBrowser {
    switch (self.browserAction) {
        case BrowserActionCopy: {
            [_toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"copy", nil)];
            [_toolBarCopyBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarCopyBarButtonItem.tag] forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarCopyBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionMove: {
            [_toolBarMoveBarButtonItem setTitle:AMLocalizedString(@"move", nil)];
            [_toolBarMoveBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarMoveBarButtonItem.tag] forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarMoveBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionImport:
        case BrowserActionImportFromFolderLink: {
            [_toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"import", nil)];
            [_toolBarCopyBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarCopyBarButtonItem.tag] forState:UIControlStateNormal];
            
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
            [_toolBarShareFolderBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarShareFolderBarButtonItem.tag] forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarShareFolderBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionOpenIn: {
            [_toolBarSaveInMegaBarButtonItem setTitle:AMLocalizedString(@"upload", nil)];
            [_toolBarSaveInMegaBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarSaveInMegaBarButtonItem.tag] forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarSaveInMegaBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
    }
}

- (void)reloadUI {
    self.folderNodes = [NSMutableArray new];
    
    if ([self.parentNode.name isEqualToString:[[[MEGASdkManager sharedMEGASdk] rootNode] name]]) {
        [self.navigationItem setTitle:AMLocalizedString(@"cloudDrive", @"Cloud drive")];
        self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
    } else {
        [self.navigationItem setTitle:[self.parentNode name]];
        self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
    }
    
    if ((self.browserAction == BrowserActionImport) || (self.browserAction == BrowserActionImportFromFolderLink)) {
        NSString *importTitle = AMLocalizedString(@"importTitle", nil);
        importTitle = [NSString stringWithFormat:@"%@ %@", importTitle, [self.navigationItem title]];
        [self.navigationItem setTitle:importTitle];
    }
    
    for (NSInteger i = 0; i < self.nodes.size.integerValue; i++) {
        MEGANode *node = [self.nodes nodeAtIndex:i];
        
        if (node.isFolder) {
            [self.folderNodes addObject:node];
        }
    }
    
    [self.tableView reloadData];
}

- (NSDictionary *)titleTextAttributesForButton:(NSInteger)buttonTag {
    
    NSMutableDictionary *titleTextAttributesDictionary = [[NSMutableDictionary alloc] init];
    
    switch (buttonTag) {
        case 0:
            [titleTextAttributesDictionary setValue:[UIFont fontWithName:kFont size:17.0] forKey:NSFontAttributeName];
            break;
            
        case 1:
            [titleTextAttributesDictionary setValue:[UIFont fontWithName:@"SFUIText-Regular" size:17.0] forKey:NSFontAttributeName];
            break;
    }
    
    [titleTextAttributesDictionary setObject:[UIColor mnz_redD90007] forKey:NSForegroundColorAttributeName];
    
    return titleTextAttributesDictionary;
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
            [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:parentNode];
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

#pragma mark - IBActions

- (IBAction)moveNode:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        remainingOperations = self.selectedNodesArray.count;
        
        for (MEGANode *n in self.selectedNodesArray) {
            [[MEGASdkManager sharedMEGASdk] moveNode:n newParent:self.parentNode];
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)copyNode:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
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
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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
    if ([MEGAReachabilityManager isReachable]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:AMLocalizedString(@"permissions", nil)
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"readOnly", nil), AMLocalizedString(@"readAndWrite", nil), AMLocalizedString(@"fullAccess", nil), nil];
        if ([[UIDevice currentDevice] iPadDevice]) {
            [actionSheet showInView:self.view];
        } else {
            if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
                UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
                if ([window.subviews containsObject:self.view]) {
                    [actionSheet showInView:self.view];
                } else {
                    [actionSheet showInView:window];
                }
            } else {
                [actionSheet showFromTabBar:self.tabBarController.tabBar];
            }
        }
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
    }
}

- (IBAction)uploadToMega:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"uploadStarted_Message", nil)];
        [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:self.localpath parent:self.parentNode];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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

//For iOS 7 UIActionSheet color
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:[UIColor mnz_redD90007] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([MEGAReachabilityManager isReachable]) {
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:[[folderAlertView textFieldAtIndex:0] text] parent:self.parentNode];
        } else {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.folderNodes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NodeTableViewCell *cell = (NodeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    
    MEGANode *node = [self.folderNodes objectAtIndex:indexPath.row];
    
    [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    
    cell.nameLabel.text = [node name];
    
    cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *newParent = [self.folderNodes objectAtIndex:indexPath.row];
    
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
    
    [self.navigationController pushViewController:browserVC animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeCopy: {
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
//                NSString *message = (self.selectedNodesArray.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"fileMoved", nil)] : [NSString stringWithFormat:AMLocalizedString(@"filesMoved", nil), self.selectedNodesArray.count];
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
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

@end
