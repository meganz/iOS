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

#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MediaPlayer.h>

#import "SVProgressHUD.h"
#import "SSKeychain.h"
#import "MWPhotoBrowser.h"
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "MEGAPreview.h"
#import "MEGAReachabilityManager.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "Helper.h"

#import "FolderLinkViewController.h"
#import "NodeTableViewCell.h"
#import "MainTabBarController.h"
#import "DetailsNodeInfoViewController.h"
#import "UnavailableLinkView.h"
#import "LoginViewController.h"
#import "OfflineTableViewController.h"
#import "PreviewDocumentViewController.h"
#import "NSString+MNZCategory.h"

@interface FolderLinkViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MWPhotoBrowserDelegate, MEGAGlobalDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    
    BOOL isLoginDone;
    BOOL isFetchNodesDone;
    BOOL isFolderLinkNotValid;
    
    NSMutableArray *matchSearchNodes;
    
    NSString *previewDocumentPath;
    
    UIAlertView *decryptionAlertView;
}

@property (weak, nonatomic) UILabel *navigationBarLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@end

@implementation FolderLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.tableView setTableHeaderView:self.searchDisplayController.searchBar];
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchDisplayController.searchBar.frame))];
    [self.searchDisplayController.searchBar setUserInteractionEnabled:NO];
    [self.searchDisplayController.searchBar setHidden:YES];
    
    isLoginDone = NO;
    isFetchNodesDone = NO;
    
    _nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
        }
    }
    
    [self.navigationController.view setBackgroundColor:megaLightGray];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.navigationItem setTitle:AMLocalizedString(@"folderLink", nil)];
    
    [self.importBarButtonItem setEnabled:NO];
    [self.importBarButtonItem setTitle:AMLocalizedString(@"import", nil)];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)reloadUI {
    if (!self.parentNode) {
        self.parentNode = [[MEGASdkManager sharedMEGASdkFolder] rootNode];
    }
    
    if ([self.parentNode name] != nil && !isFolderLinkNotValid) {
        [self setNavigationBarTitleLabel];
        
        if (!self.isFolderRootNode) { //Enable and show search bar when you're on a child folder
            [self.searchDisplayController.searchBar setHidden:NO];
            [self.searchDisplayController.searchBar setUserInteractionEnabled:YES];
        }
    } else {
        [self.navigationItem setTitle:AMLocalizedString(@"folderLink", nil)];
    }
    
    self.nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:self.parentNode];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarTitleLabel {
    NSString *title = [self.parentNode name];
    NSMutableAttributedString *titleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:title];
    [titleMutableAttributedString addAttribute:NSFontAttributeName
                                         value:[UIFont fontWithName:kFont size:18.0]
                                         range:[title rangeOfString:title]];
    
    NSString *subtitle = [NSString stringWithFormat:@"\n(%@)", AMLocalizedString(@"folderLink", nil)];
    NSMutableAttributedString *subtitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:subtitle];
    [subtitleMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                            value:megaRed
                                            range:[subtitle rangeOfString:subtitle]];
    [subtitleMutableAttributedString addAttribute:NSFontAttributeName
                                            value:[UIFont fontWithName:kFont size:12.0]
                                            range:[subtitle rangeOfString:subtitle]];
    
    [titleMutableAttributedString appendAttributedString:subtitleMutableAttributedString];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44)];
    [label setNumberOfLines:2];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setAttributedText:titleMutableAttributedString];
    _navigationBarLabel = label;
    [self.navigationItem setTitleView:label];
}

- (void)showUnavailableLinkView {
    [SVProgressHUD dismiss];
    
    [self disableUIItems];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:@"invalidFolderLink"]];
    [unavailableLinkView.titleLabel setText:AMLocalizedString(@"linkUnavailable", nil)];
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

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.downloadBarButtonItem setEnabled:boolValue];
}

- (void)deleteTempDocuments {
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    for (NSString *item in directoryContents) {
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([item pathExtension]), NULL);
        if ([QLPreviewController canPreviewItem:[NSURL URLWithString:(__bridge NSString *)(fileUTI)]] || UTTypeConformsTo(fileUTI, kUTTypeText)) {
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:item] error:&error];
            if (!success || error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove temp document error: %@", error]];
            }
        }
        if (fileUTI) {
            CFRelease(fileUTI);
        }
    }
}

