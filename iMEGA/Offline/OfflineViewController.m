#import "OfflineViewController.h"

#import "SVProgressHUD.h"

#import "UIScrollView+EmptyDataSet.h"
#import "NSString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "MEGANavigationController.h"
#import "MEGASdkManager.h"
#import "PreviewDocumentViewController.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "OpenInActivity.h"
#import "SortByTableViewController.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "MEGAAVViewController.h"
#import "MEGAQLPreviewController.h"
#import "OfflineTableViewViewController.h"
#import "OfflineCollectionViewController.h"
#import "LayoutView.h"
#import "NodeCollectionViewCell.h"
#import "OfflineTableViewCell.h"
#import "UIViewController+MNZCategory.h"

static NSString *kFileName = @"kFileName";
static NSString *kIndex = @"kIndex";
static NSString *kPath = @"kPath";
static NSString *kModificationDate = @"kModificationDate";
static NSString *kFileSize = @"kFileSize";
static NSString *kisDirectory = @"kisDirectory";

@interface OfflineViewController () <UIViewControllerTransitioningDelegate, UIDocumentInteractionControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGATransferDelegate, UISearchControllerDelegate> {
}

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sortByBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *activityBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (nonatomic, strong) NSMutableArray *offlineMultimediaFiles;
@property (nonatomic, strong) NSMutableArray *offlineItems;
@property (nonatomic, strong) NSMutableArray *offlineFiles;
@property (nonatomic, strong) NSString *folderPathFromOffline;

@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@property (nonatomic, strong) OfflineTableViewViewController *offlineTableView;
@property (nonatomic, strong) OfflineCollectionViewController *offlineCollectionView;
@property (nonatomic, assign) LayoutMode layoutView;

@end

@implementation OfflineViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self determineLayoutView];
    
    if (self.folderPathFromOffline == nil) {
        [self.navigationItem setTitle:AMLocalizedString(@"offline", @"Offline")];
    } else {
        [self.navigationItem setTitle:self.folderPathFromOffline.lastPathComponent];
    }
    
    self.navigationItem.rightBarButtonItem = self.moreBarButtonItem;
    
    self.definesPresentationContext = YES;
    
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    self.searchController.delegate = self;
    
    self.moreBarButtonItem.accessibilityLabel = AMLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    if (@available(iOS 13.0, *)) {
        [self configPreviewingRegistration];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    // If the user has activated the logs, then they are imported to the offline section from the shared sandbox:
    if ([[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] boolForKey:@"logging"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionLogsFolder] path];
        if ([fileManager fileExistsAtPath:logsPath]) {
            NSString *documentProviderLog = @"MEGAiOS.docExt.log";
            NSString *fileProviderLog = @"MEGAiOS.fileExt.log";
            NSString *shareExtensionLog = @"MEGAiOS.shareExt.log";
            [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:documentProviderLog]];
            [fileManager copyItemAtPath:[logsPath stringByAppendingPathComponent:documentProviderLog]  toPath:[[self currentOfflinePath] stringByAppendingPathComponent:documentProviderLog] error:nil];
            [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:fileProviderLog]];
            [fileManager copyItemAtPath:[logsPath stringByAppendingPathComponent:fileProviderLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:fileProviderLog] error:nil];
            [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:shareExtensionLog]];
            [fileManager copyItemAtPath:[logsPath stringByAppendingPathComponent:shareExtensionLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:shareExtensionLog] error:nil];
        }
    }
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
    
    if (self.offlineTableView.tableView.isEditing) {
        self.selectedItems = nil;
        [self setEditMode:NO];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.offlineTableView.tableView reloadEmptyDataSet];
        if (self.searchController.active) {
            if (UIDevice.currentDevice.iPad) {
                if (self != UIApplication.mnz_visibleViewController) {
                    [Helper resetSearchControllerFrame:self.searchController];
                }
            } else {
                [Helper resetSearchControllerFrame:self.searchController];
            }
        }
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self configPreviewingRegistration];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (UIDevice.currentDevice.iPhone4X || UIDevice.currentDevice.iPhone5X) {
            CGRect frame = [UIApplication sharedApplication].keyWindow.rootViewController.view.frame;
            if (frame.size.width > frame.size.height) {
                CGFloat oldWidth = frame.size.width;
                frame.size.width = frame.size.height;
                frame.size.height = oldWidth;
                [UIApplication sharedApplication].keyWindow.rootViewController.view.frame = frame;
            }
        }
    }];
}

#pragma mark - Layout


