
#import "OfflineTableViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "NSMutableAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "MEGANavigationController.h"
#import "MEGASdkManager.h"
#import "MEGAQLPreviewController.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "OfflineTableViewCell.h"
#import "OpenInActivity.h"
#import "SortByTableViewController.h"

#import "MEGAStore.h"
#import "MEGAAVViewController.h"

static NSString *kFileName = @"kFileName";
static NSString *kIndex = @"kIndex";
static NSString *kPath = @"kPath";
static NSString *kModificationDate = @"kModificationDate";
static NSString *kFileSize = @"kFileSize";
static NSString *kisDirectory = @"kisDirectory";

@interface OfflineTableViewController () <UIViewControllerTransitioningDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGATransferDelegate> {
    NSString *previewDocumentPath;
    BOOL allItemsSelected;
    BOOL isSwipeEditing;
}

@property (nonatomic, strong) NSMutableArray *offlineSortedItems;
@property (nonatomic, strong) NSMutableArray *offlineFiles;
@property (nonatomic, strong) NSMutableArray *offlineMultimediaFiles;
@property (nonatomic, strong) NSMutableArray *offlineItems;

@property (nonatomic, strong) NSString *folderPathFromOffline;

@property (nonatomic, strong) NSMutableArray *selectedItems;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *activityBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sortByBarButtonItem;

@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

@end

@implementation OfflineTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    if (self.folderPathFromOffline == nil) {
        [self.navigationItem setTitle:AMLocalizedString(@"offline", @"Offline")];
    } else {
        NSString *currentFolderName = [self.folderPathFromOffline lastPathComponent];
        [self.navigationItem setTitle:currentFolderName];
    }
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [self.toolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 49)];    
    [self.toolbar setItems:@[self.activityBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhone6XPlus]) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    [self.navigationItem setRightBarButtonItems:@[negativeSpaceBarButtonItem, self.editBarButtonItem, self.sortByBarButtonItem]];
    
    // Long press to select:
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadEmptyDataSet) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    // If the user has activated the logs, then they are imported to the offline section from the shared sandbox:
    if ([[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"logging"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"logs"] path];
        if ([fileManager fileExistsAtPath:logsPath]) {
            NSString *documentProviderLog = @"MEGAiOS.docExt.log";
            NSString *fileProviderLog = @"MEGAiOS.fileExt.log";
            NSString *shareExtensionLog = @"MEGAiOS.shareExt.log";
            [fileManager removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:documentProviderLog] error:nil];
            [fileManager copyItemAtPath:[logsPath stringByAppendingPathComponent:documentProviderLog]  toPath:[[self currentOfflinePath] stringByAppendingPathComponent:documentProviderLog] error:nil];
            [fileManager removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:fileProviderLog] error:nil];
            [fileManager copyItemAtPath:[logsPath stringByAppendingPathComponent:fileProviderLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:fileProviderLog] error:nil];
            [fileManager removeItemAtPath:[[self currentOfflinePath] stringByAppendingPathComponent:shareExtensionLog] error:nil];
            [fileManager copyItemAtPath:[logsPath stringByAppendingPathComponent:shareExtensionLog] toPath:[[self currentOfflinePath] stringByAppendingPathComponent:shareExtensionLog] error:nil];
        }
    }
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
    
    if (self.tableView.isEditing) {
        self.selectedItems = nil;
        [self setEditing:NO animated:NO];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
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
            
            [tempDictionary setValue:[NSNumber numberWithBool:isDirectory ? YES : NO] forKey:kisDirectory];
            
            [tempDictionary setValue:[filePropertiesDictionary objectForKey:NSFileSize] forKey:kFileSize];
            [tempDictionary setValue:[filePropertiesDictionary valueForKey:NSFileModificationDate] forKey:kModificationDate];
            
            [self.offlineItems addObject:tempDictionary];
            
            if (!isDirectory) {
                if (!fileName.mnz_isMultimediaPathExtension) {
                    offsetIndex++;
                }
            }
        }
    }
    
    //Sort configuration by default is "default ascending"
    if (![[NSUserDefaults standardUserDefaults] integerForKey:@"OfflineSortOrderType"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"OfflineSortOrderType"];
        [[NSUserDefaults standardUserDefaults] synchronize];
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
            
            [tempDictionary setValue:[NSNumber numberWithBool:isDirectory ? YES : NO] forKey:kisDirectory];
            
            [tempDictionary setValue:[filePropertiesDictionary objectForKey:NSFileSize] forKey:kFileSize];
            [tempDictionary setValue:[filePropertiesDictionary valueForKey:NSFileModificationDate] forKey:kModificationDate];
            
            [self.offlineSortedItems addObject:tempDictionary];
            
            if (!isDirectory) {
                if (fileName.mnz_isMultimediaPathExtension) {
                    [self.offlineMultimediaFiles addObject:[fileURL path]];
                } else {
                    offsetIndex++;
                    [self.offlineFiles addObject:[fileURL path]];
                }
            }
        }
    }
    
    [self.tableView reloadData];
}

