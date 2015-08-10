/**
 * @file DetailsNodeInfoViewController.m
 * @brief View controller that show details info about a node
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

#import "DetailsNodeInfoViewController.h"
#import "SVProgressHUD.h"
#import "Helper.h"

#import "BrowserViewController.h"
#import "CloudDriveTableViewController.h"
#import "ContactsViewController.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"

#import "MEGAStore.h"

@interface DetailsNodeInfoViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MEGADelegate> {
    UIAlertView *cancelDownloadAlertView;
    UIAlertView *renameAlertView;
    UIAlertView *removeAlertView;
    
    NSInteger actions;
    MEGAShareType accessType;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *foldersFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DetailsNodeInfoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setRightBarButtonItem:_shareBarButtonItem];
    
    accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node];
    
    switch (accessType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite:
            if (self.displayMode == DisplayModeContact) {
                actions = 3; //Download, copy and leave
            } else {
                actions = 2; //Download and copy
            }
            break;
            
        case MEGAShareTypeAccessFull:
                actions = 4; //Download, copy, rename and leave (contacts) or delete (cloud drive)
            break;
            
        case MEGAShareTypeAccessOwner: //Cloud Drive & Rubbish Bin
            actions = 5; //Download, move, copy, rename and move to rubbish bin or remove
            break;
            
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadUI];
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)reloadUI {
    if ([self.node type] == MEGANodeTypeFile) {
        
        if ([self.node hasThumbnail]) {
            NSString *thumbnailFilePath = [Helper pathForNode:self.node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            if (!thumbnailExists) {
                [self.thumbnailImageView setImage:[Helper infoImageForNode:self.node]];
            } else {
                [self.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
            }
        } else {
            [self.thumbnailImageView setImage:[Helper infoImageForNode:self.node]];
        }
        
        [_foldersFilesLabel setHidden:YES];
        
    } else if ([self.node type] == MEGANodeTypeFolder) {
        
        [self.thumbnailImageView setImage:[Helper infoImageForNode:self.node]];
        
        NSInteger files = [[MEGASdkManager sharedMEGASdk] numberChildFilesForParent:_node];
        NSInteger folders = [[MEGASdkManager sharedMEGASdk] numberChildFoldersForParent:_node];
        
        NSString *filesAndFolders = [self stringByFiles:files andFolders:folders];
        [_foldersFilesLabel setText:filesAndFolders];
    }
    
    struct tm *timeinfo;
    char buffer[80];
    time_t rawtime;
    if ([self.node isFile]) {
        rawtime = [[self.node modificationTime] timeIntervalSince1970];
    } else {
        rawtime = [[self.node creationTime] timeIntervalSince1970];
    }
    timeinfo = localtime(&rawtime);
    
    strftime(buffer, 80, "%d/%m/%y %H:%M", timeinfo);
    
    [self setTitle:[self.node name]];
    
    [self.nameLabel setText:[self.node name]];
    
    NSString *date = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    NSString *size = [NSByteCountFormatter stringFromByteCount:[[[MEGASdkManager sharedMEGASdk] sizeForNode:self.node] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
    NSString *sizeAndDate = [NSString stringWithFormat:@"%@ • %@", size, date];
    
    [_infoLabel setText:sizeAndDate];
    
    [self.tableView reloadData];
}

#pragma mark - Private methods

- (void)download {
    if ([MEGAReachabilityManager isReachable]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:self.node isFolderLink:NO]) {
            return;
        }
        [Helper downloadNode:self.node folderPath:[Helper pathForOffline] isFolderLink:NO];
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"downloadStarted", nil)];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (void)getLink {
    if ([MEGAReachabilityManager isReachable]) {
        [[MEGASdkManager sharedMEGASdk] exportNode:self.node];
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (void)browserWithAction:(NSInteger)browserAction {
    if ([MEGAReachabilityManager isReachable]) {
        MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
        browserVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
        [browserVC setBrowserAction:browserAction]; //
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (void)rename {
    if ([MEGAReachabilityManager isReachable]) {
        if (!renameAlertView) {
            renameAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"rename", nil) message:AMLocalizedString(@"renameNodeMessage", @"Enter the new name") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"rename", nil), nil];
        }
        
        [renameAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [renameAlertView setTag:0];
        
        UITextField *textField = [renameAlertView textFieldAtIndex:0];
        [textField setDelegate:self];
        [textField setText:[self.node name]];
        
        [renameAlertView show];
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (void)delete {
    if ([MEGAReachabilityManager isReachable]) {
        //Leave folder or remove folder in a incoming shares
        if (self.displayMode == DisplayModeContact || (self.displayMode == DisplayModeCloudDrive && accessType == MEGAShareTypeAccessFull)) {
            [[MEGASdkManager sharedMEGASdk] removeNode:self.node];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            
            //Delete permanently
            if (self.displayMode == DisplayModeRubbishBin) {
                if ([self.node type] == MEGANodeTypeFolder) {
                    removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"remove", nil) message:AMLocalizedString(@"removeFolderToRubbishBinMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                } else {
                    removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"remove", nil) message:AMLocalizedString(@"removeFileToRubbishBinMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                }
            }
            
            //Move to rubbish bin
            if (self.displayMode == DisplayModeCloudDrive) {
                removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveNodeToRubbishBinTitle", @"Remove node") message:AMLocalizedString(@"moveNodeToRubbishBinMessage", @"Are you sure?") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
            }
            
            [removeAlertView setTag:1];
            [removeAlertView show];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
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
    
    return AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
}

#pragma mark - IBActions

- (IBAction)shareTouchUpInside:(UIBarButtonItem *)sender {
    if ([self.node type] == MEGANodeTypeFolder) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"shareFolder", nil), AMLocalizedString(@"getLink", nil), nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [actionSheet showFromBarButtonItem:_shareBarButtonItem animated:YES];
        } else {
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }
    } else if ([self.node type] == MEGANodeTypeFile) {
        [self getLink];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
            
        case 0: { //Share folder
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
            ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
            [contactsVC setNode:self.node];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self presentViewController:navigationController animated:YES completion:nil];
            }];
            break;
        }
            
        case 1: { //Get link
            [self getLink];
            break;
        }
            
        default:
            break;
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

#pragma mark - UIAlertDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable;
    if ([alertView tag] == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *newName = [textField text];
        NSString *newNameExtension = [newName pathExtension];
        NSString *newNameWithoutExtension = [newName stringByDeletingPathExtension];
        
        NSString *nodeNameString = [self.node name];
        NSString *nodeNameExtension = [NSString stringWithFormat:@".%@", [nodeNameString pathExtension]];
        
        switch ([self.node type]) {
            case MEGANodeTypeFile: {
                if ([newName isEqualToString:@""] ||
                    [newName isEqualToString:nodeNameString] ||
                    [newName isEqualToString:nodeNameExtension] ||
                    ![[NSString stringWithFormat:@".%@", newNameExtension] isEqualToString:nodeNameExtension] || //Particular case, for example: (.jp == .jpg)
                    [newNameWithoutExtension isEqualToString:nodeNameExtension]) {
                    shouldEnable = NO;
                } else {
                    shouldEnable = YES;
                }
                break;
            }
                
            case MEGANodeTypeFolder: {
                if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString]) {
                    shouldEnable = NO;
                } else {
                    shouldEnable = YES;
                }
                break;
            }
                
            default:
                shouldEnable = NO;
                break;
        }
        
    } else {
        shouldEnable = YES;
    }
    
    return shouldEnable;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        [textField setSelectedTextRange:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 0) {
        if (buttonIndex == 1) {
            UITextField *alertViewTextField = [alertView textFieldAtIndex:0];
            [[MEGASdkManager sharedMEGASdk] renameNode:self.node newName:[alertViewTextField text]];
        }
    } else if ([alertView tag] == 1) {
        if (buttonIndex == 1) {
            if (self.displayMode == DisplayModeRubbishBin) {
                [[MEGASdkManager sharedMEGASdk] removeNode:self.node];
            } else {
                [[MEGASdkManager sharedMEGASdk] moveNode:self.node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if ([alertView tag] == 2) {
        if (buttonIndex == 1) {
            NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:self.node.base64Handle];
            if (transferTag != nil) {
                [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return actions;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"NodeDetailsTableViewCellID"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NodeDetailsTableViewCellID"];
    }
    
    //Is the same for all posibilities
    if (indexPath.row == 0) {
        if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
            [cell.imageView setImage:[UIImage imageNamed:@"download"]];
            [cell.textLabel setText:AMLocalizedString(@"queued", @"Queued")];
            return cell;
        } else {
            
            MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:self.node]];
            
            if (offlineNode != nil) {
                [cell.imageView setImage:[UIImage imageNamed:@"downloaded"]];
                [cell.textLabel setText:AMLocalizedString(@"savedForOffline", @"Saved for offline")];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"download"]];
                [cell.textLabel setText:AMLocalizedString(@"saveForOffline", @"Save for Offline")];
            }
        }
    }
    
    switch (accessType) {
        case MEGAShareTypeAccessReadWrite:
        case MEGAShareTypeAccessRead:
            switch (indexPath.row) {
                case 1:
                    [cell.imageView setImage:[UIImage imageNamed:@"copy"]];
                    [cell.textLabel setText:AMLocalizedString(@"copy", @"Copy")];
                    break;
                    
                case 2:
                    [cell.imageView setImage:[UIImage imageNamed:@"leaveShare"]];
                    [cell.textLabel setText:AMLocalizedString(@"leaveFolder", @"Leave")];
                    break;
            }
            break;
            
        case MEGAShareTypeAccessFull:
            switch (indexPath.row) {
                case 1:
                    [cell.imageView setImage:[UIImage imageNamed:@"copy"]];
                    [cell.textLabel setText:AMLocalizedString(@"copy", nil)];
                    break;
                
                case 2:
                    [cell.imageView setImage:[UIImage imageNamed:@"rename"]];
                    [cell.textLabel setText:AMLocalizedString(@"rename", nil)];
                    break;
                    
                case 3:
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [cell.imageView setImage:[UIImage imageNamed:@"remove"]];
                        [cell.textLabel setText:AMLocalizedString(@"remove", nil)];
                    } else {
                        [cell.imageView setImage:[UIImage imageNamed:@"leaveShare"]];
                        [cell.textLabel setText:AMLocalizedString(@"leaveFolder", @"Leave")];
                    }
                    
                    break;
            }
            break;
            
        case MEGAShareTypeAccessOwner:
            if (self.displayMode == DisplayModeCloudDrive) {
                switch (indexPath.row) {
                    case 1:
                        [cell.imageView setImage:[UIImage imageNamed:@"move"]];
                        [cell.textLabel setText:AMLocalizedString(@"move", nil)];
                        break;
                        
                    case 2:
                        [cell.imageView setImage:[UIImage imageNamed:@"copy"]];
                        [cell.textLabel setText:AMLocalizedString(@"copy", nil)];
                        break;
                        
                    case 3:
                        [cell.imageView setImage:[UIImage imageNamed:@"rename"]];
                        [cell.textLabel setText:AMLocalizedString(@"rename", nil)];
                        break;
                        
                    case 4:
                        [cell.imageView setImage:[UIImage imageNamed:@"rubbishBin"]];
                        [cell.textLabel setText:AMLocalizedString(@"moveToRubbishBin", @"Move to the rubbish bin")];
                        break;
                }
                // Rubbish bin
            } else {
                switch (indexPath.row) {
                    case 1:
                        [cell.imageView setImage:[UIImage imageNamed:@"move"]];
                        [cell.textLabel setText:AMLocalizedString(@"move", nil)];
                        break;
                        
                    case 2:
                        [cell.imageView setImage:[UIImage imageNamed:@"copy"]];
                        [cell.textLabel setText:AMLocalizedString(@"copy", nil)];
                        break;
                        
                    case 3:
                        [cell.imageView setImage:[UIImage imageNamed:@"rename"]];
                        [cell.textLabel setText:AMLocalizedString(@"rename", nil)];
                        break;
                        
                    case 4:
                        [cell.imageView setImage:[UIImage imageNamed:@"remove"]];
                        [cell.textLabel setText:AMLocalizedString(@"remove", nil)];
                        break;
                }
            }
            
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0: { //Save for Offline
            if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
                if (!cancelDownloadAlertView) {
                    cancelDownloadAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"downloading", @"Downloading...")
                                                                         message:AMLocalizedString(@"cancelDownloadAlertViewText", @"Do you want to cancel the download?")
                                                                        delegate:self
                                                               cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                               otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                }
                [cancelDownloadAlertView setTag:2];
                [cancelDownloadAlertView show];
            } else {
                [self download];
            }
            break;
        }
            
        case 1:
            switch (accessType) {
                case MEGAShareTypeAccessRead:
                case MEGAShareTypeAccessReadWrite:
                case MEGAShareTypeAccessFull:
                    [self browserWithAction:BrowserActionCopy];
                    break;
                    
                case MEGAShareTypeAccessOwner:
                    [self browserWithAction:BrowserActionMove];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 2: //Copy
            switch (accessType) {
                case MEGAShareTypeAccessRead:
                case MEGAShareTypeAccessReadWrite:
                    [self delete];
                    break;
                    
                case MEGAShareTypeAccessFull:
                    [self rename];
                    break;
                    
                case MEGAShareTypeAccessOwner:
                    [self browserWithAction:BrowserActionCopy];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 3: //Rename
            switch (accessType) {
                case MEGAShareTypeAccessFull:
                    [self delete];
                    break;
                    
                case MEGAShareTypeAccessOwner:
                    [self rename];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 4: //Move to the Rubbish Bin / Remove
            [self delete];
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSString *nodeName = [textField text];
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextRange *textRange;
    
    switch ([self.node type]) {
        case MEGANodeTypeFile: {
            if ([[nodeName pathExtension] isEqualToString:@""] && [nodeName isEqualToString:[nodeName stringByDeletingPathExtension]]) { //File without extension
                UITextPosition *end = textField.endOfDocument;
                textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            } else {
                NSRange filenameRange = [nodeName rangeOfString:@"." options:NSBackwardsSearch];
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:filenameRange.location];
                textRange = [textField textRangeFromPosition:beginning  toPosition:beforeExtension];
            }
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        case MEGANodeTypeFolder: {
            UITextPosition *end = textField.endOfDocument;
            textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shouldChangeCharacters = YES;
    switch ([self.node type]) {
        case MEGANodeTypeFile: {
            NSString *textFieldString = [textField text];
            NSString *newName = [textFieldString stringByReplacingCharactersInRange:range withString:string];
            NSString *newNameExtension = [newName pathExtension];
            NSString *newNameWithoutExtension = [newName stringByDeletingPathExtension];
            
            NSString *nodeNameString = [self.node name];
            NSString *nodeNameExtension = [NSString stringWithFormat:@".%@", [nodeNameString pathExtension]];
            
            NSRange nodeWithoutExtensionRange = [[textFieldString stringByDeletingPathExtension] rangeOfString:[textFieldString stringByDeletingPathExtension]];
            NSRange nodeExtensionStartRange = [textFieldString rangeOfString:@"." options:NSBackwardsSearch];
            
            if ((range.location > nodeExtensionStartRange.location) ||
                (range.length > nodeWithoutExtensionRange.length) ||
                ([newName isEqualToString:newNameExtension] && [newNameWithoutExtension isEqualToString:nodeNameExtension]) ||
                ((range.location == nodeExtensionStartRange.location) && [string isEqualToString:@""])) {
                
                UITextPosition *beginning = textField.beginningOfDocument;
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:nodeExtensionStartRange.location];
                [textField setSelectedTextRange:[textField textRangeFromPosition:beginning toPosition:beforeExtension]];
                shouldChangeCharacters = NO;
            } else if (range.location < nodeExtensionStartRange.location) {
                shouldChangeCharacters = YES;
            }
            break;
        }
            
        case MEGANodeTypeFolder:
            shouldChangeCharacters = YES;
            break;
            
        default:
            shouldChangeCharacters = NO;
            break;
    }
    
    return shouldChangeCharacters;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeExport:
            [SVProgressHUD showWithStatus:AMLocalizedString(@"generatingLink", @"Generating link...")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrFile: {
            if ([request nodeHandle] == [self.node handle]) {
                MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[request nodeHandle]];
                NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                if (fileExists) {
                    [self.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                }
            }
            break;
        }
        case MEGARequestTypeExport: {
            [SVProgressHUD dismiss];
            
            MEGANode *n = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            
            NSString *name = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"name", nil), n.name];
            NSString *size = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"size", nil), n.isFile ? [NSByteCountFormatter stringFromByteCount:[[n size] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory] : AMLocalizedString(@"folder", nil)];
            NSString *link = [request link];
            
            NSArray *itemsArray = [NSArray arrayWithObjects:name, size, link, nil];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsArray applicationActivities:nil];
            activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
            
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                [activityVC.popoverPresentationController setBarButtonItem:_shareBarButtonItem];
            }
            
            [self presentViewController:activityVC animated:YES completion:nil];
            break;
        }
            
        case MEGARequestTypeCancelTransfer:
            [self.tableView reloadData];
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"transferCanceled", @"Transfer canceled!")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList{
}

- (void)onReloadNeeded:(MEGASdk *)api {
}

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    self.node = [nodeList nodeAtIndex:0];
    [self reloadUI];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:base64Handle];
        if (([transferTag integerValue] == transfer.tag) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [cell.textLabel setText:AMLocalizedString(@"queued", @"Queued")];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:base64Handle];
        if (([transferTag integerValue] == transfer.tag) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
            NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
            NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [cell.textLabel setText:[NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed]];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type] || ([transfer type] == MEGATransferTypeUpload)) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithBase64Handle:self.node.base64Handle];
        if ((offlineNode != nil) && ([self.node.base64Handle isEqualToString:base64Handle])) {
            if (cancelDownloadAlertView.visible) {
                [cancelDownloadAlertView dismissWithClickedButtonIndex:0 animated:YES];
            }
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:0];
            [cell.textLabel setText:AMLocalizedString(@"savedForOffline", @"Saved for offline")];
            [self.tableView reloadData];
        }
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