- (void)determineLayoutView {
    
    NSString *relativePath = [[self currentOfflinePath] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()]  withString:@""];
    MOOfflineFolderLayout *folderLayout = [[MEGAStore shareInstance] fetchOfflineFolderLayoutWithPath:relativePath];
    
    if (folderLayout) {
        switch (folderLayout.value.integerValue) {
            case 0:
                [self initTable];
                break;
                
            case 1:
                [self initCollection];
                break;
                
            default:
                [self initTable];
                break;
        }
    } else {
        NSInteger nodesWithThumbnail = 0;
        NSInteger nodesWithoutThumbnail = 0;
        
        NSString *directoryPathString = [self currentOfflinePath];
        NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPathString error:NULL];
        
        for (int i = 0; i < directoryContents.count; i++) {
            NSString *fileName = [directoryContents objectAtIndex:i];
            NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:fileName];
            
            MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
            NSString *handleString = offNode.base64Handle;
            
            BOOL isDirectory;
            [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
            if (isDirectory) {
                nodesWithoutThumbnail = nodesWithoutThumbnail + 1;
            } else {
                NSString *thumbnailFilePath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
                thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath] && handleString) {
                    nodesWithThumbnail = nodesWithThumbnail + 1;
                } else {
                    nodesWithoutThumbnail = nodesWithoutThumbnail + 1;
                }
            }
        }
        
        if (nodesWithThumbnail > nodesWithoutThumbnail) {
            [self initCollection];
        } else {
            [self initTable];
        }
    }
}


- (void)initTable {
    [self.offlineCollectionView willMoveToParentViewController:nil];
    [self.offlineCollectionView.view removeFromSuperview];
    [self.offlineCollectionView removeFromParentViewController];
    self.offlineCollectionView = nil;
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.layoutView = LayoutModeList;
    
    self.offlineTableView = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineTableID"];
    [self addChildViewController:self.offlineTableView];
    self.offlineTableView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.offlineTableView.view];
    [self.offlineTableView didMoveToParentViewController:self];
    
    self.offlineTableView.offline = self;
    self.offlineTableView.tableView.tableHeaderView = self.searchController.searchBar;
    self.offlineTableView.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame));
    self.offlineTableView.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.offlineTableView.tableView.emptyDataSetDelegate = self;
    self.offlineTableView.tableView.emptyDataSetSource = self;
}

- (void)initCollection {
    [self.offlineTableView willMoveToParentViewController:nil];
    [self.offlineTableView.view removeFromSuperview];
    [self.offlineTableView removeFromParentViewController];
    self.offlineTableView = nil;
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.layoutView = LayoutModeThumbnail;
    
    self.offlineCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineCollectionID"];
    self.offlineCollectionView.offline = self;
    [self addChildViewController:self.offlineCollectionView];
    self.offlineCollectionView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.offlineCollectionView.view];
    [self.offlineCollectionView didMoveToParentViewController:self];
    
    self.offlineCollectionView.collectionView.emptyDataSetDelegate = self;
    self.offlineCollectionView.collectionView.emptyDataSetSource = self;
}

- (void)changeLayoutMode {
    if (self.layoutView == LayoutModeList) {
        [self initCollection];
    } else  {
        [self initTable];
    }
    
    NSString *relativePath = [[self currentOfflinePath] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()]  withString:@""];
    [[MEGAStore shareInstance] insertOfflineFolderLayoutWithPOath:relativePath layout:self.layoutView];
}

#pragma mark - Private

