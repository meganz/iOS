/**
 * @file FolderLinkViewController.m
 * @brief View controller that allows to see and manage MEGA folder links.
 *
 * (c) 2013-2016 by Mega Limited, Auckland, New Zealand
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
#import "FileLinkViewController.h"
#import "NodeTableViewCell.h"
#import "MainTabBarController.h"
#import "DetailsNodeInfoViewController.h"
#import "UnavailableLinkView.h"
#import "LoginViewController.h"
#import "OfflineTableViewController.h"
#import "PreviewDocumentViewController.h"
#import "MEGAAVViewController.h"
#import "MEGANavigationController.h"
#import "BrowserViewController.h"

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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;

@property (nonatomic, strong) NSMutableArray *cloudImages;
@property (nonatomic, strong) NSMutableArray *selectedNodesArray;
@property (nonatomic, getter=areAllNodesSelected) BOOL allNodesSelected;

@end

@implementation FolderLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.searchDisplayController.searchResultsTableView.emptyDataSetSource = self;
    self.searchDisplayController.searchResultsTableView.emptyDataSetDelegate = self;
    self.searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
    [self.searchDisplayController setValue:@"" forKey:@"_noResultsMessage"];
    
    isLoginDone = NO;
    isFetchNodesDone = NO;
    
    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path: %@", error);
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path: %@", error);
        }
    }
    
    [self.navigationController.view setBackgroundColor:[UIColor mnz_grayF9F9F9]];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.navigationItem setTitle:AMLocalizedString(@"folderLink", nil)];
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || iPhone6Plus) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    [self.navigationItem setRightBarButtonItems:@[negativeSpaceBarButtonItem, self.editBarButtonItem] animated:YES];
    
    [self.importBarButtonItem setTitle:AMLocalizedString(@"import", nil)];
    [self.downloadBarButtonItem setTitle:AMLocalizedString(@"downloadButton", @"Download")];
    
    if (self.isFolderRootNode) {
        [MEGASdkManager sharedMEGASdkFolder];
        [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:self.folderLinkString delegate:self];

        [self.navigationItem setLeftBarButtonItem:_cancelBarButtonItem];
        
        [_downloadBarButtonItem setEnabled:NO];
        [_importBarButtonItem setEnabled:NO];
    } else {
        [self reloadUI];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdkFolder] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGARequestDelegate:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
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
    } else {
        [self.navigationItem setTitle:AMLocalizedString(@"folderLink", nil)];
    }
    
    self.nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:self.parentNode];
    if ([[_nodeList size] unsignedIntegerValue] == 0) {
        [self setActionButtonsEnabled:NO];
    } else {
        [self setActionButtonsEnabled:YES];
    }
    
    [self.tableView reloadData];
    
    if ([[self.nodeList size] unsignedIntegerValue] == 0) {
        [_tableView setTableHeaderView:nil];
        [_tableView setContentOffset:CGPointZero];
    } else {
        [_tableView setTableHeaderView:self.searchDisplayController.searchBar];
        [_tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchDisplayController.searchBar.frame))];
    }
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
                                            value:[UIColor mnz_redD90007]
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
    [unavailableLinkView.textView setTextColor:[UIColor mnz_gray666666]];
    
    if (iPhone4X) {
        [unavailableLinkView.imageViewCenterYLayoutConstraint setConstant:-64];
    }
    
    [self.tableView setBackgroundView:unavailableLinkView];
}

- (void)disableUIItems {
    
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self.tableView setBounces:NO];
    [self.tableView setScrollEnabled:NO];
    
    [self setActionButtonsEnabled:NO];
}

- (void)setActionButtonsEnabled:(BOOL)boolValue {
    [_editBarButtonItem setEnabled:boolValue];
    
    [_importBarButtonItem setEnabled:boolValue];
    [_downloadBarButtonItem setEnabled:boolValue];
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
            if (![[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:item] error:&error]) {
                MEGALogError(@"Remove item at path: %@", error);
            }
        }
        if (fileUTI) {
            CFRelease(fileUTI);
        }
    }
}

- (void)showLinkNotValid {
    isFolderLinkNotValid = YES;
    
    [self disableUIItems];
    
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

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self deleteTempDocuments];
    
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    
    [[MEGASdkManager sharedMEGASdkFolder] logout];
    
    [SVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editAction:(UIBarButtonItem *)sender {
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"edit"]];
    [self setEditing:value animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [_tableView setEditing:editing animated:YES];
    
    [_downloadBarButtonItem setEnabled:!editing];
    [_importBarButtonItem setEnabled:!editing];
    
    if (editing) {
        [_editBarButtonItem setImage:[UIImage imageNamed:@"done"]];

        [self.navigationItem setLeftBarButtonItem:_selectAllBarButtonItem];
    } else {
        [_editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        [self setAllNodesSelected:NO];
        _selectedNodesArray = nil;

        if (self.isFolderRootNode) {
            [self.navigationItem setLeftBarButtonItem:_cancelBarButtonItem];
        } else {
            [self.navigationItem setLeftBarButtonItem:nil];
        }
    }
    
    if (!_selectedNodesArray) {
        _selectedNodesArray = [NSMutableArray new];
    }
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [_selectedNodesArray removeAllObjects];
    
    if (![self areAllNodesSelected]) {
        MEGANode *node = nil;
        NSInteger nodeListSize = [[_nodeList size] integerValue];
        for (NSInteger i = 0; i < nodeListSize; i++) {
            node = [_nodeList nodeAtIndex:i];
            [_selectedNodesArray addObject:node];
        }
        
        [self setAllNodesSelected:YES];
    } else {
        [self setAllNodesSelected:NO];
    }
    
    if (self.selectedNodesArray.count == 0) {
        [_downloadBarButtonItem setEnabled:NO];
        [_importBarButtonItem setEnabled:NO];
    } else if (self.selectedNodesArray.count >= 1) {
        [_downloadBarButtonItem setEnabled:YES];
        [_importBarButtonItem setEnabled:YES];
    }
    
    [_tableView reloadData];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition;
    NSIndexPath *indexPath;
    MEGANode *node = nil;
    if ([self.searchDisplayController isActive]) {
        buttonPosition = [sender convertPoint:CGPointZero toView:self.searchDisplayController.searchResultsTableView];
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:buttonPosition];
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
        indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
        node = [_nodeList nodeAtIndex:indexPath.row];
    }
    
    FileLinkViewController *fileLinkVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FileLinkViewControllerID"];
    [fileLinkVC setFileLinkMode:FileLinkModeNodeFromFolderLink];
    [fileLinkVC setNodeFromFolderLink:node];
    [self.navigationController pushViewController:fileLinkVC animated:YES];
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    //TODO: If documents have been opened for preview and the user download the folder link after that, move the dowloaded documents to Offline and avoid re-downloading.
    [self deleteTempDocuments];
    
    if ([_tableView isEditing]) {
        for (MEGANode *node in _selectedNodesArray) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                [self setEditing:NO animated:YES];
                return;
            }
        }
    } else {
        if (![Helper isFreeSpaceEnoughToDownloadNode:_parentNode isFolderLink:YES]) {
            return;
        }
    }
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [self dismissViewControllerAnimated:YES completion:^{
            if ([[[[[UIApplication sharedApplication] delegate] window] rootViewController] isKindOfClass:[MainTabBarController class]]) {
                [Helper changeToViewController:[OfflineTableViewController class] onTabBarController:(MainTabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController]];
            }
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
            
            if ([_tableView isEditing]) {
                for (MEGANode *node in _selectedNodesArray) {
                    [Helper downloadNode:node folderPath:[Helper pathForOffline] isFolderLink:YES];
                }
            } else {
                [Helper downloadNode:_parentNode folderPath:[Helper pathForOffline] isFolderLink:YES];
            }
        }];
    } else {
        if ([_tableView isEditing]) {
            [[Helper nodesFromLinkMutableArray] addObjectsFromArray:_selectedNodesArray];
        } else {
            [[Helper nodesFromLinkMutableArray] addObject:_parentNode];
        }
        [Helper setSelectedOptionOnLink:4]; //Download folder or nodes from link
        
        LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        [self.navigationController pushViewController:loginVC animated:YES];
    }
    
    //TODO: Make a logout in sharedMEGASdkFolder after download the link or the selected nodes.
}

- (IBAction)importAction:(UIBarButtonItem *)sender {
    [self deleteTempDocuments];
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [self dismissViewControllerAnimated:YES completion:^{
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
            if ([_tableView isEditing]) {
                browserVC.selectedNodesArray = [NSArray arrayWithArray:_selectedNodesArray];
            } else {
                if (self.parentNode == nil) {
                    self.parentNode = [[MEGASdkManager sharedMEGASdkFolder] rootNode];
                }
                browserVC.selectedNodesArray = [NSArray arrayWithObject:_parentNode];
            }
            
            [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:navigationController animated:YES completion:nil];
        }];
    } else {
        if ([_tableView isEditing]) {
            [[Helper nodesFromLinkMutableArray] addObjectsFromArray:_selectedNodesArray];
        } else {
            [[Helper nodesFromLinkMutableArray] addObject:_parentNode];
        }
        [Helper setSelectedOptionOnLink:3]; //Import folder or nodes from link
        
        LoginViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        [self.navigationController pushViewController:loginVC animated:YES];
    }
    
    return;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) { //Decryption key
        if (buttonIndex == 0) {
            [[MEGASdkManager sharedMEGASdkFolder] logout];
            
            [[decryptionAlertView textFieldAtIndex:0] resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else if (buttonIndex == 1) {
            NSString *linkString;
            NSString *key = [[alertView textFieldAtIndex:0] text];
            if ([[key substringToIndex:1] isEqualToString:@"!"]) {
                linkString = self.folderLinkString;
            } else {
                linkString = [self.folderLinkString stringByAppendingString:@"!"];
            }
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
            [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        } else {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        }
    } else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        }
        
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
    
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
    }
    
    if ([node type] == MEGANodeTypeFile) {
        if ([node hasThumbnail]) {
            [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdkFolder] cell:cell];
        } else {
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
        
        cell.infoLabel.text = [Helper sizeAndDateForNode:node api:[MEGASdkManager sharedMEGASdkFolder]];
        
    } else if ([node type] == MEGANodeTypeFolder) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        
        cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdkFolder]];
    }
    
    [cell.thumbnailImageView.layer setCornerRadius:4];
    [cell.thumbnailImageView.layer setMasksToBounds:YES];
    
    cell.nameLabel.text = [node name];
    
    cell.nodeHandle = [node handle];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    if (tableView.isEditing) {
        for (MEGANode *n in _selectedNodesArray) {
            if ([n handle] == [node handle]) {
                [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
        [self.searchDisplayController setActive:NO animated:YES];
    } else {
        node = [self.nodeList nodeAtIndex:indexPath.row];
    }
    
    if (tableView.isEditing) {
        [_selectedNodesArray addObject:node];
        
        [_downloadBarButtonItem setEnabled:YES];
        [_importBarButtonItem setEnabled:YES];
        
        if ([_selectedNodesArray count] == [_nodeList.size integerValue]) {
            [self setAllNodesSelected:YES];
        } else {
            [self setAllNodesSelected:NO];
        }
        
        return;
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
                } else if (UTTypeConformsTo(fileUTI, kUTTypeAudiovisualContent) && [[MEGASdkManager sharedMEGASdkFolder] httpServerStart:YES port:4443]) {
                    MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithNode:node folderLink:YES];
                    [self presentViewController:megaAVViewController animated:YES completion:nil];

                    if (fileUTI) {
                        CFRelease(fileUTI);
                    }                    
                    return;
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [_nodeList nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        NSMutableArray *tempArray = [_selectedNodesArray copy];
        for (MEGANode *n in tempArray) {
            if (n.handle == node.handle) {
                [_selectedNodesArray removeObject:n];
            }
        }
        
        if (_selectedNodesArray.count == 0) {
            [_downloadBarButtonItem setEnabled:NO];
            [_importBarButtonItem setEnabled:NO];
        } else if (self.selectedNodesArray.count < 1) {
            [_downloadBarButtonItem setEnabled:YES];
            [_importBarButtonItem setEnabled:YES];
        }
        
        [self setAllNodesSelected:NO];
        
        return;
    }
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
    [self.searchDisplayController setActive:NO animated:YES];
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
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (!isFetchNodesDone && self.isFolderRootNode) {
            if (isFolderLinkNotValid) {
                text = AMLocalizedString(@"linkNotValid", nil);
            } else {
                text = @"";
            }
        } else {
            if ([self.searchDisplayController isActive]) {
                text = AMLocalizedString(@"noResults", nil);
            } else {
                text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
            }
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
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
        
         if ([self.searchDisplayController isActive]) {
             return [UIImage imageNamed:@"emptySearch"];
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

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    if ([self.searchDisplayController isActive]) {
        return -66.0;
    }
    
    return 0.0f;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return 40.0f;
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
                    [api logout];
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
            [api fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            
            if ([request flag]) { //Invalid key
                [api logout];
                
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
            
            [_importBarButtonItem setEnabled:YES];
            [_downloadBarButtonItem setEnabled:YES];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [api pauseTransfers:YES];
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
            UITableView *tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
            for (NodeTableViewCell *nodeTableViewCell in [tableView visibleCells]) {
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

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

@end
