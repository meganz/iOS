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
#import "NSString+MNZCategory.h"

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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolBarSaveInMegaBarButtonItem;

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

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
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
            
        case BrowserActionImport: {
            [_toolBarCopyBarButtonItem setTitle:AMLocalizedString(@"import", nil)];
            [_toolBarCopyBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_toolBarCopyBarButtonItem.tag] forState:UIControlStateNormal];
            
            NSMutableArray *toolbarButtons = [self.toolbar.items mutableCopy];
            [toolbarButtons addObject:_toolBarCopyBarButtonItem];
            [self.toolbar setItems:toolbarButtons];
            break;
        }
            
        case BrowserActionSelectFolderToShare: {
            [_toolbar setHidden:YES];
            [_shareFolderButton setEnabled:YES];
            [_shareFolderButton setHidden:NO];
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
    
    if (self.browserAction == BrowserActionImport) {
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
        NSString *sharedFolderString = [AMLocalizedString(@"select", nil) stringByAppendingString:[self.navigationItem title]];
        [self.shareFolderButton setTitle:sharedFolderString forState:UIControlStateNormal];
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
            [titleTextAttributesDictionary setValue:[UIFont fontWithName:@"HelveticaNeue-Regular" size:17.0] forKey:NSFontAttributeName];
            break;
    }
    
    [titleTextAttributesDictionary setObject:megaRed forKey:NSForegroundColorAttributeName];
    
    return titleTextAttributesDictionary;
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
        remainingOperations = self.selectedNodesArray.count;
        
        for (MEGANode *n in self.selectedNodesArray) {
            [[MEGASdkManager sharedMEGASdk] copyNode:n newParent:self.parentNode];
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
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[inboxDirectory stringByAppendingPathComponent:file] error:&error];
            if (!success || error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
            }
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectSharedFolder:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"readOnly", nil), AMLocalizedString(@"readAndWrite", nil), AMLocalizedString(@"fullAccess", nil), nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
            [button setTitleColor:megaRed forState:UIControlStateNormal];
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
    
    NSInteger files = [[MEGASdkManager sharedMEGASdk] numberChildFilesForParent:node];
    NSInteger folders = [[MEGASdkManager sharedMEGASdk] numberChildFoldersForParent:node];
    
    NSString *filesAndFolders = [@"" stringByFiles:files andFolders:folders];
    
    cell.infoLabel.text = filesAndFolders;
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEOverQuota) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"quotaExceeded", nil)];
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
                [SVProgressHUD showSuccessWithStatus:message];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
        
        case MEGARequestTypeCopy: {
            if (self.browserAction == BrowserActionImport) {
                [self dismissViewControllerAnimated:YES completion:nil];
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"fileImported", @"File imported!")];
                break;
            }
            
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
                [SVProgressHUD showSuccessWithStatus:message];
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
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

@end