- (void)reloadUI {
    self.offlineSortedItems = [[NSMutableArray alloc] init];
    self.offlineFiles = [[NSMutableArray alloc] init];
    self.offlineMultimediaFiles = [[NSMutableArray alloc] init];
    self.offlineItems = [[NSMutableArray alloc] init];
    
    NSString *directoryPathString = [self currentOfflinePath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPathString error:NULL];
    
    int offsetIndex = 0;
    for (int i = 0; i < (int)[directoryContents count]; i++) {
        NSString *filePath = [directoryPathString stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
        NSString *fileName = [NSString stringWithFormat:@"%@", [directoryContents objectAtIndex:i]];
        
        // Inbox folder in documents folder is created by the system. Don't show it
        if ([[[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"] isEqualToString:filePath]) {
            continue;
        }
        
        if (![fileName.lowercaseString.pathExtension isEqualToString:@"mega"]) {
            
            NSMutableDictionary *tempDictionary = [NSMutableDictionary new];
            [tempDictionary setValue:fileName forKey:kFileName];
            [tempDictionary setValue:[NSNumber numberWithInt:offsetIndex] forKey:kIndex];
            [tempDictionary setValue:[NSURL fileURLWithPath:filePath] forKey:kPath];
            
            NSDictionary *filePropertiesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            BOOL isDirectory;
            [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
            
            [tempDictionary setValue:[NSNumber numberWithBool:isDirectory] forKey:kisDirectory];
            
            [tempDictionary setValue:[filePropertiesDictionary objectForKey:NSFileSize] forKey:kFileSize];
            [tempDictionary setValue:[filePropertiesDictionary valueForKey:NSFileModificationDate] forKey:kModificationDate];
            
            [self.offlineItems addObject:tempDictionary];
            
            if (!isDirectory) {
                if (!fileName.mnz_isMultimediaPathExtension && !fileName.mnz_isWebCodePathExtension) {
                    offsetIndex++;
                }
            }
        }
    }
    
    //Sort configuration by default is "default ascending"
    if (![[NSUserDefaults standardUserDefaults] integerForKey:@"OfflineSortOrderType"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"OfflineSortOrderType"];
    }
    
    MEGASortOrderType sortOrderType = [[NSUserDefaults standardUserDefaults] integerForKey:@"OfflineSortOrderType"];
    [self sortBySortType:sortOrderType];
    
    offsetIndex = 0;
    for (NSDictionary *p in self.offlineItems) {
        NSURL *fileURL = [p objectForKey:kPath];
        NSString *fileName = [p objectForKey:kFileName];
        
        // Inbox folder in documents folder is created by the system. Don't show it
        if ([[[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"] isEqualToString:[fileURL path]]) {
            continue;
        }
        
        if (![fileName.lowercaseString.pathExtension isEqualToString:@"mega"]) {
            
            NSMutableDictionary *tempDictionary = [NSMutableDictionary new];
            [tempDictionary setValue:fileName forKey:kFileName];
            [tempDictionary setValue:[NSNumber numberWithInt:offsetIndex] forKey:kIndex];
            [tempDictionary setValue:fileURL forKey:kPath];
            
            NSDictionary *filePropertiesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:nil];
            BOOL isDirectory;
            [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
            
            [tempDictionary setValue:[NSNumber numberWithBool:isDirectory] forKey:kisDirectory];
            
            [tempDictionary setValue:[filePropertiesDictionary objectForKey:NSFileSize] forKey:kFileSize];
            [tempDictionary setValue:[filePropertiesDictionary valueForKey:NSFileModificationDate] forKey:kModificationDate];
            
            [self.offlineSortedItems addObject:tempDictionary];
            
            if (!isDirectory) {
                if (fileName.mnz_isMultimediaPathExtension) {
                    AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
                    if (asset.playable) {
                        [self.offlineMultimediaFiles addObject:[fileURL path]];
                    } else {
                        offsetIndex++;
                        [self.offlineFiles addObject:[fileURL path]];                        
                    }
                } else if (!fileName.mnz_isWebCodePathExtension) {
                    offsetIndex++;
                    [self.offlineFiles addObject:[fileURL path]];
                }
            }
        }
    }
    
    if ([self.offlineSortedItems count] == 0) {
        self.offlineTableView.tableView.tableHeaderView = nil;
    } else {
        if (!self.offlineTableView.tableView.tableHeaderView) {
            self.offlineTableView.tableView.tableHeaderView = self.searchController.searchBar;
        }
    }
    
    self.moreBarButtonItem.enabled = self.offlineSortedItems.count > 0;

    [self updateNavigationBarTitle];
    
    [self reloadData];
}

- (NSString *)folderPathFromOffline:(NSString *)absolutePath folder:(NSString *)folderName {
    
    NSArray *directoryPathComponents = [absolutePath pathComponents];
    NSUInteger directoryPathComponentsCount = directoryPathComponents.count;
    
    NSString *documentDirectory = [[Helper pathForOffline] lastPathComponent];
    NSUInteger documentsDirectoryPosition = 0;
    for (NSUInteger i = 0; i < directoryPathComponentsCount; i++) {
        NSString *folderString = [directoryPathComponents objectAtIndex:i];
        if ([folderString isEqualToString:documentDirectory]) {
            documentsDirectoryPosition = i;
            break;
        }
    }
    
    NSUInteger numberOfChildFolders = (directoryPathComponentsCount - (documentsDirectoryPosition + 1));
    NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange((documentsDirectoryPosition + 1), numberOfChildFolders)];
    NSArray *childFoldersArray = [directoryPathComponents objectsAtIndexes:indexSet];
    
    NSString *pathFromOffline = @"";
    if (childFoldersArray.count > 1) {
        for (NSString *folderString in childFoldersArray) {
            pathFromOffline = [pathFromOffline stringByAppendingPathComponent:folderString];
        }
    } else {
        pathFromOffline = folderName;
    }
    
    return pathFromOffline;
}

- (NSArray *)offlinePathOnFolder:(NSString *)path {
    NSString *relativePath = [Helper pathRelativeToOfflineDirectory:path];
    NSMutableArray *offlinePathsOnFolder = [[NSMutableArray alloc] init];
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [offlinePathsOnFolder addObject:[relativePath stringByAppendingPathComponent:item]];
            [offlinePathsOnFolder addObjectsFromArray:[self offlinePathOnFolder:[path stringByAppendingPathComponent:item]]];
        } else {
            [offlinePathsOnFolder addObject:[relativePath stringByAppendingPathComponent:item]];
        }
    }
    
    return offlinePathsOnFolder;
}

- (void)cancelPendingTransfersOnFolder:(NSString *)folderPath folderLink:(BOOL)isFolderLink {
    MEGATransferList *transferList;
    NSInteger transferListSize;
    if (isFolderLink) {
        transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
        transferListSize = [transferList.size integerValue];
    } else {
        transferList = [[MEGASdkManager sharedMEGASdk] transfers];
        transferListSize = [transferList.size integerValue];
    }
    
    for (NSInteger i = 0; i < transferListSize; i++) {
        MEGATransfer *transfer = [transferList transferAtIndex:i];
        if (transfer.type == MEGATransferTypeUpload) {
            continue;
        }
        
        if ([transfer.parentPath isEqualToString:[folderPath stringByAppendingString:@"/"]]) {
            if (isFolderLink) {
                [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transfer.tag];
            } else {
                [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transfer.tag];
            }
        } else {
            NSString *lastPathComponent = [folderPath lastPathComponent];
            NSArray *pathComponentsArray = [transfer.parentPath pathComponents];
            NSUInteger pathComponentsArrayCount = [pathComponentsArray count];
            for (NSUInteger j = 0; j < pathComponentsArrayCount; j++) {
                NSString *folderString = [pathComponentsArray objectAtIndex:j];
                if ([folderString isEqualToString:lastPathComponent]) {
                    if (isFolderLink) {
                        [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transfer.tag];
                    } else {
                        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transfer.tag];
                    }
                    break;
                }
            }
        }
    }
}

- (BOOL)isDirectorySelected {
    BOOL isDirectory = NO;
    for (NSURL *url in self.selectedItems) {
        [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];
        if (isDirectory) {
            return isDirectory;
        }
    }
    return isDirectory;
}

- (void)sortBySortType:(MEGASortOrderType)sortOrderType {
    NSSortDescriptor *sortDescriptor = nil;
    NSSortDescriptor *sortDirectoryDescriptor = nil;
    
    switch (sortOrderType) {
        case MEGASortOrderTypeDefaultAsc:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kFileName ascending:YES selector:@selector(localizedStandardCompare:)];
            sortDirectoryDescriptor = [[NSSortDescriptor alloc] initWithKey:kisDirectory ascending:NO];
            break;
        case MEGASortOrderTypeDefaultDesc:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kFileName ascending:NO selector:@selector(localizedStandardCompare:)];
            sortDirectoryDescriptor = [[NSSortDescriptor alloc] initWithKey:kisDirectory ascending:YES];
            break;
        case MEGASortOrderTypeSizeAsc:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kFileSize ascending:YES];
            sortDirectoryDescriptor = [[NSSortDescriptor alloc] initWithKey:kisDirectory ascending:NO];
            break;
        case MEGASortOrderTypeSizeDesc:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kFileSize ascending:NO];
            sortDirectoryDescriptor = [[NSSortDescriptor alloc] initWithKey:kisDirectory ascending:YES];
            break;
        case MEGASortOrderTypeModificationAsc:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kModificationDate ascending:YES];
            sortDirectoryDescriptor = [[NSSortDescriptor alloc] initWithKey:kisDirectory ascending:NO];
            break;
        case MEGASortOrderTypeModificationDesc:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kModificationDate ascending:NO];
            sortDirectoryDescriptor = [[NSSortDescriptor alloc] initWithKey:kisDirectory ascending:YES];
            break;
            
        default:
            break;
    }
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDirectoryDescriptor, sortDescriptor, nil];
    NSArray *sortedArray = [self.offlineItems sortedArrayUsingDescriptors:sortDescriptors];
    self.offlineItems = [NSMutableArray arrayWithArray:sortedArray];
}

