#import "OfflineViewController.h"

#import "SVProgressHUD.h"

#import "UIScrollView+EmptyDataSet.h"
#import "NSString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "EmptyStateView.h"
#import "MEGANavigationController.h"
#import "PreviewDocumentViewController.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NodeCollectionViewCell.h"
#import "OfflineTableViewCell.h"
#import "UIViewController+MNZCategory.h"
#import "NSArray+MNZCategory.h"
@import ChatRepo;
@import MEGADomain;
#import "LocalizationHelper.h"
@import MEGAUIKit;

static NSString *kFileName = @"kFileName";
static NSString *kIndex = @"kIndex";
static NSString *kPath = @"kPath";
static NSString *kModificationDate = @"kModificationDate";
static NSString *kFileSize = @"kFileSize";
static NSString *kisDirectory = @"kisDirectory";

@interface OfflineViewController () <UIViewControllerTransitioningDelegate, UIDocumentInteractionControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGATransferDelegate, UISearchControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *activityBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *offlineMultimediaFiles;
@property (nonatomic, strong) NSMutableArray *offlineItems;
@property (nonatomic, strong) NSMutableArray *offlineNonMultimediaFiles;

@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@property (nonatomic, assign) ViewModePreferenceEntity viewModePreference;

@property (nonatomic, copy) void (^openFileWhenViewReady)(void);

@end

@implementation OfflineViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureImages];
    
    self.currentContentInsetHeight = 0;
    
    [self determineViewMode];
    
    [self configureNavigationBar];
    
    [self configureNavigationBarButtons];
    
    [self setUpInvokeCommands];
    
    self.definesPresentationContext = YES;
    
    if (self.flavor == AccountScreen) {
        self.offlineTableView.tableView.allowsMultipleSelectionDuringEditing = YES;
    }
    
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self searchControllerDelegate:self];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.serialQueue = dispatch_queue_create("nz.mega.offlineviewcontroller.reloadui", DISPATCH_QUEUE_SERIAL);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshMiniPlayerIfNeeded];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sortingPreferenceDidChange:) name:MEGASortingPreference object:nil];
    
    [self observeViewMode];
    [self dispatchOnViewAppearAction];
    
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    [MEGASdk.sharedFolderLink retryPendingConnections];
    
    // If the user has activated the logs, then they are imported to the offline section from the shared sandbox:
    BOOL isDocumentDirectory = [self.currentOfflinePath isEqualToString:Helper.pathForOffline];
    if ([[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] boolForKey:@"logging"] && isDocumentDirectory) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        self.logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionLogsFolder] path];
        if ([fileManager fileExistsAtPath:self.logsPath]) {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:documentProviderLog]];
                [fileManager copyItemAtPath:[self.logsPath stringByAppendingPathComponent:documentProviderLog]  toPath:[[self currentOfflinePath] stringByAppendingPathComponent:documentProviderLog] error:nil];
                [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:fileProviderLog]];
                [fileManager copyItemAtPath:[self.logsPath stringByAppendingPathComponent:fileProviderLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:fileProviderLog] error:nil];
                [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:shareExtensionLog]];
                [fileManager copyItemAtPath:[self.logsPath stringByAppendingPathComponent:shareExtensionLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:shareExtensionLog] error:nil];
                [fileManager mnz_removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:notificationServiceExtensionLog]];
                [fileManager copyItemAtPath:[self.logsPath stringByAppendingPathComponent:notificationServiceExtensionLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:notificationServiceExtensionLog] error:nil];
                [self reloadUI];
            });
        }
    }
    
    [self reloadUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    if (self.openFileWhenViewReady != nil) {
        self.openFileWhenViewReady();
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self refreshMiniPlayerIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self dispatchOnViewWillDisappearAction];
    
    if (self.offlineTableView.tableView.isEditing) {
        self.selectedItems = nil;
        [self setEditMode:NO];
    }
    
    [self refreshMiniPlayerIfNeeded];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.offlineTableView.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (OfflineViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self createOfflineViewModel];
    }
    return _viewModel;
}