- (void)showLinkNotValid {
    isFolderLinkNotValid = YES;
    
    [SVProgressHUD dismiss];
    [self.tableView reloadData];
}

- (void)showDecryptionAlert {
    if (decryptionAlertView == nil) {
        decryptionAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", nil)
                                                         message:AMLocalizedString(@"decryptionKeyAlertMessage", nil)
                                                        delegate:self
                                               cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                               otherButtonTitles:AMLocalizedString(@"decrypt", nil), nil];
    }
    
    [decryptionAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *textField = [decryptionAlertView textFieldAtIndex:0];
    [textField setPlaceholder:AMLocalizedString(@"decryptionKey", nil)];
    [decryptionAlertView setTag:1];
    [decryptionAlertView show];
}

- (void)showDecryptionKeyNotValidAlert {
    UIAlertView *decryptionKeyNotValidAlertView  = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"decryptionKeyNotValid", nil)
                                                                              message:nil
                                                                             delegate:self
                                                                    cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                                    otherButtonTitles:nil];
    [decryptionKeyNotValidAlertView setTag:2];
    [decryptionKeyNotValidAlertView show];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [self deleteTempDocuments];
    
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    
    if ([[MEGASdkManager sharedMEGASdkFolder] isLoggedIn]) {
        [[MEGASdkManager sharedMEGASdkFolder] logout];
    }
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)downloadFolderTouchUpInside:(UIBarButtonItem *)sender {
    //TODO: If documents have been opened for preview and the user download the folder link after that, move the dowloaded documents to Offline and avoid re-downloading.
    [self deleteTempDocuments];
    
    if (![Helper isFreeSpaceEnoughToDownloadNode:self.parentNode isFolderLink:YES]) {
        [self setEditing:NO animated:YES];
        return;
    }
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [self dismissViewControllerAnimated:YES completion:^{
            MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            [Helper changeToViewController:[OfflineTableViewController class] onTabBarController:mainTBC];
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
            [Helper downloadNode:self.parentNode folderPath:[Helper pathForOffline] isFolderLink:YES];
        }];
    } else {
        LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [Helper setLinkNode:self.parentNode];
        [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
        
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

- (IBAction)importFolderTouchUpInside:(UIBarButtonItem *)sender {
    [self deleteTempDocuments];
    
    //TODO: Import folder
    return;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) { //Decryption key
        if (buttonIndex == 0) {
            if ([[MEGASdkManager sharedMEGASdkFolder] isLoggedIn]) {
                [[MEGASdkManager sharedMEGASdkFolder] logout];
            }
            
            [[decryptionAlertView textFieldAtIndex:0] resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else if (buttonIndex == 1) {
            NSString *linkString = [self.folderLinkString stringByAppendingString:@"!"];
            NSString *key = [[alertView textFieldAtIndex:0] text];
            linkString = [linkString stringByAppendingString:key];
            
            [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:linkString delegate:self];
        }
    } else if (alertView.tag == 2) { //Decryption key not valid
        [self showDecryptionAlert];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 1) {
        NSString *decryptionKey = [[alertView textFieldAtIndex:0] text];
        if ([decryptionKey isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
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
            if (isFolderLinkNotValid) {
                numberOfRows = 0;
            } else {
                numberOfRows = [[self.nodeList size] integerValue];
            }
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
    MEGANode *node = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodeList nodeAtIndex:indexPath.row];
    }
    
    [self.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
    
    NodeTableViewCell *cell;
    if ([[Helper downloadingNodes] objectForKey:node.base64Handle] != nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"downloadingNodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"downloadingNodeCell"];
        }
        
        [cell.downloadingArrowImageView setImage:[UIImage imageNamed:@"downloadQueued"]];
        [cell.infoLabel setText:AMLocalizedString(@"queued", @"Queued")];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
        }
    }
    
    if ([node type] == MEGANodeTypeFile) {
        if ([node hasThumbnail]) {
            NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
            BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
            if (!thumbnailExists) {
                [[MEGASdkManager sharedMEGASdkFolder] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:self];
                [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
            } else {
                [cell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
            }
        } else {
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
        
        struct tm *timeinfo;
        char buffer[80];
        
        time_t rawtime = [[node modificationTime] timeIntervalSince1970];
        timeinfo = localtime(&rawtime);
        
        strftime(buffer, 80, "%d/%m/%y %H:%M", timeinfo);
        
        NSString *date = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        NSString *size = [NSByteCountFormatter stringFromByteCount:node.size.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory];
        NSString *sizeAndDate = [NSString stringWithFormat:@"%@ • %@", size, date];
        
        cell.infoLabel.text = sizeAndDate;
        
    } else if ([node type] == MEGANodeTypeFolder) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        
        NSInteger files = [[MEGASdkManager sharedMEGASdkFolder] numberChildFilesForParent:node];
        NSInteger folders = [[MEGASdkManager sharedMEGASdkFolder] numberChildFoldersForParent:node];
        
        NSString *filesAndFolders = [@"" stringByFiles:files andFolders:folders];
        cell.infoLabel.text = filesAndFolders;
    }
    
    [cell.thumbnailImageView.layer setCornerRadius:4];
    [cell.thumbnailImageView.layer setMasksToBounds:YES];
    
    cell.nameLabel.text = [node name];
    
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
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([name pathExtension]), NULL);
            if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                
                int offsetIndex = 0;
                self.cloudImages = [NSMutableArray new];
                
                if (tableView == self.searchDisplayController.searchResultsTableView) {
                    for (NSInteger i = 0; i < matchSearchNodes.count; i++) {
                        MEGANode *n = [matchSearchNodes objectAtIndex:i];
                        
                        if (fileUTI) {
                            CFRelease(fileUTI);
                        }
                        
                        fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([n.name pathExtension]), NULL);
                        
                        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
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
                        
                        if (fileUTI) {
                            CFRelease(fileUTI);
                        }
                        
                        fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([n.name pathExtension]), NULL);
                        
                        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
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
            } else {
                MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:node]];
                
                if (offlineNodeExist) {
                    previewDocumentPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
                    
                    QLPreviewController *previewController = [[QLPreviewController alloc] init];
                    [previewController setDelegate:self];
                    [previewController setDataSource:self];
                    [previewController setTransitioningDelegate:self];
                    [previewController setTitle:name];
                    [self presentViewController:previewController animated:YES completion:nil];
                } else if (UTTypeConformsTo(fileUTI, kUTTypeAudiovisualContent) && [[MEGASdkManager sharedMEGASdk] httpServerStart:YES port:4443]) {
                    NSURL *link = [[MEGASdkManager sharedMEGASdk] httpServerGetLocalLink:node];
                    if (link) {
                        MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:link];
                        // Remove the movie player view controller from the "playback did finish" notification observers
                        [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController
                                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                                      object:moviePlayerViewController.moviePlayer];
                        
                        // Register this class as an observer instead
                        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                 selector:@selector(movieFinishedCallback:)
                                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                                   object:moviePlayerViewController.moviePlayer];
                        
                        [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController name:UIApplicationDidEnterBackgroundNotification object:nil];
                        
                        [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
                        
                        [moviePlayerViewController.moviePlayer prepareToPlay];
                        [moviePlayerViewController.moviePlayer play];
                        
                        if (fileUTI) {
                            CFRelease(fileUTI);
                        }
                        
                        return;
                    }
                } else {
                    if ([[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] > 0) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"documentOpening_alertTitle", nil)
                                                                            message:AMLocalizedString(@"documentOpening_alertMessage", nil)
                                                                           delegate:nil
                                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                                  otherButtonTitles:nil, nil];
                        [alertView show];
                    } else {
                        // There isn't enough space in the device for preview the document
                        if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                            if (fileUTI) {
                                CFRelease(fileUTI);
                            }
                            return;
                        }
                        
                        PreviewDocumentViewController *previewDocumentVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentID"];
                        [previewDocumentVC setNode:node];
                        [previewDocumentVC setApi:[MEGASdkManager sharedMEGASdkFolder]];
                        
                        [self.navigationController pushViewController:previewDocumentVC animated:YES];
                        
                        [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                }
            }
            
            if (fileUTI) {
                CFRelease(fileUTI);
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

#pragma mark - UISearchDisplayDelegate

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

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    if ([presented isKindOfClass:[QLPreviewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    
    return nil;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (previewDocumentPath != nil) {
        return [NSURL fileURLWithPath:previewDocumentPath];
    }
    
    return nil;
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode) {
            if (isFolderLinkNotValid) {
                text = AMLocalizedString(@"linkNotValid", nil);
            } else {
                text = @"";
            }
        } else {
            if (self.isFolderRootNode) {
                text = AMLocalizedString(@"folderLinkEmptyState_title", @"Empty folder link");
            } else {
                text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
            }
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
            text = @"";
        } else {
            if (self.isFolderRootNode) {
                text = AMLocalizedString(@"folderLinkEmptyState_text", @"Empty folder link");
            } else {
                text = AMLocalizedString(@"folderLinkEmptyState_textFolder", @"Empty child folder link.");
            }
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
            if (isFolderLinkNotValid) {
                return [UIImage imageNamed:@"invalidFolderLink"];
            }
            return nil;
        }
        
        return [UIImage imageNamed:@"emptyFolder"];
    } else {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode && !isFolderLinkNotValid) {
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


#pragma mark - Movie player

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    MPMoviePlayerController *moviePlayer = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:moviePlayer];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[MEGASdkManager sharedMEGASdk] httpServerStop];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.nodesIndexPathMutableDictionary removeAllObjects];
    [self reloadUI];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            isFolderLinkNotValid = NO;
            break;
        }
            
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
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs: {
                if ([request type] == MEGARequestTypeLogin) {
                    if (decryptionAlertView.visible) { //If the user have written the key
                        [self showDecryptionKeyNotValidAlert];
                    } else {
                        [self showLinkNotValid];
                    }
                } else if ([request type] == MEGARequestTypeFetchNodes) {
                    [self showUnavailableLinkView];
                }
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                if ([request type] == MEGARequestTypeFetchNodes) {
                    [self showLinkNotValid];
                }
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                [self showDecryptionAlert];
                break;
            }
                
            default: {
                if ([request type] == MEGARequestTypeLogin) {
                    [self showUnavailableLinkView];
                } else if ([request type] == MEGARequestTypeFetchNodes) {
                    [[MEGASdkManager sharedMEGASdkFolder] logout];
                    [self showUnavailableLinkView];
                }
                break;
            }
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            isLoginDone = YES;
            isFetchNodesDone = NO;
            [[MEGASdkManager sharedMEGASdkFolder] fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            
            if ([request flag]) { //Invalid key
                [[MEGASdkManager sharedMEGASdkFolder] logout];
                
                [SVProgressHUD dismiss];
                
                if (decryptionAlertView.visible) { //Link without key, after entering a bad one
                    [self showDecryptionKeyNotValidAlert];
                } else { //Link with invalid key
                    [self showLinkNotValid];
                }
                return;
            }
            
            isFetchNodesDone = YES;
            [self reloadUI];
            [self.searchDisplayController.searchBar setUserInteractionEnabled:YES];
            [self.searchDisplayController.searchBar setHidden:NO];
            
//            [self.importBarButtonItem setEnabled:YES];
            [self.downloadBarButtonItem setEnabled:YES];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES];
            }
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeLogout: {
            isLoginDone = NO;
            isFetchNodesDone = NO;
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *ntvc in [self.tableView visibleCells]) {
                if ([request nodeHandle] == [ntvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [ntvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
            
            for (NodeTableViewCell *ntvc in [self.searchDisplayController.searchResultsTableView visibleCells]) {
                if ([request nodeHandle] == [ntvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdkFolder] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
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

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
    
    if (transfer.type == MEGATransferTypeDownload && [[Helper downloadingNodes] objectForKey:base64Handle]) {
        float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
        NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            NodeTableViewCell *cell = (NodeTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.infoLabel setText:[NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed]];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
            NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
            NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
            if (indexPath != nil) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