- (MEGAQLPreviewController *)qlPreviewControllerForIndexPath:(NSIndexPath *)indexPath {
    MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithArrayOfFiles:self.offlineFiles];
    
    NSInteger selectedIndexFile = [[[self.offlineSortedItems objectAtIndex:indexPath.row] objectForKey:kIndex] integerValue];
    previewController.currentPreviewItemIndex = selectedIndexFile;
    
    [self.offlineTableView.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    return previewController;
}

- (void)reloadData {
    if (self.layoutView == LayoutModeList) {
        [self.offlineTableView.tableView reloadData];
    } else {
        [self.offlineCollectionView.collectionView reloadData];
    }
}

- (void)setEditMode:(BOOL)editMode {
    if (self.layoutView == LayoutModeList) {
        [self.offlineTableView setTableViewEditing:editMode animated:YES];
    } else {
        [self.offlineCollectionView setCollectionViewEditing:editMode animated:YES];
    }
}

- (void)selectIndexPath:(NSIndexPath *)indexPath {
    if (self.layoutView == LayoutModeList) {
        [self.offlineTableView tableViewSelectIndexPath:indexPath];
        [self.offlineTableView.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } else {
        [self.offlineCollectionView collectionViewSelectIndexPath:indexPath];
        [self.offlineCollectionView.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (NSInteger)numberOfRows {
    NSInteger numberOfRows = 0;
    if (self.layoutView == LayoutModeList) {
        numberOfRows = [self.offlineTableView.tableView numberOfRowsInSection:0];
    } else {
        numberOfRows = [self.offlineCollectionView.collectionView numberOfItemsInSection:0];
    }
    
    return numberOfRows;
}

- (MEGANavigationController *)webCodeViewControllerWithFilePath:(NSString *)filePath {
    WebCodeViewController *webCodeVC = [WebCodeViewController.alloc initWithFilePath:filePath];
    MEGANavigationController *navigationController = [MEGANavigationController.alloc initWithRootViewController:webCodeVC];
    [navigationController addLeftDismissButtonWithText:AMLocalizedString(@"ok", nil)];
    return navigationController;
}

#pragma mark - IBActions

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = self.offlineTableView ? !self.offlineTableView.tableView.isEditing : !self.offlineCollectionView.collectionView.allowsMultipleSelection;
    [self setEditMode:enableEditing];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedItems removeAllObjects];
    
    if (!self.allItemsSelected) {
        NSURL *filePathURL = nil;
        
        for (NSInteger i = 0; i < self.offlineSortedItems.count; i++) {
            filePathURL = [[self.offlineSortedItems objectAtIndex:i] objectForKey:kPath];
            [self.selectedItems addObject:filePathURL];
        }
        
        self.allItemsSelected = YES;
    } else {
        self.allItemsSelected = NO;
    }
    
    if (self.selectedItems.count == 0) {
        [self.activityBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    } else if (self.selectedItems.count >= 1) {
        [self.activityBarButtonItem setEnabled:![self isDirectorySelected]];
        [self.deleteBarButtonItem setEnabled:YES];
    }
    
    [self updateNavigationBarTitle];
    
    [self reloadData];
}

- (IBAction)activityTapped:(UIBarButtonItem *)sender {
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    if (self.selectedItems.count == 1) {
        OpenInActivity *openInActivity = [[OpenInActivity alloc] initOnBarButtonItem:sender];
        [activitiesMutableArray addObject:openInActivity];
    }
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:self.selectedItems applicationActivities:activitiesMutableArray];
    if (self.selectedItems.count > 5) {
        activityViewController.excludedActivityTypes = @[UIActivityTypeSaveToCameraRoll];
    }
    activityViewController.popoverPresentationController.barButtonItem = self.activityBarButtonItem;
    [activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed,  NSArray *returnedItems, NSError *activityError) {
        if (completed) {
            [self setEditMode:NO];
        }
    }];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)deleteTapped:(UIBarButtonItem *)sender {
    NSString *message;
    if (self.selectedItems.count == 1) {
        message = AMLocalizedString(@"removeItemFromOffline", nil);
    } else {
        message = AMLocalizedString(@"removeItemsFromOffline", nil);
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"remove", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        for (NSURL *url in self.selectedItems) {
            [self removeOfflineNodeCell:url.path];
        }
        [self reloadUI];
        [self setEditMode:NO];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)sortByTapped:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    SortByTableViewController *sortByTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"sortByTableViewControllerID"];
    sortByTableViewController.offline = YES;
    
    MEGANavigationController *megaNavigationController = [[MEGANavigationController alloc] initWithRootViewController:sortByTableViewController];
    
    [self presentViewController:megaNavigationController animated:YES completion:nil];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    UIAlertController *moreAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [moreAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    if ([self numberOfRows]) {
        NSString *changeViewTitle = (self.layoutView == LayoutModeList) ? AMLocalizedString(@"Thumbnail view", @"Text shown for switching from list view to thumbnail view.") : AMLocalizedString(@"List view", @"Text shown for switching from thumbnail view to list view.");
        UIAlertAction *changeViewAlertAction = [UIAlertAction actionWithTitle:changeViewTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self changeLayoutMode];
        }];
        [changeViewAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
        [moreAlertController addAction:changeViewAlertAction];
    }
    
    UIAlertAction *sortByAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"sortTitle", @"Section title of the 'Sort by'") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByTapped:self.sortByBarButtonItem];
    }];
    [sortByAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
    [moreAlertController addAction:sortByAlertAction];
    
    if (self.offlineSortedItems.count) {
        UIAlertAction *selectAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"select", @"Button that allows you to select a given folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self editTapped:self.editButtonItem];
        }];
        [selectAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
        [moreAlertController addAction:selectAlertAction];
    }
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        moreAlertController.modalPresentationStyle = UIModalPresentationPopover;
        moreAlertController.popoverPresentationController.barButtonItem = self.moreBarButtonItem;
        moreAlertController.popoverPresentationController.sourceView = self.view;
    }
    
    [self presentViewController:moreAlertController animated:YES completion:nil];
}

