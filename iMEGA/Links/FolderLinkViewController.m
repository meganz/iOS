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
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "Helper.h"

#import "FolderLinkViewController.h"
#import "NodeTableViewCell.h"
#import "MainTabBarController.h"
#import "MEGAPreview.h"
#import "MEGAReachabilityManager.h"
#import "DetailsNodeInfoViewController.h"
#import "UnavailableLinkView.h"
#import "LoginViewController.h"
#import "OfflineTableViewController.h"

@interface FolderLinkViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MWPhotoBrowserDelegate, MEGAGlobalDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    
    BOOL isFetchNodesDone;
    
    NSMutableArray *matchSearchNodes;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
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
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.tableView setTableHeaderView:self.searchDisplayController.searchBar];
    [self performSelector:@selector(hideSearchBar) withObject:nil afterDelay:0.0f];
    
    isFetchNodesDone = NO;
    
    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
        }
    }
    
    [self.navigationController.view setBackgroundColor:megaLightGray];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.navigationItem setTitle:AMLocalizedString(@"megaFolder", nil)];
    
    [self.importBarButtonItem setEnabled:NO];
    [self.importBarButtonItem setTitle:AMLocalizedString(@"browserVC_importButton", @"Import")];
    [self.downloadBarButtonItem setEnabled:NO];
    [self.downloadBarButtonItem setTitle:AMLocalizedString(@"downloadButton", @"Download")];
    
    if (self.isFolderRootNode) {
        [MEGASdkManager sharedMEGASdkFolder];
        [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:self.folderLinkString delegate:self];

        [self.navigationItem setRightBarButtonItem:self.cancelBarButtonItem];
    } else {
        [self reloadUI];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdkFolder] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGAGlobalDelegate:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)dealloc {
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private

- (void)reloadUI {
    if (!self.parentNode) {
        self.parentNode = [[MEGASdkManager sharedMEGASdkFolder] rootNode];
    }
    
    NSString *titleString = AMLocalizedString(@"megaFolder", @"MEGA Folder Link");
    if ([self.parentNode name] != nil) {
        if (self.isFolderRootNode) {
            titleString = [titleString stringByAppendingPathComponent:[self.parentNode name]];
        } else {
            titleString = [self.parentNode name];
        }
    }
    [self.navigationItem setTitle:titleString];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:self.parentNode];
    
    [self.tableView reloadData];
}

- (void)showUnavailableLinkView {
    [self disableUIItems];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:@"unavailableLink"]];
    [unavailableLinkView.titleLabel setText:AMLocalizedString(@"folderLinkUnavailableTitle", @"")];
    [unavailableLinkView.textView setText:AMLocalizedString(@"folderLinkUnavailableText", nil)];
    [unavailableLinkView.textView setFont:[UIFont fontWithName:kFont size:14.0]];
    [unavailableLinkView.textView setTextColor:megaDarkGray];
    
    [self.tableView setBackgroundView:unavailableLinkView];
}

- (void)disableUIItems {
    
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self.tableView setBounces:NO];
    [self.tableView setScrollEnabled:NO];
    
    [self.importBarButtonItem setEnabled:NO];
    [self.downloadBarButtonItem setEnabled:NO];
}

- (void)filterContentForSearchText:(NSString*)searchText {
    
    matchSearchNodes = [NSMutableArray new];
    MEGANodeList *allNodeList = nil;
    
    allNodeList = [[MEGASdkManager sharedMEGASdkFolder] nodeListSearchForNode:self.parentNode searchString:searchText recursive:YES];
    
    for (NSInteger i = 0; i < [allNodeList.size integerValue]; i++) {
        MEGANode *n = [allNodeList nodeAtIndex:i];
        [matchSearchNodes addObject:n];
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

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.downloadBarButtonItem setEnabled:boolValue];
}

- (void)hideSearchBar {
    [self.tableView setContentOffset:CGPointMake(0, 44)];
}

