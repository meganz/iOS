
#import "MEGAIndexer.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "CloudDriveTableViewController.h"
#import "Helper.h"
#import "MEGASDKManager.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGANode+MNZCategory.h"
#import "NSString+MNZCategory.h"

#define MNZ_PERSIST_EACH 1000

@interface MEGAIndexer () <MEGATreeProcessorDelegate>

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic) NSMutableArray *base64HandlesToIndex;
@property (nonatomic) NSMutableArray *base64HandlesIndexed;
@property (nonatomic) uint64_t totalNodes;

@property (nonatomic) CSSearchableIndex *searchableIndex;
@property (nonatomic) NSURL *thumbnailGeneric;
@property (nonatomic) NSURL *thumbnailFolder;

@property (nonatomic) NSByteCountFormatter *byteCountFormatter;
@property (nonatomic) NSUserDefaults *sharedUserDefaults;

@property (nonatomic) NSString *pListPath;

@property (nonatomic) BOOL shouldStop;

@end

@implementation MEGAIndexer

- (instancetype)init {
    self = [super init];
    if (self) {
        _shouldStop = NO;
        _searchableIndex = [CSSearchableIndex defaultSearchableIndex];
        if ([[UIScreen mainScreen] scale] == 1) {
            _thumbnailGeneric = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spotlight_file" ofType:@"png"]];
            _thumbnailFolder = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spotlight_folder" ofType:@"png"]];
        } else if ([[UIScreen mainScreen] scale] == 2) {
            _thumbnailGeneric = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spotlight_file@2x" ofType:@"png"]];
            _thumbnailFolder = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spotlight_folder@2x" ofType:@"png"]];
        } else if ([[UIScreen mainScreen] scale] == 3) {
            _thumbnailGeneric = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spotlight_file@3x" ofType:@"png"]];
            _thumbnailFolder = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spotlight_folder@3x" ofType:@"png"]];
        }
        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        [_byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
        _sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
        _pListPath = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] URLByAppendingPathComponent:@"spotlightTree.plist"] path];
        if ([_sharedUserDefaults boolForKey:@"treeCompleted"]) {
            _base64HandlesToIndex = [NSMutableArray arrayWithContentsOfFile:self.pListPath];
            MEGALogDebug(@"%lu nodes pending after loading from pList", _base64HandlesToIndex.count);
            _base64HandlesIndexed = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (void)generateAndSaveTree {
    self.semaphore = dispatch_semaphore_create(0);
    self.base64HandlesToIndex = [[NSMutableArray alloc] init];
    self.base64HandlesIndexed = [[NSMutableArray alloc] init];

    if ([[MEGASdkManager sharedMEGASdk] totalNodes]) {
        self.totalNodes = [[MEGASdkManager sharedMEGASdk] totalNodes] - 1; // -1 because totalNodes counts the inShares root node, not processed here
        [[MEGASdkManager sharedMEGASdk] processMEGANodeTree:[[MEGASdkManager sharedMEGASdk] rootNode] recursive:YES delegate:self];
        NSArray *inSharesArray = [[[MEGASdkManager sharedMEGASdk] inShares] mnz_nodesArrayFromNodeList];
        for (MEGANode *n in inSharesArray) {
            [[MEGASdkManager sharedMEGASdk] processMEGANodeTree:n recursive:YES delegate:self];
        }
        [[MEGASdkManager sharedMEGASdk] processMEGANodeTree:[[MEGASdkManager sharedMEGASdk] rubbishNode] recursive:YES delegate:self];
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    }
    
    [self saveTree];
    [self.sharedUserDefaults setBool:YES forKey:@"treeCompleted"];
}

- (void)saveTree {
    NSMutableArray *toIndex = [[NSMutableArray alloc] initWithArray:self.base64HandlesToIndex copyItems:YES];
    [toIndex removeObjectsInArray:self.base64HandlesIndexed];
    [toIndex writeToFile:self.pListPath atomically:YES];
    MEGALogDebug(@"%lu nodes pending", toIndex.count);
}

- (void)indexTree {
    MEGALogInfo(@"Spotlight start");
    for (NSString *base64Handle in self.base64HandlesToIndex) {
        uint64_t handle = [MEGASdk handleForBase64Handle:base64Handle];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:handle];
        if (node) {
            if ([self index:node]) {
                [self.base64HandlesIndexed addObject:base64Handle];
            }
        } else {
            if ([self removeFromIndex:base64Handle]) {
                [self.base64HandlesIndexed addObject:base64Handle];
            }
        }
        if (self.shouldStop) {
            break;
        }
        if (self.base64HandlesIndexed.count%MNZ_PERSIST_EACH == 0) {
            [self saveTree];
        }
    }
    [self saveTree];
    
    // self is still needed, but the arrays are not any more:
    [self.base64HandlesToIndex removeAllObjects];
    [self.base64HandlesIndexed removeAllObjects];
}