#pragma mark - Public

- (void)enableButtonsByNumberOfItems {
    NSInteger rows = self.searchController.isActive ? self.searchItemsArray.count : self.offlineSortedItems.count;
    if (rows == 0) {
        self.sortByBarButtonItem.enabled = NO;
        [self.editBarButtonItem setEnabled:NO];
    } else {
        self.sortByBarButtonItem.enabled = YES;
        [self.editBarButtonItem setEnabled:YES];
    }
}

- (void)enableButtonsBySelectedItems {
    if (self.selectedItems.count == 0) {
        [self.activityBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    } else {
        [self.activityBarButtonItem setEnabled:![self isDirectorySelected]];
        [self.deleteBarButtonItem setEnabled:YES];
    }
}

- (void)itemTapped:(NSString *)name atIndexPath:(NSIndexPath *)indexPath {
    self.previewDocumentPath = [[self currentOfflinePath] stringByAppendingPathComponent:name];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:self.previewDocumentPath isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *folderPathFromOffline = [self folderPathFromOffline:self.previewDocumentPath folder:name];
        
        OfflineViewController *offlineVC = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineViewControllerID"];
        [offlineVC setFolderPathFromOffline:folderPathFromOffline];
        
        [self.navigationController pushViewController:offlineVC animated:YES];
        
    } else if (self.previewDocumentPath.mnz_isMultimediaPathExtension) {
        if (MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
            [Helper cannotPlayContentDuringACallAlert];
            return;
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.previewDocumentPath]];
        
        if (asset.playable) {
            MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:[NSURL fileURLWithPath:self.previewDocumentPath]];
            [self presentViewController:megaAVViewController animated:YES completion:nil];
        } else {
            MEGAQLPreviewController *previewController = [self qlPreviewControllerForIndexPath:indexPath];
            [self presentViewController:previewController animated:YES completion:nil];
        }
        
    } else if ([self.previewDocumentPath.pathExtension isEqualToString:@"pdf"]){
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
        PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
        previewController.filesPathsArray = self.offlineFiles;
        previewController.nodeFileIndex = [[[self itemAtIndexPath:indexPath] objectForKey:kIndex] integerValue];
        [self presentViewController:navigationController animated:YES completion:nil];
        switch (self.layoutView) {
            case LayoutModeList:
                [self.offlineTableView.tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
                
            case LayoutModeThumbnail:
                [self.offlineCollectionView.collectionView deselectItemAtIndexPath:indexPath animated:YES];
                break;
        }
    } else if (self.previewDocumentPath.mnz_isWebCodePathExtension) {
        MEGANavigationController *navigationController = [self webCodeViewControllerWithFilePath:self.previewDocumentPath];
        [self presentViewController:navigationController animated:YES completion:nil];
    } else {
        MEGAQLPreviewController *previewController = [self qlPreviewControllerForIndexPath:indexPath];
        [self presentViewController:previewController animated:YES completion:nil];
    }
}