- (NSString *)currentOfflinePath {
    NSString *pathString = [Helper pathForOffline];
    if (self.folderPathFromOffline != nil) {
        pathString = [pathString stringByAppendingPathComponent:self.folderPathFromOffline];
    }
    return pathString;
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.offlineSortedItems.count == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        self.sortByBarButtonItem.enabled = NO;
        [self.editBarButtonItem setEnabled:NO];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        self.sortByBarButtonItem.enabled = YES;
        [self.editBarButtonItem setEnabled:YES];
    }
    return self.offlineSortedItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OfflineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"offlineTableViewCell" forIndexPath:indexPath];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    NSString *directoryPathString = [self currentOfflinePath];
    NSString *nameString = [[self.offlineSortedItems objectAtIndex:indexPath.row] objectForKey:kFileName];
    NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:nameString];
    
    [cell setItemNameString:nameString];
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    NSString *handleString = [offNode base64Handle];
    
    [cell.thumbnailPlayImageView setHidden:YES];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        [cell.thumbnailImageView setImage:[Helper folderImage]];
        
        NSInteger files = 0;
        NSInteger folders = 0;
        
        NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathForItem error:nil];
        for (NSString *file in directoryContents) {
            BOOL isDirectory;
            NSString *path = [pathForItem stringByAppendingPathComponent:file];
            if (![path.pathExtension.lowercaseString isEqualToString:@"mega"]) {
                [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
                isDirectory ? folders++ : files++;
            }

        }
        
        [cell.infoLabel setText:[NSString mnz_stringByFiles:files andFolders:folders]];
    } else {
        NSString *extension = [[nameString pathExtension] lowercaseString];
        NSString *fileTypeIconString = [Helper fileTypeIconForExtension:extension];
        
        if (!handleString) {
            NSString *fpLocal = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:pathForItem];
            if (fpLocal) {
                MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fpLocal];
                if (node) {
                    handleString = [node base64Handle];
                    [[MEGAStore shareInstance] insertOfflineNode:node api:[MEGASdkManager sharedMEGASdk] path:[[Helper pathRelativeToOfflineDirectory:pathForItem] decomposedStringWithCanonicalMapping]];
                }
            }
        }
        
        NSString *thumbnailFilePath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
        thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
            
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath] && handleString) {
            UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
            if (thumbnailImage != nil) {
                [cell.thumbnailImageView setImage:thumbnailImage];
                if (nameString.mnz_isVideoPathExtension) {
                    [cell.thumbnailPlayImageView setHidden:NO];
                }
            }
            
        } else {
            if (nameString.mnz_isImagePathExtension) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                    [[MEGASdkManager sharedMEGASdk] createThumbnail:pathForItem destinatioPath:thumbnailFilePath];
                }
            } else {
                UIImage *iconImage = [UIImage imageNamed:fileTypeIconString];
                [cell.thumbnailImageView setImage:iconImage];
            }
        }
        
        NSDictionary *filePropertiesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:pathForItem error:nil];
        
        time_t rawtime = [[filePropertiesDictionary valueForKey:NSFileModificationDate] timeIntervalSince1970];
        NSString *date = [Helper dateWithISO8601FormatOfRawTime:rawtime];
        
        unsigned long long size;        
        size = [[[NSFileManager defaultManager] attributesOfItemAtPath:pathForItem error:nil] fileSize];
        
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleMemory];
        NSString *sizeAndDate = [NSString stringWithFormat:@"%@ • %@", sizeString, date];
        [cell.infoLabel setText:sizeAndDate];
    }
    [cell.nameLabel setText:[[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:nameString]];
    
    if (self.isEditing) {
        for (NSURL *url in self.selectedItems) {
            if ([url.path isEqualToString:pathForItem]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        NSString *itemPath = [[self currentOfflinePath] stringByAppendingPathComponent:[cell itemNameString]];
        NSArray *offlinePathsOnFolderArray;
        MOOfflineNode *offlineNode;
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
        if (isDirectory) {
            if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] != 0) {
                [self cancelPendingTransfersOnFolder:itemPath folderLink:NO];
            }
            if ([[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] != 0) {
                [self cancelPendingTransfersOnFolder:itemPath folderLink:YES];
            }
            offlinePathsOnFolderArray = [self offlinePathOnFolder:itemPath];
        }
        
        NSError *error = nil;
        BOOL success = [ [NSFileManager defaultManager] removeItemAtPath:itemPath error:&error];
        offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:itemPath]];
        if (!success || error) {
            [SVProgressHUD showErrorWithStatus:@""];
            return;
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
        }
    }
    [self setEditing:NO animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.isEditing) {
        NSURL *filePathURL = [[self.offlineSortedItems objectAtIndex: indexPath.row] objectForKey:kPath];
        [self.selectedItems addObject:filePathURL];
        
        if (self.selectedItems.count > 0) {
            [self.activityBarButtonItem setEnabled:![self isDirectorySelected]];
            [self.deleteBarButtonItem setEnabled:YES];
        }
        
        if (self.selectedItems.count == self.offlineSortedItems.count) {
            allItemsSelected = YES;
        } else {
            allItemsSelected = NO;
        }
        
        return;
    }
    
    OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSString *itemNameString = [cell itemNameString];
    previewDocumentPath = [[self currentOfflinePath] stringByAppendingPathComponent:itemNameString];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:previewDocumentPath isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *folderPathFromOffline = [self folderPathFromOffline:previewDocumentPath folder:[cell itemNameString]];
        
        OfflineTableViewController *offlineTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineTableViewControllerID"];
        [offlineTVC setFolderPathFromOffline:folderPathFromOffline];
        [self.navigationController pushViewController:offlineTVC animated:YES];
    } else if (previewDocumentPath.mnz_isMultimediaPathExtension) {
        MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:[NSURL fileURLWithPath:previewDocumentPath]];
        [self presentViewController:megaAVViewController animated:YES completion:nil];
    } else {
        MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithArrayOfFiles:self.offlineFiles];
        
        NSInteger selectedIndexFile = [[[self.offlineSortedItems objectAtIndex:indexPath.row] objectForKey:kIndex] integerValue];
        
        [previewController setCurrentPreviewItemIndex:selectedIndexFile];
        [self presentViewController:previewController animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
   
    if (tableView.isEditing) {
        NSURL *filePathURL = [[self.offlineSortedItems objectAtIndex: indexPath.row] objectForKey:kPath];
        
        NSMutableArray *tempArray = [self.selectedItems copy];
        for (NSURL *url in tempArray) {
            if ([[url filePathURL] isEqual:filePathURL]) {
                [self.selectedItems removeObject:url];
            }
        }
        
        if (self.selectedItems.count == 0) {
            [self.activityBarButtonItem setEnabled:NO];
            [self.deleteBarButtonItem setEnabled:NO];
        } else {
            [self.activityBarButtonItem setEnabled:![self isDirectorySelected]];
            [self.deleteBarButtonItem setEnabled:YES];
        }
        
        allItemsSelected = NO;
        
        return;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *fileURL = [[self.offlineSortedItems objectAtIndex:indexPath.row] objectForKey:kPath];
    
    self.selectedItems = [[NSMutableArray alloc] init];
    [self.selectedItems addObject:fileURL];
    [self.deleteBarButtonItem setEnabled:YES];
    [self.activityBarButtonItem setEnabled:![self isDirectorySelected]];
    
    isSwipeEditing = YES;
    
    return UITableViewCellEditingStyleDelete;
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        }
        
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.tabBar addSubview:self.toolbar];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allItemsSelected = NO;
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
    
    isSwipeEditing = NO;
}