#pragma mark - Layout

- (void)determineViewMode {
    if (self.flavor == HomeScreen) {
        [self initTable];
        return;
    }

    ViewModePreferenceEntity viewModePreference = [NSUserDefaults.standardUserDefaults integerForKey:MEGAViewModePreference];
    switch (viewModePreference) {
        case ViewModePreferenceEntityPerFolder:
            //Check Core Data or determine according to the number of nodes with or without thumbnail
            break;

        case ViewModePreferenceEntityList:
            [self initTable];
            return;

        case ViewModePreferenceEntityThumbnail:
            [self initCollection];
            return;
        case ViewModePreferenceEntityMediaDiscovery:
            break;
    }

    NSString *relativePath = [[self currentOfflinePath] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()]  withString:@""];
    OfflineAppearancePreference *offlineAppearancePreference = [MEGAStore.shareInstance fetchOfflineAppearancePreferenceWithPath:relativePath];

    if (offlineAppearancePreference) {
        switch (offlineAppearancePreference.viewMode.integerValue) {
            case ViewModePreferenceEntityList:
                [self initTable];
                break;

            case ViewModePreferenceEntityThumbnail:
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
    
    self.viewModePreference = ViewModePreferenceEntityList;
    
    self.offlineTableView = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineTableID"];
    self.offlineTableView.offline = self;
   
    UIViewController *bannerContainerVC = [[BannerContainerViewRouter.alloc initWithContentViewController:self.offlineTableView bannerMessage:LocalizedString(@"offline.logOut.warning.message", @"Offline log out warning message") bannerType:BannerTypeWarning] build];
    [self add:bannerContainerVC container:self.containerView animate:NO];
    
    self.offlineTableView.tableView.emptyDataSetDelegate = self;
    self.offlineTableView.tableView.emptyDataSetSource = self;

    if(self.flavor == HomeScreen) {
        self.offlineTableView.tableView.bounces = NO;
    }
}

- (void)initCollection {
    [self.offlineTableView willMoveToParentViewController:nil];
    [self.offlineTableView.view removeFromSuperview];
    [self.offlineTableView removeFromParentViewController];
    self.offlineTableView = nil;
    
    self.viewModePreference = ViewModePreferenceEntityThumbnail;
    
    self.offlineCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineCollectionID"];
    self.offlineCollectionView.offline = self;
    
    UIViewController *bannerContainerVC = [[BannerContainerViewRouter.alloc initWithContentViewController:self.offlineCollectionView bannerMessage:LocalizedString(@"offline.logOut.warning.message", @"Offline log out warning message") bannerType:BannerTypeWarning] build];
    [self add:bannerContainerVC container:self.containerView animate:NO];
    
    self.offlineCollectionView.collectionView.emptyDataSetDelegate = self;
    self.offlineCollectionView.collectionView.emptyDataSetSource = self;
}

- (void)changeViewModePreference {
    self.viewModePreference = (self.viewModePreference == ViewModePreferenceEntityList) ? ViewModePreferenceEntityThumbnail : ViewModePreferenceEntityList;
    if ([NSUserDefaults.standardUserDefaults integerForKey:MEGAViewModePreference] == ViewModePreferenceEntityPerFolder) {
        NSString *relativePath = [self.currentOfflinePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()] withString:@""];
        [MEGAStore.shareInstance insertOrUpdateOfflineViewModeWithPath:relativePath viewMode:self.viewModePreference];
    } else {
        [NSUserDefaults.standardUserDefaults setInteger:self.viewModePreference forKey:MEGAViewModePreference];
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:NSNotification.MEGAViewModePreferenceDidChange object:self userInfo:@{MEGAViewModePreference : @(self.viewModePreference)}];
}

- (BOOL)isListViewModeSelected {
    return self.viewModePreference == ViewModePreferenceEntityList;
}

#pragma mark - Private