- (void)setViewEditing:(BOOL)editing {
    [self updateNavigationBarTitle];
    
    if (editing) {
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbar.items = @[self.activityBarButtonItem, flexibleItem, self.deleteBarButtonItem];
        
        self.navigationItem.rightBarButtonItem = self.editBarButtonItem;
        self.editBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.view addSubview:self.toolbar];
        self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutAnchor *bottomAnchor;
        if (@available(iOS 11.0, *)) {
            bottomAnchor = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
        } else {
            bottomAnchor = self.tabBarController.tabBar.bottomAnchor;
        }
        
        [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                  [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                  [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                  [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        self.navigationItem.rightBarButtonItem = self.moreBarButtonItem;
        self.allItemsSelected = NO;
        self.selectedItems = nil;
        self.navigationItem.leftBarButtonItems = @[];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
    
    if (!self.selectedItems) {
        self.selectedItems = [[NSMutableArray alloc] init];
        
        [self.activityBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    }
}

- (BOOL)removeOfflineNodeCell:(NSString *)itemPath {
    NSArray *offlinePathsOnFolderArray;
    MOOfflineNode *offlineNode;
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
    if (isDirectory) {
        if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue]) {
            [self cancelPendingTransfersOnFolder:itemPath folderLink:NO];
        }
        if ([[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue]) {
            [self cancelPendingTransfersOnFolder:itemPath folderLink:YES];
        }
        offlinePathsOnFolderArray = [self offlinePathOnFolder:itemPath];
    }
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:itemPath error:&error];
    offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:itemPath]];
    if (!success || error) {
        [SVProgressHUD showErrorWithStatus:@""];
        return NO;
    } else {
        if (isDirectory) {
            for (NSString *localPathAux in offlinePathsOnFolderArray) {
                offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:localPathAux];
                if (offlineNode) {
                    [[MEGAStore shareInstance] removeOfflineNode:offlineNode];
                }
            }
        } else {
            if (offlineNode) {
                [[MEGAStore shareInstance] removeOfflineNode:offlineNode];
            }
        }
        [self reloadUI];
        return YES;
    }
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.offlineTableView.tableView.isEditing || self.offlineCollectionView.collectionView.allowsMultipleSelection) {
        if (self.selectedItems.count == 0) {
            navigationTitle = AMLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            navigationTitle = (self.selectedItems.count == 1) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), self.selectedItems.count] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), self.selectedItems.count];
        }
    } else {
        if (self.folderPathFromOffline == nil) {
            navigationTitle = AMLocalizedString(@"offline", @"Offline");
        } else {
            navigationTitle = self.folderPathFromOffline.lastPathComponent;
        }
    }
    
    self.navigationItem.title = navigationTitle;
}