#pragma mark - IBActions

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    [self setEditing:enableEditing animated:YES];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedItems removeAllObjects];
    
    if (!allItemsSelected) {
        NSURL *filePathURL = nil;
        
        for (NSInteger i = 0; i < self.offlineSortedItems.count; i++) {
            filePathURL = [[self.offlineSortedItems objectAtIndex:i] objectForKey:kPath];
            [self.selectedItems addObject:filePathURL];
        }
        
        allItemsSelected = YES;
    } else {
        allItemsSelected = NO;
    }

    if (self.selectedItems.count == 0) {
        [self.activityBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    } else if (self.selectedItems.count >= 1) {
        [self.activityBarButtonItem setEnabled:![self isDirectorySelected]];
        [self.deleteBarButtonItem setEnabled:YES];
    }

    [self.tableView reloadData];
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
        [self setEditing:NO animated:YES];
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
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"remove", nil)
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                              otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
    [alertView show];
}

- (IBAction)sortByTapped:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    SortByTableViewController *sortByTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"sortByTableViewControllerID"];
    sortByTableViewController.offline = YES;
    
    MEGANavigationController *megaNavigationController = [[MEGANavigationController alloc] initWithRootViewController:sortByTableViewController];
    
    [self presentViewController:megaNavigationController animated:YES completion:nil];
}

