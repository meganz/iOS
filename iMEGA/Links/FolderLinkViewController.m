/**
 * @file FolderLinkViewController.m
 * @brief View controller that allows to see and manage MEGA folder links.
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

#import "SVProgressHUD.h"
#import "SSKeychain.h"
#import "MWPhotoBrowser.h"

#import "FolderLinkViewController.h"
#import "MEGASdkManager.h"
#import "Helper.h"
#import "NodeTableViewCell.h"
#import "MainTabBarController.h"
#import "MEGAPreview.h"
#import "DetailsNodeInfoViewController.h"
#import "EmptyView.h"
#import "LoginViewController.h"

@interface FolderLinkViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, MWPhotoBrowserDelegate, MEGAGlobalDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    
    NSMutableArray *matchSearchNodes;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@end

@implementation FolderLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSLog(@"FolderLinkVC > viewDidLoad: %@", error);
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSLog(@"FolderLinkVC > viewDidLoad: %@", error);
        }
    }
    
    [self.navigationController.view setBackgroundColor:megaLightGray];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.importBarButtonItem setEnabled:NO];
    [self.downloadBarButtonItem setEnabled:NO];
    
    if (self.isFolderRootNode) {
        [MEGASdkManager sharedMEGASdkFolder];
        [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:self.folderLinkString delegate:self];

        [self.navigationItem setLeftBarButtonItem:self.cancelBarButtonItem];
        [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    } else {
        [self reloadUI];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdkFolder] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
    
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGARequestDelegate:self];
}

#pragma mark - Private

- (void)reloadUI {
    if (!self.parentNode) {
        self.parentNode = [[MEGASdkManager sharedMEGASdkFolder] rootNode];
    }
    
    NSString *titleString = NSLocalizedString(@"MEGA Folder", @"MEGA Folder");
    if ([self.parentNode name] != nil) {
        if (self.isFolderRootNode) {
            titleString = [titleString stringByAppendingString:@"/"];
            titleString = [titleString stringByAppendingString:[self.parentNode name]];
        } else {
            titleString = [self.parentNode name];
        }
    }
    
    [self.navigationItem setTitle:titleString];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:self.parentNode];
    
    if ([self.nodeList.size integerValue] == 0) {
        [self showEmptyFolderView];
    }
    
    [self.tableView reloadData];
}

- (void)showEmptyFolderView {
    
    [self.searchDisplayController.searchBar setHidden:YES];
    
    EmptyView *emptyView = [[[NSBundle mainBundle] loadNibNamed:@"EmptyView"  owner:self options: nil] firstObject];
    [emptyView.emptyImageView setImage:[UIImage imageNamed:@"emptyFolder"]];
    [emptyView.emptyLabel setText:NSLocalizedString(@"emptyFolder", @"Empty Folder")];
    
    [self.tableView setBounces:NO];
    [self.tableView setScrollEnabled:NO];
    [self.tableView setBackgroundView:emptyView];
    
    [self.importBarButtonItem setEnabled:NO];
    [self.downloadBarButtonItem setEnabled:NO];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    matchSearchNodes = [NSMutableArray new];
    MEGANodeList *allNodeList = nil;
    
    if([scope isEqualToString:@"Recursive"]) {
        allNodeList = [[MEGASdkManager sharedMEGASdkFolder] nodeListSearchForNode:self.parentNode searchString:searchText recursive:YES];
    } else {
        allNodeList = [[MEGASdkManager sharedMEGASdkFolder] nodeListSearchForNode:self.parentNode searchString:searchText recursive:NO];
    }
    
    for (NSInteger i = 0; i < [allNodeList.size integerValue]; i++) {
        MEGANode *n = [allNodeList nodeAtIndex:i];
        [matchSearchNodes addObject:n];
    }
}

#pragma mark - IBActions
- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [[MEGASdkManager sharedMEGASdkFolder] logout];
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
    } else {
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
    }
}

- (IBAction)downloadFolderTouchUpInside:(UIBarButtonItem *)sender {
    
    NSNumber *folderSizeNumber = [[MEGASdkManager sharedMEGASdkFolder] sizeForNode:self.parentNode];
    NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
    
    if ([freeSizeNumber longLongValue] < [folderSizeNumber longLongValue]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"folderTooBig", @"You need more free space")
                                                            message:NSLocalizedString(@"folderTooBigMessage", @"The file you are trying to download is bigger than the avaliable memory.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
        [mainTBC setSelectedIndex:1]; //0 = Cloud, 1 = Offline, 2 = Contacts, 3 = Settings
        
        NSString *folderName = [[[MEGASdkManager sharedMEGASdkFolder] nameToLocal:[self.parentNode name]] stringByAppendingString:@"/"];
        NSString *offlinePath = [Helper pathForOffline];
        NSString *folderPath = [offlinePath stringByAppendingString:folderName];
        
        BOOL folderExists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath];
        if (!folderExists) {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error != nil) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"folderCreationError", (@"The folder '@%' can't be created", folderName))];
                NSLog(@"FolderLinkVC > downloadFolderTouchUpInside: %@", error);
            } else {
                [Helper downloadNodesOnFolder:folderPath parentNode:self.parentNode];
            }
            
        } else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"folderAlreadyExist", @"The folder you want to download already exists on Offline")];
        }
        
    } else {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [loginVC setLoginOption:[(UIButton *)sender tag]];
        [loginVC setNode:self.parentNode];
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

- (IBAction)importFolderTouchUpInside:(UIBarButtonItem *)sender {
    //TODO: Import folder
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"importFolderAction", @"Import folder")
                                                        message:NSLocalizedString(@"importFolderActionMessage", @"This function is not available. For the moment you can't import a folder.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
    return;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [matchSearchNodes count];
    } else {
        return [[self.nodeList size] integerValue];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
    }
    
    MEGANode *node = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodeList nodeAtIndex:indexPath.row];
    }
    
    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
    
    if (!fileExists && [node hasThumbnail]) {
        [[MEGASdkManager sharedMEGASdkFolder] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:self];
    }
    
    if (!fileExists) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    } else {
        [cell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
    }
    
    cell.nameLabel.text = [node name];
    
    if ([node type] == MEGANodeTypeFile) {
        struct tm *timeinfo;
        char buffer[80];
        
        time_t rawtime = [[node modificationTime] timeIntervalSince1970];
        timeinfo = localtime(&rawtime);
        
        strftime(buffer, 80, "%d/%m/%y %H:%M", timeinfo);
        
        NSString *date = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        NSString *size = [NSByteCountFormatter stringFromByteCount:node.size.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory];
        NSString *sizeAndDate = [NSString stringWithFormat:@"%@ • %@", size, date];
        
        cell.infoLabel.text = sizeAndDate;
    } else {
        NSInteger files = [[MEGASdkManager sharedMEGASdkFolder] numberChildFilesForParent:node];
        NSInteger folders = [[MEGASdkManager sharedMEGASdkFolder] numberChildFoldersForParent:node];
        
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
    }
    
    cell.nodeHandle = [node handle];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodeList nodeAtIndex:indexPath.row];
    }

    switch ([node type]) {
        case MEGANodeTypeFolder: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Links" bundle:nil];
            FolderLinkViewController *folderLinkVC = [storyboard instantiateViewControllerWithIdentifier:@"FolderLinkViewControllerID"];
            [folderLinkVC setParentNode:node];
            [folderLinkVC setIsFolderRootNode:NO];
            [self.navigationController pushViewController:folderLinkVC animated:YES];
            break;
        }

        case MEGANodeTypeFile: {
            NSString *name = [node name];
            if (isImage(name.lowercaseString.pathExtension)) {
                
                int offsetIndex = 0;
                self.cloudImages = [NSMutableArray new];
                
                if (tableView == self.searchDisplayController.searchResultsTableView) {
                    for (NSInteger i = 0; i < matchSearchNodes.count; i++) {
                        MEGANode *n = [matchSearchNodes objectAtIndex:i];
                        
                        if (isImage([n name].lowercaseString.pathExtension)) {
                            MEGAPreview *photo = [MEGAPreview photoWithNode:n];
                            photo.caption = [n name];
                            [self.cloudImages addObject:photo];
                            if ([n handle] == [node handle]) {
                                offsetIndex = (int)[self.cloudImages count] - 1;
                            }
                        }
                    }
                } else {
                    NSUInteger nodeListSize = [[self.nodeList size] integerValue];
                    for (NSInteger i = 0; i < nodeListSize; i++) {
                        MEGANode *n = [self.nodeList nodeAtIndex:i];
                        
                        if (isImage([n name].lowercaseString.pathExtension)) {
                            MEGAPreview *photo = [MEGAPreview photoWithNode:n];
                            photo.caption = [n name];
                            [self.cloudImages addObject:photo];
                            if ([n handle] == [node handle]) {
                                offsetIndex = (int)[self.cloudImages count] - 1;
                            }
                        }
                    }
                }
                
                MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
                
                browser.displayActionButton = YES;
                browser.displayNavArrows = YES;
                browser.displaySelectionButtons = NO;
                browser.zoomPhotosToFill = YES;
                browser.alwaysShowControls = NO;
                browser.enableGrid = YES;
                browser.startOnGrid = NO;
                
                // Optionally set the current visible photo before displaying
                //    [browser setCurrentPhotoIndex:1];
                
                [self.navigationController pushViewController:browser animated:YES];
                
                [browser showNextPhotoAnimated:YES];
                [browser showPreviousPhotoAnimated:YES];
                [browser setCurrentPhotoIndex:offsetIndex];
            }
            break;
        }
        
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodeList nodeAtIndex:indexPath.row];
    }
    
    DetailsNodeInfoViewController *nodeInfoDetailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
    [nodeInfoDetailsVC setNode:node];
    [self.navigationController pushViewController:nodeInfoDetailsVC animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    return YES;
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.cloudImages.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.cloudImages.count) {
        return [self.cloudImages objectAtIndex:index];
    }
    
    return nil;
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeFetchNodes: {
            [SVProgressHUD show];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    switch ([error type]) {
        case MEGAErrorTypeApiEArgs:
            if ([request type] == MEGARequestTypeLogin) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"Error")
                                                                    message:NSLocalizedString(@"invalidFolderLink", @"Folder link invalid")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                          otherButtonTitles:nil];
                [alertView show];
                
                if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
                    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
                    
                    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
                } else {
                    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
                    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
                }
            }
            break;
            
        case MEGAErrorTypeApiEOverQuota:
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"quotaExceeded", @"Storage quota exceeded")];
            break;
            
        default:
            break;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [[MEGASdkManager sharedMEGASdkFolder] fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [self reloadUI];
            [self.importBarButtonItem setEnabled:YES];
            [self.downloadBarButtonItem setEnabled:YES];
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *ntvc in [self.tableView visibleCells]) {
                if ([request nodeHandle] == [ntvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [ntvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
            
            for (NodeTableViewCell *ntvc in [self.searchDisplayController.searchResultsTableView visibleCells]) {
                if ([request nodeHandle] == [ntvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [ntvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.tableView reloadData];
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