- (void)stopIndexing {
    self.shouldStop = YES;
}

#pragma mark - Spotlight

- (BOOL)index:(MEGANode *)node {
    __block BOOL success = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    if (![[MEGASdkManager sharedMEGASdk] nodePathForNode:node]) {
        return [self removeFromIndex:[node base64Handle]];
    }
    
    [self.searchableIndex indexSearchableItems:@[[self spotlightSearchableItemForNode:node downloadThumbnail:NO]] completionHandler:^(NSError *error){
        if (error) {
            MEGALogError(@"Spotlight error %@", error);
        } else {
            success = YES;
            MEGALogDebug(@"Spotlight indexed node");
        }
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return success;
}

- (BOOL)removeFromIndex:(NSString *)base64Handle {
    __block BOOL success = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    [self.searchableIndex deleteSearchableItemsWithIdentifiers:@[base64Handle] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"Spotlight error %@", error);
        } else {
            success = YES;
            MEGALogDebug(@"Spotlight indexed node");
        }
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return success;
}

- (CSSearchableItem *)spotlightSearchableItemForNode:(MEGANode *)node downloadThumbnail:(BOOL)downloadThumbnail {
    NSString *path = [[MEGASdkManager sharedMEGASdk] nodePathForNode:node];
    
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeData];
    attributeSet.title = node.name;
    
    if ([node isFile]) {
        NSString *extendedDescription = [self.byteCountFormatter stringFromByteCount:node.size.longLongValue];
        attributeSet.contentDescription = [NSString stringWithFormat:@"%@\n%@", path, extendedDescription];
    } else {
        attributeSet.contentDescription = path;
    }
    
    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([node hasThumbnail] && [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
        attributeSet.thumbnailURL = [NSURL fileURLWithPath:thumbnailFilePath];
    } else {
        if ([node hasThumbnail] && downloadThumbnail) {
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
            attributeSet.thumbnailURL = [NSURL fileURLWithPath:thumbnailFilePath];
        } else {
            if ([node isFile]) {
                attributeSet.thumbnailURL = self.thumbnailGeneric;
            } else {
                attributeSet.thumbnailURL = self.thumbnailFolder;
            }
        }
    }
    
    CSSearchableItem *searchableItem = [[CSSearchableItem alloc] initWithUniqueIdentifier:[node base64Handle] domainIdentifier:@"nodes" attributeSet:attributeSet];
    return searchableItem;
}

#pragma mark - continueUserActivity

- (void)presentNodeFromSpotlight:(MEGANode *)node inNavigationController:(UINavigationController *)navigationController {
    NSMutableArray *nodes = [[NSMutableArray alloc] init];

    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) { // node from inshare
        MEGANode *tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[node parentHandle]];
        while (tempNode != nil) {
            [nodes insertObject:tempNode atIndex:0];
            tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[tempNode parentHandle]];
        }
    } else {
        uint64_t rootHandle;
        if ([[[MEGASdkManager sharedMEGASdk] nodePathForNode:node] hasPrefix:@"//bin"]) {
            rootHandle = [[MEGASdkManager sharedMEGASdk] rubbishNode].parentHandle;
        } else {
            rootHandle = [[MEGASdkManager sharedMEGASdk] rootNode].handle;
        }
        uint64_t tempHandle = [node parentHandle];
        while (tempHandle != rootHandle) {
            MEGANode *tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:tempHandle];
            [nodes insertObject:tempNode atIndex:0];
            tempHandle = [tempNode parentHandle];
        }
    }

    [navigationController popToRootViewControllerAnimated:NO];
    
    for (MEGANode *n in nodes) {
        CloudDriveTableViewController *cdvc = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        [cdvc setParentNode:n];
        [navigationController pushViewController:cdvc animated:NO];
    }
    
    switch ([node type]) {
        case MEGANodeTypeFolder: {
            CloudDriveTableViewController *cdvc = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            [cdvc setParentNode:node];
            [navigationController pushViewController:cdvc animated:NO];
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension) {
                [node mnz_openImageInNavigationController:navigationController withNodes:@[node] folderLink:NO displayMode:DisplayModeCloudDrive];
            } else {
                [node mnz_openNodeInNavigationController:navigationController folderLink:NO];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGATreeProcessorDelegate

- (BOOL)processMEGANode:(MEGANode *)node {
    static unsigned int processed = 0;
    [self.base64HandlesToIndex addObject:[node base64Handle]];
    if (++processed == self.totalNodes) {
        processed = 0;
        dispatch_semaphore_signal(self.semaphore);
        return NO;
    }
    return YES;
}

@end
