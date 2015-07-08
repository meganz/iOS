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
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"

@interface DetailsNodeInfoViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MEGADelegate> {
    UIAlertView *cancelDownloadAlertView;
    UIAlertView *renameAlertView;
    UIAlertView *removeAlertView;
    
    NSInteger actions;
    MEGAShareType accessType;
}

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *modificationTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DetailsNodeInfoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
            
        case MEGAShareTypeAccessOwner:
            //Cloud drive
            if (self.displayMode == DisplayModeCloudDrive) {
                actions = 5; //Download, get link, *share*, move & copy, rename, move to rubbish bin
            } else {
                //Rubbish bin
                actions = 4; //Download, move or copy, rename, remove
            }
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
            NSString *thumbnailFilePath = [Helper pathForNode:self.node searchPath:NSCachesDirectory directory:@"thumbs"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            if (!thumbnailExists) {
                [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
            } else {
                [self.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
            }
        } else {
            [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
        }
    } else if ([self.node type] == MEGANodeTypeFolder) {
        [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
    }
    
    self.nameLabel.text = [self.node name];
    
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
    
    self.modificationTimeLabel.text = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    
    if ([self.node isFile]) {
        self.sizeLabel.text = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
    } else {
        self.sizeLabel.text = [NSByteCountFormatter stringFromByteCount:[[[MEGASdkManager sharedMEGASdk] sizeForNode:self.node] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
    }
    
    self.title = [self.node name];
}

#pragma mark - Private methods

- (void)download {
    if ([MEGAReachabilityManager isReachable]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:self.node]) {
            return;
        }
        
        if ([self.node type] == MEGANodeTypeFile) {
            [Helper downloadNode:self.node folder:@"" folderLink:NO];
        } else if ([self.node type] == MEGANodeTypeFolder) {
            NSString *folderName = [[[self.node base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[self.node name]]];
            NSString *folderPath = [[Helper pathForOffline] stringByAppendingPathComponent:folderName];
            
            if ([Helper createOfflineFolder:folderName folderPath:folderPath]) {
                [self.navigationController popViewControllerAnimated:YES];
                [Helper downloadNodesOnFolder:folderPath parentNode:self.node folderLink:NO];
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"downloadStarted", @"Download started")];
            }
        }
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

- (void)copyAndMove:(BOOL)move {
    if ([MEGAReachabilityManager isReachable]) {
        MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"moveNodeNav"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
        browserVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
        
        move ? [browserVC setBrowseAction:BrowseActionCopyAndMove] : [browserVC setBrowseAction:BrowseActionCopy];
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}

- (void)rename {
    if ([MEGAReachabilityManager isReachable]) {
        if (!renameAlertView) {
            renameAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"renameNodeTitle", @"Rename") message:AMLocalizedString(@"renameNodeMessage", @"Enter the new name") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"renameNodeButton", @"Rename"), nil];
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
                removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"remove", nil) message:AMLocalizedString(@"removeNodeFromRubbishBinMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"ok", @"OK"), nil];
            }
            
            //Move to rubbish bin
            if (self.displayMode == DisplayModeCloudDrive) {
                removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveNodeToRubbishBinTitle", @"Remove node") message:AMLocalizedString(@"moveNodeToRubbishBinMessage", @"Are you sure?") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"ok", @"OK"), nil];
            }
            
            [removeAlertView setTag:1];
            [removeAlertView show];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
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
            if ([[Helper downloadedNodes] objectForKey:self.node.base64Handle] != nil) {
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
                    [cell.textLabel setText:AMLocalizedString(@"copy", @"Copy")];
                    break;
                
                case 2:
                    [cell.imageView setImage:[UIImage imageNamed:@"rename"]];
                    [cell.textLabel setText:AMLocalizedString(@"rename", @"Rename")];
                    break;
                    
                case 3:
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [cell.imageView setImage:[UIImage imageNamed:@"remove"]];
                        [cell.textLabel setText:AMLocalizedString(@"remove", @"Remove")];
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
                        [cell.imageView setImage:[UIImage imageNamed:@"getLink"]];
                        [cell.textLabel setText:AMLocalizedString(@"getLink", @"Get link")];
                        break;
                        
                    case 2:
                        [cell.imageView setImage:[UIImage imageNamed:@"move"]];
                        [cell.textLabel setText:AMLocalizedString(@"move", @"Move")];
                        break;
                        
                    case 3:
                        [cell.imageView setImage:[UIImage imageNamed:@"rename"]];
                        [cell.textLabel setText:AMLocalizedString(@"rename", @"Rename")];
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
                        [cell.textLabel setText:AMLocalizedString(@"move", @"Move")];
                        break;
                        
                    case 2:
                        [cell.imageView setImage:[UIImage imageNamed:@"rename"]];
                        [cell.textLabel setText:AMLocalizedString(@"rename", @"Rename")];
                        break;
                        
                    case 3:
                        [cell.imageView setImage:[UIImage imageNamed:@"remove"]];
                        [cell.textLabel setText:AMLocalizedString(@"remove", @"Remove")];
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
        case 0: {
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
                if ([[Helper downloadedNodes] objectForKey:self.node.base64Handle] != nil) {
                    break;
                } else {
                   [self download];
                }
            }
            break;
        }
            
        case 1:
            switch (accessType) {
                case MEGAShareTypeAccessRead:
                case MEGAShareTypeAccessReadWrite:
                case MEGAShareTypeAccessFull:
                    [self copyAndMove:NO];
                    break;
                    
                case MEGAShareTypeAccessOwner:
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [self getLink];
                    } else {
                        [self copyAndMove:YES];
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 2:
            switch (accessType) {
                case MEGAShareTypeAccessRead:
                case MEGAShareTypeAccessReadWrite:
                    [self delete];
                    break;
                    
                case MEGAShareTypeAccessFull:
                    [self rename];
                    break;
                    
                case MEGAShareTypeAccessOwner:
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [self copyAndMove:YES];
                    } else {
                        [self rename];
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 3:
            switch (accessType) {
                case MEGAShareTypeAccessFull:
                    [self delete];
                    break;
                    
                case MEGAShareTypeAccessOwner:
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [self rename];
                    } else {
                        [self delete];
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 4:
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
                NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
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
            
            NSString *name = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"fileName", nil), n.name];
            NSString *size = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"fileSize", nil), n.isFile ? [NSByteCountFormatter stringFromByteCount:[[n size] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory] : AMLocalizedString(@"folder", nil)];
            NSString *link = [request link];
            
            NSArray *itemsArray = [NSArray arrayWithObjects:name, size, link, nil];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsArray applicationActivities:nil];
            activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
            
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                activityVC.popoverPresentationController.sourceView = self.view;
                activityVC.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 4, 0, 0);
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
        if (([[Helper downloadedNodes] objectForKey:base64Handle] != nil) && ([self.node.base64Handle isEqualToString:base64Handle])) {
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