- (void)configureImages {
    self.activityBarButtonItem.image = [UIImage megaImageWithNamed:@"share"];
    self.selectAllBarButtonItem.image = [UIImage megaImageWithNamed:@"selectAllItems"];
    self.deleteBarButtonItem.image = [UIImage megaImageWithNamed:@"rubbishBin"];
}

- (void)sortingPreferenceDidChange:(NSNotification *)notification {
    [self reloadUI];
    [self configureNavigationBarButtons];
}

- (void)reloadUI {
    dispatch_async(self.serialQueue, ^(void) {
        NSMutableArray* tmpOfflineSortedItems = [[NSMutableArray alloc] init];
        NSMutableArray* tmpOfflineSortedFileItems = [[NSMutableArray alloc] init];
        NSMutableArray* tmpOfflineFiles = [[NSMutableArray alloc] init];
        NSMutableArray* tmpOfflineMultimediaFiles = [[NSMutableArray alloc] init];
        NSMutableArray* tmpOfflineItems = [[NSMutableArray alloc] init];
        
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
                [tempDictionary setValue:filePropertiesDictionary[NSFileModificationDate] forKey:kModificationDate];
                
                [tmpOfflineItems addObject:tempDictionary];
                
                if (!isDirectory) {
                    if (![self shouldSkipQLPreviewForFile:fileName]) {
                        offsetIndex++;
                    }
                }
            }
        }
        
        MEGASortOrderType sortOrderType = [Helper sortTypeFor:self.currentOfflinePath];
        tmpOfflineItems = [self sortBySortType:sortOrderType array: tmpOfflineItems];

        int multimediaOffsetIndex = 0;
        int nonMultimediaOffsetIndex = 0;

        for (NSDictionary *p in tmpOfflineItems) {
            NSURL *fileURL = [p objectForKey:kPath];
            NSString *fileName = [p objectForKey:kFileName];
            
            // Inbox folder in documents folder is created by the system. Don't show it
            if ([[[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"] isEqualToString:[fileURL path]]) {
                continue;
            }
            
            if (![fileName.lowercaseString.pathExtension isEqualToString:@"mega"]) {
                
                NSMutableDictionary *tempDictionary = [NSMutableDictionary new];
                [tempDictionary setValue:fileName forKey:kFileName];
                [tempDictionary setValue:fileURL forKey:kPath];
                
                NSDictionary *filePropertiesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:nil];
                BOOL isDirectory;
                [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
                
                [tempDictionary setValue:[NSNumber numberWithBool:isDirectory] forKey:kisDirectory];
                
                [tempDictionary setValue:[filePropertiesDictionary objectForKey:NSFileSize] forKey:kFileSize];
                [tempDictionary setValue:filePropertiesDictionary[NSFileModificationDate] forKey:kModificationDate];
                
                [tmpOfflineSortedItems addObject:tempDictionary];
                
                if (!isDirectory) {
                    [tmpOfflineSortedFileItems addObject:tempDictionary];
                    if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:fileName]) {
                        [tempDictionary setValue:[NSNumber numberWithInt:multimediaOffsetIndex] forKey:kIndex];
                        multimediaOffsetIndex++;
                        [tmpOfflineMultimediaFiles addObject:[fileURL path]];
                    } else if (![self shouldSkipQLPreviewForFile:fileName]) {
                        [tempDictionary setValue:[NSNumber numberWithInt:nonMultimediaOffsetIndex] forKey:kIndex];
                        nonMultimediaOffsetIndex++;
                        [tmpOfflineFiles addObject:[fileURL path]];
                    }
                }
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.offlineSortedItems = tmpOfflineSortedItems;
            self.offlineSortedFileItems = tmpOfflineSortedFileItems;
            self.offlineNonMultimediaFiles = tmpOfflineFiles;
            self.offlineMultimediaFiles = tmpOfflineMultimediaFiles;
            self.offlineItems = tmpOfflineItems;
            [self updateNavigationBarTitle];
            [self reloadData];
        });
    });
}