#pragma mark - UIDocumentInteractionController

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressGestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        
        if (self.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedItems.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedItems.count == 1) {
                NSURL *offlineUrlSelected = self.selectedItems.firstObject;
                NSURL *offlineUrlPressed = [[self.offlineSortedItems objectAtIndex:indexPath.row] objectForKey:kPath];
                if ([[offlineUrlPressed path] compare:[offlineUrlSelected path]] == NSOrderedSame) {
                    [self setEditing:NO animated:YES];
                }
            }
        } else {
            [self setEditing:YES animated:YES];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.folderPathFromOffline == nil) {
            return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"offlineEmptyState_title", @"Title shown when the Offline section is empty, when you don't have download any files. Keep the upper.") sectionTitle:AMLocalizedString(@"offline", @"Title of the Offline section")];
        } else {
            text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.folderPathFromOffline == nil) {
            image = [UIImage imageNamed:@"emptyOffline"];
        } else {
            image = [UIImage imageNamed:@"emptyFolder"];
        }
    } else {
        image = [UIImage imageNamed:@"noInternetConnection"];
    }
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        for (NSURL *url in self.selectedItems) {
            
            NSArray *offlinePathsOnFolderArray;
            MOOfflineNode *offlineNode;
            
            BOOL isDirectory;
            [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];
            if (isDirectory) {
                if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] != 0) {
                    [self cancelPendingTransfersOnFolder:url.path folderLink:NO];
                }
                if ([[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] != 0) {
                    [self cancelPendingTransfersOnFolder:url.path folderLink:YES];
                }
                offlinePathsOnFolderArray = [self offlinePathOnFolder:url.path];
            }
            
            NSError *error = nil;
            BOOL success = [ [NSFileManager defaultManager] removeItemAtPath:url.path error:&error];
            offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:url.path]];
            if (!success || error) {
                [SVProgressHUD showErrorWithStatus:@""];
                return;
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
            }
        }
        [self reloadUI];
        [self setEditing:NO animated:YES];
    }
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
