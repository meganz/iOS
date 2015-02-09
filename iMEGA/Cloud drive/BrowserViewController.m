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

@end

@implementation BrowserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

#pragma mark - Private

- (void)reloadUI {
    self.folderNodes = [NSMutableArray new];
    
    if ([self.parentNode.name isEqualToString:[[[MEGASdkManager sharedMEGASdk] rootNode] name]]) {
        [self.navigationItem setTitle:NSLocalizedString(@"cloudDrive", @"Cloud drive")];
        self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
    } else {
        [self.navigationItem setTitle:[self.parentNode name]];
        self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
    }
    
    if (self.isPublicNode) {
        NSString *importTitle = @"Import to ";
        importTitle = [importTitle stringByAppendingString:[self.navigationItem title]];
        [self.navigationItem setTitle:importTitle];
        
        NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbar.items];
        
        [[items objectAtIndex:0] setEnabled:NO];
        [[items objectAtIndex:2] setTitle:@"Import"];
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
        
        NSString *sharedFolderString = [NSLocalizedString(@"select", nil) stringByAppendingString:[self.navigationItem title]];
        [self.shareFolderButton setTitle:sharedFolderString forState:UIControlStateNormal];
    }
    
    [self.tableView reloadData];
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

- (IBAction)add:(UIBarButtonItem *)sender {
    folderAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"newFolderTitle", @"Create new folder") message:NSLocalizedString(@"newFolderMessage", @"Name for the new folder") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"createFolderButton", @"Create"), nil];
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
                                                    cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"readOnly", nil), NSLocalizedString(@"readAndWrite", nil), NSLocalizedString(@"fullAccess", nil), nil];
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
    
    NSString *filesAndFolders;
    
    if (files == 0 || files > 1) {
        if (folders == 0 || folders > 1) {
            filesAndFolders = [NSString stringWithFormat:NSLocalizedString(@"foldersFiles", @"Folders, files"), (int)folders, (int)files];
        } else if (folders == 1) {
            filesAndFolders = [NSString stringWithFormat:NSLocalizedString(@"folderFiles", @"Folder, files"), (int)folders, (int)files];
        }
    } else if (files == 1) {
        if (folders == 0 || folders > 1) {
            filesAndFolders = [NSString stringWithFormat:NSLocalizedString(@"foldersFile", @"Folders, file"), (int)folders, (int)files];
        } else if (folders == 1) {
            filesAndFolders = [NSString stringWithFormat:NSLocalizedString(@"folderFile", @"Folders, file"), (int)folders, (int)files];
        }
    }
    
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
    
    [self.navigationController pushViewController:mcnvc animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEOverQuota) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"quotaExceeded", @"Storage quota exceeded")];
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeMove:
            remainingOperations--;
            
            if (remainingOperations == 0) {
                NSString *message = (self.selectedNodesArray.count <= 1 ) ? [NSString stringWithFormat:NSLocalizedString(@"fileMoved", nil)] : [NSString stringWithFormat:NSLocalizedString(@"filesMoved", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        
        case MEGARequestTypeCopy:
            if(self.isPublicNode) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"fileImported", @"File imported")];
                break;
            }
            
            remainingOperations--;
            
            if (remainingOperations == 0) {
                NSString *message = (self.selectedNodesArray.count <= 1 ) ? [NSString stringWithFormat:NSLocalizedString(@"fileCopied", nil)] : [NSString stringWithFormat:NSLocalizedString(@"filesCopied", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
            
        case MEGARequestTypeShare:
            remainingOperations--;
            
            if (remainingOperations == 0) {
//                NSString *message = (self.selectedNodesArray.count <= 1 ) ? [NSString stringWithFormat:NSLocalizedString(@"fileMoved", nil)] : [NSString stringWithFormat:NSLocalizedString(@"filesMoved", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:@"carpeta compartida"];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

@end