- (BOOL)shouldSkipQLPreviewForFile:(NSString *)fileName {
    return [FileExtensionGroupOCWrapper verifyIsMultiMedia:fileName] || [FileExtensionGroupOCWrapper verifyIsEditableText:fileName] || [fileName.pathExtension isEqualToString:@"pdf"];
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

- (NSMutableArray*)sortBySortType:(MEGASortOrderType)sortOrderType array: (NSArray *)items {
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
    return [[items sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
}

- (nullable MEGAQLPreviewController *)qlPreviewControllerForIndexPath:(NSIndexPath *)indexPath isMultimedia:(BOOL)isMultimedia {
    NSArray *filesArray = isMultimedia ? self.offlineMultimediaFiles : self.offlineNonMultimediaFiles;
    MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithArrayOfFiles:filesArray];
    NSMutableArray *items = self.viewModePreference == ViewModePreferenceEntityThumbnail ? self.offlineSortedFileItems : self.offlineSortedItems;
    NSDictionary *item = [items objectOrNilAtIndex:indexPath.row];
    if (item == nil) {
        return nil;
    }

    NSInteger selectedIndexFile = [[item objectForKey:kIndex] integerValue];
    previewController.currentPreviewItemIndex = selectedIndexFile;

    switch (self.viewModePreference) {
        case ViewModePreferenceEntityPerFolder:
            break;
            
        case ViewModePreferenceEntityList:
            [self.offlineTableView.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
            
        case ViewModePreferenceEntityThumbnail:
            [self.offlineCollectionView.collectionView deselectItemAtIndexPath:indexPath animated:YES];
            break;
        case ViewModePreferenceEntityMediaDiscovery:
            break;
    }
    
    return previewController;
}

- (void)reloadData {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        [self.offlineTableView.tableView reloadData];
    } else {
        [self.offlineCollectionView reloadData];
    }
}

- (void)setEditMode:(BOOL)editMode {
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        [self.offlineTableView setTableViewEditing:editMode animated:YES];
    } else {
        [self.offlineCollectionView setCollectionViewEditing:editMode animated:YES];
    }
}

- (NSInteger)numberOfRows {
    NSInteger numberOfRows = 0;
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        numberOfRows = [self.offlineTableView.tableView numberOfRowsInSection:0];
    } else {
        numberOfRows = [self.offlineCollectionView.collectionView mnz_totalRows];
    }
    
    return numberOfRows;
}

- (MEGANavigationController *)previewDocumentViewControllerForIndexPath:(NSIndexPath *)indexPath {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"DocumentPreviewer" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
    PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
    previewController.filePath = self.previewDocumentPath;
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    switch (self.viewModePreference) {
        case ViewModePreferenceEntityPerFolder:
            break;
            
        case ViewModePreferenceEntityList:
            [self.offlineTableView.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
            
        case ViewModePreferenceEntityThumbnail:
            [self.offlineCollectionView.collectionView deselectItemAtIndexPath:indexPath animated:YES];
            break;
        case ViewModePreferenceEntityMediaDiscovery:
            break;
    }
    return navigationController;
}

- (void)changeEditingModeStatus {
    BOOL enableEditing = self.offlineTableView ? !self.offlineTableView.tableView.isEditing : !self.offlineCollectionView.collectionView.allowsMultipleSelection;
    [self setEditMode:enableEditing];
}

- (void)nodesSortTypeHasChanged {
    [self reloadUI];
}

#pragma mark - IBActions

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    [self changeEditingModeStatus];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedItems removeAllObjects];
    
    if (!self.allItemsSelected) {
        
        NSArray *items = (self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty) ? self.searchItemsArray : self.offlineSortedItems;
        
        NSURL *filePathURL = nil;
        
        for (NSInteger i = 0; i < items.count; i++) {
            filePathURL = [[items objectAtIndex:i] objectForKey:kPath];
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
        [self.activityBarButtonItem setEnabled:YES];
        [self.deleteBarButtonItem setEnabled:YES];
    }
    
    [self updateNavigationBarTitle];
    
    [self reloadData];
}