- (NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = nil;
    if (indexPath) {
        if (self.searchController.isActive) {
            item = [self.searchItemsArray objectAtIndex:indexPath.row];
        } else {
            item = [self.offlineSortedItems objectAtIndex:indexPath.row];
        }
    }
    return item;
}

- (NSString *)currentOfflinePath {
    NSString *pathString = [Helper pathForOffline];
    if (self.folderPathFromOffline != nil) {
        pathString = [pathString stringByAppendingPathComponent:self.folderPathFromOffline];
    }
    return pathString;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchItemsArray = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (self.layoutView == LayoutModeThumbnail) {
        self.offlineCollectionView.collectionView.clipsToBounds = YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.layoutView == LayoutModeThumbnail) {
        self.offlineCollectionView.collectionView.clipsToBounds = NO;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            self.searchItemsArray = self.offlineSortedItems;
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.kFileName contains[c] %@", searchString];
            self.searchItemsArray = [[self.offlineSortedItems filteredArrayUsingPredicate:resultPredicate] mutableCopy];
        }
    }
    
    [self reloadData];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    if (UIDevice.currentDevice.iPhoneDevice && UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) {
        [Helper resetSearchControllerFrame:searchController];
    }
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    UIView *view = self.offlineTableView ? self.offlineTableView.tableView : self.offlineCollectionView.collectionView;
    CGPoint touchPoint = [longPressGestureRecognizer locationInView:view];
    NSIndexPath *indexPath;
    
    if (self.layoutView == LayoutModeList) {
        indexPath = [self.offlineTableView.tableView indexPathForRowAtPoint:touchPoint];
        if (!indexPath || ![self.offlineTableView.tableView numberOfRowsInSection:indexPath.section]) {
            return;
        }
    } else {
        indexPath = [self.offlineCollectionView.collectionView indexPathForItemAtPoint:touchPoint];
        if (!indexPath || ![self.offlineCollectionView.collectionView numberOfItemsInSection:indexPath.section]) {
            return;
        }
    }
    
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {        
        if (self.offlineTableView.tableView.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedItems.count == 0) {
                [self setEditMode:NO];
            }
            if (self.selectedItems.count == 1) {
                NSURL *offlineUrlSelected = self.selectedItems.firstObject;
                NSURL *offlineUrlPressed = [[self.offlineSortedItems objectAtIndex:indexPath.row] objectForKey:kPath];
                if ([[offlineUrlPressed path] compare:[offlineUrlSelected path]] == NSOrderedSame) {
                    [self setEditMode:NO];
                }
            }
        } else {
            [self setEditMode:YES];
            [self selectIndexPath:indexPath];
        }
    }
    
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.offlineTableView.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if (self.offlineTableView.tableView.isEditing || self.offlineCollectionView.collectionView.allowsMultipleSelection) {
        return nil;
    }
    
    NSIndexPath *indexPath;
    NSString *itemName;
    if (self.layoutView == LayoutModeList) {
        CGPoint rowPoint = [self.offlineTableView.tableView convertPoint:location fromView:self.view];
        indexPath = [self.offlineTableView.tableView indexPathForRowAtPoint:rowPoint];
        if (!indexPath || ![self.offlineTableView.tableView numberOfRowsInSection:indexPath.section]) {
            return nil;
        }
        OfflineTableViewCell *cell = (OfflineTableViewCell *)[self.offlineTableView.tableView cellForRowAtIndexPath:indexPath];
        itemName = cell.itemNameString;
    } else {
        CGPoint rowPoint = [self.offlineCollectionView.collectionView convertPoint:location fromView:self.view];
        indexPath = [self.offlineCollectionView.collectionView indexPathForItemAtPoint:rowPoint];
        if (!indexPath || ![self.offlineCollectionView.collectionView numberOfItemsInSection:indexPath.section]) {
            return nil;
        }
        NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.offlineCollectionView.collectionView cellForItemAtIndexPath:indexPath];
        itemName = cell.nameLabel.text;
    }
    
    previewingContext.sourceRect = (self.layoutView == LayoutModeList) ? [self.offlineTableView.tableView convertRect:[self.offlineTableView.tableView cellForRowAtIndexPath:indexPath].frame toView:self.view] : [self.offlineCollectionView.collectionView convertRect:[self.offlineCollectionView.collectionView cellForItemAtIndexPath:indexPath].frame toView:self.view];
    
    self.previewDocumentPath = [[self currentOfflinePath] stringByAppendingPathComponent:itemName];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:self.previewDocumentPath isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *folderPathFromOffline = [self folderPathFromOffline:self.previewDocumentPath folder:itemName];
        
        OfflineViewController *offlineVC = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineViewControllerID"];
        offlineVC.folderPathFromOffline = folderPathFromOffline;
        offlineVC.peekIndexPath = indexPath;
        
        return offlineVC;
    } else if (self.previewDocumentPath.mnz_isMultimediaPathExtension) {
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.previewDocumentPath]];
        
        if (asset.playable) {
            MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:[NSURL fileURLWithPath:self.previewDocumentPath]];
            return megaAVViewController;
        } else {
            return [self qlPreviewControllerForIndexPath:indexPath];
        }
    } else if ([self.previewDocumentPath.pathExtension isEqualToString:@"pdf"]){
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
        PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
        previewController.filesPathsArray = self.offlineFiles;
        previewController.nodeFileIndex = [[[self itemAtIndexPath:indexPath] objectForKey:kIndex] integerValue];
        
        [self.offlineTableView.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        return navigationController;
    } else if (self.previewDocumentPath.mnz_isWebCodePathExtension) {
        return [self webCodeViewControllerWithFilePath:self.previewDocumentPath];
    } else {
        return [self qlPreviewControllerForIndexPath:indexPath];
    }
    
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if (viewControllerToCommit.class == OfflineViewController.class) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else {
        [self.navigationController presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    UIPreviewAction *deleteAction = [UIPreviewAction actionWithTitle:AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder")
                                                               style:UIPreviewActionStyleDestructive
                                                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                 if ([self removeOfflineNodeCell:[self currentOfflinePath]]) {
                                                                     [self reloadData];
                                                                 }
                                                             }];
    return @[deleteAction];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        if (self.folderPathFromOffline) {
            text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
        } else {
            text = AMLocalizedString(@"offlineEmptyState_title", @"Title shown when the Offline section is empty, when you don't have download any files. Keep the upper.");
        }
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper titleAttributesForEmptyState]];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            image = [UIImage imageNamed:@"searchEmptyState"];
        } else {
            image = nil;
        }
    } else {
        if (self.folderPathFromOffline) {
            image = [UIImage imageNamed:@"folderEmptyState"];
        } else {
            image = [UIImage imageNamed:@"offlineEmptyState"];
        }
    }
    
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:self.searchController.isActive];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        [self reloadUI];
    }
}

@end
