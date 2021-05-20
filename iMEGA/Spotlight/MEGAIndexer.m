
#import "MEGAIndexer.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Helper.h"
#import "MEGASDKManager.h"
#import "MEGANodeList+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "LTHPasscodeViewController.h"

#define MNZ_PERSIST_EACH 1000

@interface MEGAIndexer () <MEGATreeProcessorDelegate, MEGAGlobalDelegate, MEGARequestDelegate>

@property (strong, nonatomic) NSOperationQueue *indexSerialQueue;
@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic) NSMutableArray *base64HandlesToIndex;
@property (nonatomic) NSMutableArray *base64HandlesIndexed;
@property (nonatomic) uint64_t totalNodes;

@property (nonatomic) CSSearchableIndex *searchableIndex;
@property (nonatomic) UIImage *genericFileThumbnail;
@property (nonatomic) UIImage *genericFolderThumbnail;

@property (nonatomic) NSUserDefaults *sharedUserDefaults;

@property (nonatomic) NSString *pListPath;

@property (nonatomic) BOOL shouldStop;

@end

@implementation MEGAIndexer

+ (instancetype)sharedIndexer {
    static MEGAIndexer *indexer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexer = MEGAIndexer.alloc.init;
    });
    return indexer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _indexSerialQueue = [[NSOperationQueue alloc] init];
        _indexSerialQueue.maxConcurrentOperationCount = 1;
        _indexSerialQueue.qualityOfService = NSQualityOfServiceBackground;
        _indexSerialQueue.name = @"nz.mega.spotlight.nodesIndexing";
        _shouldStop = NO;
        _searchableIndex = [CSSearchableIndex defaultSearchableIndex];
        _genericFileThumbnail = [UIImage imageNamed:@"Spotlight_file"];
        _genericFolderThumbnail = [UIImage imageNamed:@"Spotlight_folder"];
        _sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
        _pListPath = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] URLByAppendingPathComponent:@"spotlightTree.plist"] path];
        if ([_sharedUserDefaults boolForKey:@"treeCompleted"]) {
            _base64HandlesToIndex = [NSMutableArray arrayWithContentsOfFile:self.pListPath];
            MEGALogDebug(@"[Spotlight] %lu nodes pending after loading from pList", (unsigned long)_base64HandlesToIndex.count);
            _base64HandlesIndexed = [[NSMutableArray alloc] init];
        }
        
        [MEGASdkManager.sharedMEGASdk addMEGAGlobalDelegate:self];
    }
    return self;
}

- (void)reindexSpotlightIfNeeded {
    if (!self.enableSpotlight) {
        return;
    }
    
    if (self.shouldStop) {
        return;
    }
    
    [self.indexSerialQueue addOperationWithBlock:^{
        if (![self.sharedUserDefaults boolForKey:@"treeCompleted"]) {
            [self generateAndSaveTree];
        }
        @try {
            [self indexTree];
        } @catch (NSException *exception) {
            MEGALogError(@"Exception during spotlight indexing: %@", exception);
        }
    }];
}

- (void)setEnableSpotlight:(BOOL)enableSpotlight {
    if (self.enableSpotlight == enableSpotlight) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setBool:!enableSpotlight forKey:@"spotlightDisabled"];
    
    if (enableSpotlight) {
        [self reindexSpotlightIfNeeded];
    } else {
        NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
        [sharedUserDefaults removeObjectForKey:@"treeCompleted"];
        [MEGAIndexer.sharedIndexer deleteIndexTree];
    }
}

- (BOOL)enableSpotlight {
    return ![NSUserDefaults.standardUserDefaults boolForKey:@"spotlightDisabled"];
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
    MEGALogDebug(@"[Spotlight] %lu nodes pending after saving to pList", (unsigned long)toIndex.count);
}