- (IBAction)activityTapped:(UIBarButtonItem *)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:self.selectedItems applicationActivities:nil];
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
    [self showRemoveAlertWithConfirmAction:^{
        [self removeOfflineItems:self.selectedItems];
        [self setEditMode:NO];
    } andCancelAction:nil];
}

#pragma mark - Public

- (void)enableButtonsBySelectedItems {
    if (self.selectedItems.count == 0) {
        [self.activityBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    } else {
        [self.activityBarButtonItem setEnabled:YES];
        [self.deleteBarButtonItem setEnabled:YES];
    }
}

- (void)openFileFromWidgetWith:(NSString *)path {
    if (self.isViewReady) {
        MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:path]];
        for (int i = 0; i < self.offlineSortedItems.count; i++){
            NSDictionary *dictionary = self.offlineSortedItems[i];
            NSURL *url = [dictionary valueForKey:kPath];
           
            if ([url.path isEqualToString:[NSString stringWithFormat:@"%@%@", [Helper pathForOffline], offlineNode.localPath]]) {
                [self itemTapped:offlineNode.localPath.lastPathComponent atIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                return;
            }
        }
        
        MEGALogError(@"Offline file opened from QuickAccessWidget not found");
    } else {
        __weak typeof(self) weakSelf = self;
        self.openFileWhenViewReady = ^{
            [weakSelf openFileFromWidgetWith:path];
            weakSelf.openFileWhenViewReady = nil;
        };
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

    } else if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:self.previewDocumentPath]) {
        if (MEGAChatSdk.shared.mnz_existsActiveCall) {
            [Helper cannotPlayContentDuringACallAlert];
            return;
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.previewDocumentPath]];
        
        if (asset.isPlayable) {
            if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
                AVPlayerViewController *megaAVViewController = [[AVPlayerManager shared] makePlayerControllerFor:[NSURL fileURLWithPath:self.previewDocumentPath]];
                [self presentViewController:megaAVViewController animated:YES completion:nil];
            } else {
                [self presentAudioPlayerWithFileLink:self.previewDocumentPath filePaths:self.offlineMultimediaFiles];
            }
        } else {
            MEGAQLPreviewController *previewController = [self qlPreviewControllerForIndexPath:indexPath isMultimedia: YES];
            if (previewController == nil) {
                return;
            }
            [self presentViewController:previewController animated:YES completion:nil];
        }
        
    } else if ([self.previewDocumentPath.pathExtension isEqualToString:@"pdf"] || [FileExtensionGroupOCWrapper verifyIsEditableText:self.previewDocumentPath]) {
        [self presentViewController:[self previewDocumentViewControllerForIndexPath:indexPath] animated:YES completion:nil];
    } else {
        MEGAQLPreviewController *previewController = [self qlPreviewControllerForIndexPath:indexPath isMultimedia: NO];
        if (previewController == nil) {
            return;
        }
        [self presentViewController:previewController animated:YES completion:nil];
    }
}