#pragma mark - IBActions
- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    [[MEGASdkManager sharedMEGASdkFolder] logout];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)downloadFolderTouchUpInside:(UIBarButtonItem *)sender {
    
    if (![Helper isFreeSpaceEnoughToDownloadNode:self.parentNode]) {
        return;
    }
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        [self dismissViewControllerAnimated:YES completion:^{
            MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            [Helper changeToViewController:[OfflineTableViewController class] onTabBarController:mainTBC];
            
            NSString *folderName = [[[self.parentNode base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[self.parentNode name]]];
            NSString *folderPath = [[Helper pathForOffline] stringByAppendingPathComponent:folderName];
            
            if ([Helper createOfflineFolder:folderName folderPath:folderPath]) {
                [Helper downloadNodesOnFolder:folderPath parentNode:self.parentNode folderLink:YES];
            }
        }];
    } else {
        LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [Helper setLinkNode:self.parentNode];
        [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
        
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

- (IBAction)importFolderTouchUpInside:(UIBarButtonItem *)sender {
    //TODO: Import folder
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"importFolderAction", @"Import folder")
                                                        message:AMLocalizedString(@"importFolderActionMessage", @"For the moment you can't import a folder.")
                                                       delegate:self
                                              cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    return;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            numberOfRows = [matchSearchNodes count];
        } else {
            numberOfRows = [[self.nodeList size] integerValue];
        }
    }
    
    if (numberOfRows == 0) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        } else {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        }
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
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
    
    if ([node type] == MEGANodeTypeFile) {
        if ([node hasThumbnail]) {
            NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            if (!thumbnailExists) {
                [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
                [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
            } else {
                [cell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
            }
        } else {
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
    } else if ([node type] == MEGANodeTypeFolder) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
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
        
        NSString *filesAndFolders = [self stringByFiles:files andFolders:folders];
        cell.infoLabel.text = filesAndFolders;
    }
    
    cell.nodeHandle = [node handle];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
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
            if (isImage(name.pathExtension)) {
                
                int offsetIndex = 0;
                self.cloudImages = [NSMutableArray new];
                
                if (tableView == self.searchDisplayController.searchResultsTableView) {
                    for (NSInteger i = 0; i < matchSearchNodes.count; i++) {
                        MEGANode *n = [matchSearchNodes objectAtIndex:i];
                        
                        if (isImage([n name].pathExtension)) {
                            MEGAPreview *megaPreview = [MEGAPreview photoWithNode:n];
                            megaPreview.isFromFolderLink = YES;
                            megaPreview.caption = [n name];
                            [self.cloudImages addObject:megaPreview];
                            if ([n handle] == [node handle]) {
                                offsetIndex = (int)[self.cloudImages count] - 1;
                            }
                        }
                    }
                } else {
                    NSUInteger nodeListSize = [[self.nodeList size] integerValue];
                    for (NSInteger i = 0; i < nodeListSize; i++) {
                        MEGANode *n = [self.nodeList nodeAtIndex:i];
                        
                        if (isImage([n name].pathExtension)) {
                            MEGAPreview *megaPreview = [MEGAPreview photoWithNode:n];
                            megaPreview.isFromFolderLink = YES;
                            megaPreview.caption = [n name];
                            [self.cloudImages addObject:megaPreview];
                            if ([n handle] == [node handle]) {
                                offsetIndex = (int)[self.cloudImages count] - 1;
                            }
                        }
                    }
                }
                
                MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
                
                photoBrowser.displayActionButton = YES;
                photoBrowser.displayNavArrows = YES;
                photoBrowser.displaySelectionButtons = NO;
                photoBrowser.zoomPhotosToFill = YES;
                photoBrowser.alwaysShowControls = NO;
                photoBrowser.enableGrid = YES;
                photoBrowser.startOnGrid = NO;
                
                // Optionally set the current visible photo before displaying
                //    [browser setCurrentPhotoIndex:1];
                
                [self.navigationController pushViewController:photoBrowser animated:YES];
                
                [photoBrowser showNextPhotoAnimated:YES];
                [photoBrowser showPreviousPhotoAnimated:YES];
                [photoBrowser setCurrentPhotoIndex:offsetIndex];
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

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView insertSubview:self.searchDisplayController.searchBar aboveSubview:self.tableView];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
    
    return YES;
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode) {
            return nil;
        }
        
        if (self.isFolderRootNode) {
            text = AMLocalizedString(@"folderLinkEmptyState_title", @"Empty folder link");
        } else {
            text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaBlack};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode) {
            return nil;
        }
        
        if (self.isFolderRootNode) {
            text = AMLocalizedString(@"folderLinkEmptyState_text", @"Empty folder link");
        } else {
            text = AMLocalizedString(@"folderLinkEmptyState_textFolder", @"Empty child folder link.");
        }
    } else {
        text = @"";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:14.0],
                                 NSForegroundColorAttributeName:megaGray,
                                 NSParagraphStyleAttributeName:paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode) {
            return nil;
        }
        
        return [UIImage imageNamed:@"emptyFolder"];
    } else {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode) {
            return nil;
        }
    }
    
    return [UIColor whiteColor];
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
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEAccess) {
            if ([request type] == MEGARequestTypeFetchNodes) {
                [self showUnavailableLinkView];
                [SVProgressHUD dismiss];
            }
        }
        
        if ([error type] == MEGAErrorTypeApiEOverQuota) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"quotaExceeded", @"Storage quota exceeded")];
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            isFetchNodesDone = NO;
            [[MEGASdkManager sharedMEGASdkFolder] fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            isFetchNodesDone = YES;
            [self reloadUI];
//            [self.importBarButtonItem setEnabled:YES];
            [self.downloadBarButtonItem setEnabled:YES];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES];
            }
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
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

@end