- (void)indexTree {
    if (self.shouldStop) {
        return;
    }
    
    MEGALogInfo(@"[Spotlight] start indexing");
    for (NSString *base64Handle in self.base64HandlesToIndex) {
        @autoreleasepool {
            if (self.shouldStop) {
                break;
            }
            
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

            if (self.base64HandlesIndexed.count%MNZ_PERSIST_EACH == 0) {
                [self saveTree];
            }
        }
    }
    [self saveTree];
    
    // self is still needed, but the arrays are not any more:
    [self.base64HandlesToIndex removeAllObjects];
    [self.base64HandlesIndexed removeAllObjects];
}

- (void)stopIndexing {
    MEGALogDebug(@"Stopping spotlight indexing");
    self.shouldStop = YES;
    [self.indexSerialQueue cancelAllOperations];
}

- (void)deleteIndexTree {
    // Delete Spotlight index
    [self.searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[@"nodes"] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"Error deleting spotligth index");
        } else {
            MEGALogInfo(@"Spotlight index deleted");
        }
    }];
}

#pragma mark - Spotlight

- (BOOL)index:(MEGANode *)node {
    __block BOOL success = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    if ([[MEGASdkManager sharedMEGASdk] nodePathForNode:node]) {
        [self.searchableIndex indexSearchableItems:@[[self spotlightSearchableItemForNode:node downloadThumbnail:NO]] completionHandler:^(NSError *error){
            if (error) {
                MEGALogError(@"[Spotlight] indexing error %@", error);
            } else {
                success = YES;
            }
            dispatch_semaphore_signal(sem);
        }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        return success;
    } else {
        return [self removeFromIndex:node.base64Handle];
    }
}

- (BOOL)removeFromIndex:(NSString *)base64Handle {
    if (!base64Handle) {
        return NO;
    }
    
    __block BOOL success = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    [self.searchableIndex deleteSearchableItemsWithIdentifiers:@[base64Handle] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Spotlight] indexing error %@", error);
        } else {
            success = YES;
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
    
    if (node.isFile) {
        NSString *extendedDescription = [Helper memoryStyleStringFromByteCount:node.size.longLongValue];
        attributeSet.contentDescription = [NSString stringWithFormat:@"%@\n%@", path, extendedDescription];
    } else {
        attributeSet.contentDescription = path;
    }
    
    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if (node.hasThumbnail && [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
        attributeSet.thumbnailURL = [NSURL fileURLWithPath:thumbnailFilePath];
    } else {
        if (node.hasThumbnail && downloadThumbnail) {
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
            attributeSet.thumbnailURL = [NSURL fileURLWithPath:thumbnailFilePath];
        } else {
            if (node.isFile && self.genericFileThumbnail) {
                attributeSet.thumbnailData = UIImagePNGRepresentation(self.genericFileThumbnail);
            } else if (self.genericFolderThumbnail) {
                attributeSet.thumbnailData = UIImagePNGRepresentation(self.genericFolderThumbnail);
            }
        }
    }
    
    CSSearchableItem *searchableItem = [[CSSearchableItem alloc] initWithUniqueIdentifier:node.base64Handle domainIdentifier:@"nodes" attributeSet:attributeSet];
    return searchableItem;
}

#pragma mark - MEGATreeProcessorDelegate

- (BOOL)processMEGANode:(MEGANode *)node {
    static unsigned int processed = 0;
    [self.base64HandlesToIndex addObject:node.base64Handle];
    if (node.isFile && [[MEGASdkManager sharedMEGASdk] hasVersionsForNode:node]) {
        processed += [[MEGASdkManager sharedMEGASdk] versionsForNode:node].size.unsignedIntegerValue;
    } else {
        processed++;
    }
    if (processed == self.totalNodes) {
        processed = 0;
        dispatch_semaphore_signal(self.semaphore);
        return NO;
    }
    return YES;
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (!nodeList) {
        return;
    }
    
    if (self.shouldStop) {
        return;
    }
    
    [self.indexSerialQueue addOperationWithBlock:^{
        NSArray<MEGANode *> *nodesToIndex = [nodeList mnz_nodesArrayFromNodeList];
        MEGALogDebug(@"Spotlight indexing %tu nodes updated", nodesToIndex.count);
        for (MEGANode *node in nodesToIndex) {
            if (self.shouldStop) {
                break;
            }
            
            [self index:node];
        }
    }];
}


@end