- (void)setViewEditing:(BOOL)editing {
    [self updateNavigationBarTitle];
    
    if (editing) {
        
        self.navigationItem.rightBarButtonItem = self.editBarButtonItem;
        self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        
        UITabBar *tabBar = self.tabBarController.tabBar;
        if (tabBar == nil) {
            return;
        }
        
        if (![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.toolbar.items = @[self.activityBarButtonItem, flexibleItem, self.deleteBarButtonItem];
            
            [self.toolbar setAlpha:0.0];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor surface1Background]];
            
            NSLayoutAnchor *bottomAnchor = tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        }
    } else {
        [self configureNavigationBarButtons];
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
    
    [self updateAudioPlayerVisibility:editing];
    
    [self adjustSafeAreaBottomInset: editing ? self.toolbar.frame.size.height : self.currentContentInsetHeight];
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.offlineTableView.tableView.isEditing || self.offlineCollectionView.collectionView.allowsMultipleSelection) {
        navigationTitle = [self selectedCountTitle];
    } else {
        if (self.folderPathFromOffline == nil) {
            navigationTitle = LocalizedString(@"offline", @"Offline");
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
            item = [self.searchItemsArray objectOrNilAtIndex:indexPath.row];
        } else {
            item = [self.offlineSortedItems objectOrNilAtIndex:indexPath.row];
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

- (void)showRemoveAlertWithConfirmAction:(void (^)(void))confirmAction andCancelAction:(void (^ _Nullable)(void))cancelAction{
    NSString *message;
    if (self.selectedItems.count > 1) {
        message = LocalizedString(@"removeItemsFromOffline", @"");
    } else {
        message = LocalizedString(@"removeItemFromOffline", @"");
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"remove", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        confirmAction();
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (cancelAction) {
            cancelAction();
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showInfoFilePath:(NSString *)itemPath at:(NSIndexPath *)indexPath from:(UIButton *)sender {
    __weak __typeof__(self) weakSelf = self;
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    if ([self isCloudDriveRevampEnabled]) {
        [actions addObject:[self makeSelectActionSheetFor:indexPath]];
    }

    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"remove", @"Title for the action that allows to remove a file or folder") detail:nil image:[UIImage megaImageWithNamed:@"rubbishBin"] style:UIAlertActionStyleDefault actionHandler:^{
        [self showRemoveAlertWithConfirmAction:^{
            [self removeOfflineItems:@[[NSURL fileURLWithPath:itemPath]]];
        } andCancelAction:nil];
    }]];
    
    BOOL isDirectory;
    NSString *title;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
    if (isDirectory) {
        title = LocalizedString(@"general.export", @"Button title which, if tapped, will trigger the action to export something from MEGA with the objective of sharing it outside of the app");
    } else {
        NSString *exportFileFormat = LocalizedString(@"general.menuAction.exportFile.title", @"Button title which, if tapped, will trigger the action of downloading the node and after that the user will be able to share through the iOS share menu");
        title = [NSString stringWithFormat:exportFileFormat, 1];
    }
    if (fileExistsAtPath) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:title detail:nil image:[UIImage megaImageWithNamed:@"export"] style:UIAlertActionStyleDefault actionHandler:^{
            
            NSURL *itemPathURL = [NSURL fileURLWithPath:itemPath];
            
            NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:1];
            [selectedItems addObject:itemPathURL];
            
            UIActivityViewController *activityViewController = [UIActivityViewController.alloc initWithActivityItems:selectedItems applicationActivities:nil];
            
            [activityViewController setCompletionWithItemsHandler:nil];
            
            if (UIDevice.currentDevice.iPadDevice) {
                activityViewController.modalPresentationStyle = UIModalPresentationPopover;
                activityViewController.popoverPresentationController.sourceView = sender;
                activityViewController.popoverPresentationController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
            }
            
            [weakSelf presentViewController:activityViewController animated:YES completion:nil];
        }]];
    }
    
    ActionSheetViewController *fileInfoActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:sender];
    [self presentViewController:fileInfoActionSheet animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchItemsArray = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (self.viewModePreference == ViewModePreferenceEntityThumbnail) {
        self.offlineCollectionView.collectionView.clipsToBounds = YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.viewModePreference == ViewModePreferenceEntityThumbnail) {
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

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:nil buttonTitle:nil];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            text = LocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
        }
    } else {
        if (self.folderPathFromOffline) {
            text = LocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
        } else {
            text = LocalizedString(@"offlineEmptyState_title", @"Title shown when the Offline section is empty, when you don't have download any files. Keep the upper.");
        }
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image;
    if (self.searchController.isActive) {
        if (self.searchController.searchBar.text.length > 0) {
            image = [UIImage megaImageWithNamed:@"searchEmptyState"];
        } else {
            image = nil;
        }
    } else {
        if (self.folderPathFromOffline) {
            image = [UIImage megaImageWithNamed:@"folderEmptyState"];
        } else {
            image = [UIImage megaImageWithNamed:@"offlineEmptyState"];
        }
    }
    
    return image;
}

@end
