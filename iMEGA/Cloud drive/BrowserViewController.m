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

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIButton *shareFolderButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarMoveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarNewFolderBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarCopyBarButtonItem;

@end

@implementation BrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    
    if (self.browseAction == BrowseActionCopy) {
        NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
        [toolbarButtons removeObject:self.toolBarMoveBarButtonItem];
        [toolbarButtons removeObject:[self.toolbar.items objectAtIndex:1]]; // Remove the 1st flexible space
        [self.toolbar setItems:toolbarButtons];
    } else {
        [self.toolBarMoveBarButtonItem setTitle:AMLocalizedString(@"browserVC_moveButton", @"Move")];
    }
    
    [self.toolBarNewFolderBarButtonItem setTitle:AMLocalizedString(@"browserVC_newFolderButton", @"New folder")];
    
    if (self.isPublicNode) {
        [self.toolBarMoveBarButtonItem setEnabled:NO];
        [self.toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"browserVC_importButton", @"Import")];
    } else {
        [self.toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"browserVC_copyButton", @"Copy")];
    }
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

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)reloadUI {
    self.folderNodes = [NSMutableArray new];
    
    if ([self.parentNode.name isEqualToString:[[[MEGASdkManager sharedMEGASdk] rootNode] name]]) {
        [self.navigationItem setTitle:AMLocalizedString(@"cloudDrive", @"Cloud drive")];
        self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
    } else {
        [self.navigationItem setTitle:[self.parentNode name]];
        self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
    }
    
    if (self.isPublicNode) {
        NSString *importTitle = AMLocalizedString(@"importTitle", @"Import to ");
        importTitle = [importTitle stringByAppendingString:[self.navigationItem title]];
        [self.navigationItem setTitle:importTitle];
    }
    
    for (NSInteger i = 0; i < self.nodes.size.integerValue; i++) {
        MEGANode *node = [self.nodes nodeAtIndex:i];
        
        if (node.isFolder) {
            [self.folderNodes addObject:node];
        }
    }
    
    if (self.selectedUsersArray) {
        [self.toolbar setFrame:CGRectMake(0, 0, 0, 0)];
        
        [self.shareFolderButton setEnabled:YES];
        [self.shareFolderButton setHidden:NO];
        
        NSString *sharedFolderString = [AMLocalizedString(@"select", nil) stringByAppendingString:[self.navigationItem title]];
        [self.shareFolderButton setTitle:sharedFolderString forState:UIControlStateNormal];
    }
    
    [self.tableView reloadData];
}



- (NSString *)stringByFiles:(NSInteger)files andFolders:(NSInteger)folders {
    if (files > 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFiles", @"Folders, files"), (int)folders, (int)files];
    }
    
    if (files > 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFiles", @"Folder, files"), (int)folders, (int)files];
    }
    
    if (files > 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"files", @"Files"), (int)files];
    }
    
    if (files == 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFile", @"Folders, file"), (int)folders, (int)files];
    }
    
    if (files == 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFile", @"Folder, file"), (int)folders, (int)files];
    }
    
    if (files == 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFile", @"File"), (int)files];
    }
    
    if (!files && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folders", @"Folders"), (int)folders];
    }
    
    if (!files && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFolder", @"Folder"), (int)folders];
    }
    
    return AMLocalizedString(@"emptyFolder", @"Empty folder");
}

#pragma mark - IBActions

- (IBAction)moveNode:(UIBarButtonItem *)sender {
    remainingOperations = self.selectedNodesArray.count;
    
    for (MEGANode *n in self.selectedNodesArray) {
        [[MEGASdkManager sharedMEGASdk] moveNode:n newParent:self.parentNode];
    }
}

- (IBAction)copyNode:(UIBarButtonItem *)sender {
    remainingOperations = self.selectedNodesArray.count;
    
    for (MEGANode *n in self.selectedNodesArray) {
        [[MEGASdkManager sharedMEGASdk] copyNode:n newParent:self.parentNode];
    }
    
}

- (IBAction)newFolder:(UIBarButtonItem *)sender {
    folderAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"newFolderTitle", @"Create new folder") message:AMLocalizedString(@"newFolderMessage", @"Name for the new folder") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"createFolderButton", @"Create"), nil];
    [folderAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [folderAlertView textFieldAtIndex:0].text = @"";
    [folderAlertView show];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        [folderAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectSharedFolder:(UIButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:AMLocalizedString(@"readOnly", nil), AMLocalizedString(@"readAndWrite", nil), AMLocalizedString(@"fullAccess", nil), nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
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
        [[MEGASdkManager sharedMEGASdk] createFolderWithName:[[folderAlertView textFieldAtIndex:0] text] parent:self.parentNode];
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
    
    NSInteger files = [[MEGASdkManager sharedMEGASdk] numberChildFilesForParent:node];
    NSInteger folders = [[MEGASdkManager sharedMEGASdk] numberChildFoldersForParent:node];
    
    NSString *filesAndFolders = [self stringByFiles:files andFolders:folders];
    
    cell.infoLabel.text = filesAndFolders;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *newParent = [self.folderNodes objectAtIndex:indexPath.row];
    
    BrowserViewController *mcnvc = [self.storyboard instantiateViewControllerWithIdentifier:@"moveNodeID"];
    [mcnvc setParentNode:newParent];
    [mcnvc setSelectedNodesArray:self.selectedNodesArray];
    
    if (self.selectedUsersArray) {
        [mcnvc setSelectedUsersArray:self.selectedUsersArray];
    }
    
    if(self.isPublicNode) {
        [mcnvc setIsPublicNode:YES];
    }
    
    [mcnvc setBrowseAction:self.browseAction];
    
    [self.navigationController pushViewController:mcnvc animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEOverQuota) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"quotaExceeded", @"Storage quota exceeded")];
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeMove: {
            remainingOperations--;
            
            if (remainingOperations == 0) {
                NSString *message = (self.selectedNodesArray.count <= 1 ) ? AMLocalizedString(@"fileMoved", nil) : [NSString stringWithFormat:AMLocalizedString(@"filesMoved", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
        
        case MEGARequestTypeCopy: {
            if (self.isPublicNode) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"fileImported", @"File imported!")];
                break;
            }
            
            remainingOperations--;
            
            if (remainingOperations == 0) {
                NSString *message = (self.selectedNodesArray.count <= 1 ) ? AMLocalizedString(@"fileCopied", nil) : [NSString stringWithFormat:AMLocalizedString(@"filesCopied", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
            
        case MEGARequestTypeShare: {
            remainingOperations--;
            
            if (remainingOperations == 0) {
//                NSString *message = (self.selectedNodesArray.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"fileMoved", nil)] : [NSString stringWithFormat:AMLocalizedString(@"filesMoved", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"sharedFolder_success", @"Folder shared!")];
                [self dismissViewControllerAnimated:YES completion:nil];
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
