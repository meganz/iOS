#import "Helper.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "NSFileManager+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "MEGACopyRequestDelegate.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGAGenericRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAProcessAsset.h"
#import "MEGALogger.h"
#import "MEGASdkManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGAUser+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

#import "NodeTableViewCell.h"
#import "PhotoCollectionViewCell.h"

static MEGAIndexer *indexer;

@implementation Helper

#pragma mark - Images

+ (NSDictionary *)fileTypesDictionary {
    static NSDictionary *fileTypesDictionary = nil;
    
    if (fileTypesDictionary == nil) {
        fileTypesDictionary = @{@"3ds":@"3d",
                                @"3dm":@"3d",
                                @"3fr":@"raw",
                                @"3g2":@"video",
                                @"3ga":@"audio",
                                @"3gp":@"video",
                                @"7z":@"compressed",
                                @"aac":@"audio",
                                @"abr":@"photoshop",
                                @"ac3":@"audio",
                                @"accdb":@"web_lang",
                                @"aep":@"after_effects",
                                @"aet":@"after_effects",
                                @"ai":@"illustrator",
                                @"aif":@"audio",
                                @"aiff":@"audio",
                                @"ait":@"illustrator",
                                @"ans":@"text",
                                @"apk":@"executable",
                                @"app":@"executable",
                                @"arw":@"raw",
                                @"ascii":@"text",
                                @"asf":@"video",
                                @"asp":@"web_lang",
                                @"aspx":@"web_lang",
                                @"avi":@"video",
                                @"bay":@"raw",
                                @"bin":@"executable",
                                @"bmp":@"image",
                                @"bz2":@"compressed",
                                @"c":@"web_lang",
                                @"cc":@"web_lang",
                                @"cdr":@"vector",
                                @"cgi":@"web_lang",
                                @"class":@"web_data",
                                @"com":@"executable",
                                @"cmd":@"executable",
                                @"cpp":@"web_lang",
                                @"cr2":@"raw",
                                @"css":@"web_data",
                                @"cxx":@"web_lang",
                                @"dcr":@"raw",
                                @"db":@"web_lang",
                                @"dbf":@"web_lang",
                                @"dhtml":@"web_data",
                                @"dll":@"web_lang",
                                @"dng":@"raw",
                                @"doc":@"word",
                                @"docx":@"word",
                                @"dotx":@"word",
                                @"dwg":@"cad",
                                @"dxf":@"cad",
                                @"dmg":@"dmg",
                                @"eac3":@"audio",
                                @"ec3":@"audio",
                                @"eps":@"vector",
                                @"exe":@"executable",
                                @"fff":@"raw",
                                @"flac":@"audio",
                                @"fnt":@"font",
                                @"fon":@"font",
                                @"gadget":@"executable",
                                @"gif":@"image",
                                @"gsheet":@"spreadsheet",
                                @"gz":@"compressed",
                                @"h":@"web_lang",
                                @"html":@"web_data",
                                @"heic":@"image",
                                @"hpp":@"web_lang",
                                @"iff":@"audio",
                                @"inc":@"web_lang",
                                @"indd":@"indesign",
                                @"jar":@"web_data",
                                @"java":@"web_data",
                                @"jpeg":@"image",
                                @"jpg":@"image",
                                @"js":@"web_data",
                                @"key":@"keynote",
                                @"log":@"text",
                                @"m":@"web_lang",
                                @"mm":@"web_lang",
                                @"m4v":@"video",
                                @"m4a":@"audio",
                                @"max":@"3d",
                                @"mdb":@"web_lang",
                                @"mef":@"raw",
                                @"mid":@"audio",
                                @"midi":@"audio",
                                @"mkv":@"video",
                                @"mov":@"video",
                                @"mp3":@"audio",
                                @"mp4":@"video",
                                @"mpeg":@"video",
                                @"mpg":@"video",
                                @"mrw":@"raw",
                                @"msi":@"executable",
                                @"nb":@"spreadsheet",
                                @"numbers":@"numbers",
                                @"nef":@"raw",
                                @"obj":@"3d",
                                @"odp":@"generic",
                                @"ods":@"spreadsheet",
                                @"odt":@"openoffice",
                                @"ogv":@"video",
                                @"otf":@"font",
                                @"ots":@"spreadsheet",
                                @"orf":@"raw",
                                @"pages":@"pages",
                                @"pdb":@"web_lang",
                                @"pdf":@"pdf",
                                @"pef":@"raw",
                                @"php":@"web_lang",
                                @"php3":@"web_lang",
                                @"php4":@"web_lang",
                                @"php5":@"web_lang",
                                @"phtml":@"web_lang",
                                @"pl":@"web_lang",
                                @"png":@"image",
                                @"ppj":@"premiere",
                                @"pps":@"powerpoint",
                                @"ppt":@"powerpoint",
                                @"pptx":@"powerpoint",
                                @"prproj":@"premiere",
                                @"psb":@"photoshop",
                                @"psd":@"photoshop",
                                @"py":@"web_lang",
                                @"rar":@"compressed",
                                @"rtf":@"text",
                                @"rw2":@"raw",
                                @"rwl":@"raw",
                                @"sh":@"web_lang",
                                @"shtml":@"web_data",
                                @"sitx":@"compressed",
                                @"sketch":@"sketch",
                                @"sql":@"web_lang",
                                @"srf":@"raw",
                                @"srt":@"text",
                                @"svg":@"vector",
                                @"svgz":@"vector",
                                @"tar":@"compressed",
                                @"tbz":@"compressed",
                                @"tga":@"image",
                                @"tgz":@"compressed",
                                @"tif":@"image",
                                @"tiff":@"image",
                                @"torrent":@"torrent",
                                @"ttf":@"font",
                                @"txt":@"text",
                                @"url":@"url",
                                @"vob":@"video",
                                @"wav":@"audio",
                                @"webm":@"video",
                                @"wma":@"audio",
                                @"wmv":@"video",
                                @"wpd":@"text",
                                @"wps":@"word",
                                @"Xd":@"experiencedesign",
                                @"xlr":@"spreadsheet",
                                @"xls":@"excel",
                                @"xlsx":@"excel",
                                @"xlt":@"excel",
                                @"xltm":@"excel",
                                @"xml":@"web_data",
                                @"zip":@"compressed"};
    }
    
    return fileTypesDictionary;
}

#pragma mark - Paths

+ (NSString *)pathForOffline {
    static NSString *pathString = nil;
    
    if (pathString == nil) {
        pathString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        pathString = [pathString stringByAppendingString:@"/"];
    }
    
    return pathString;
}

+ (NSString *)relativePathForOffline {
    static NSString *pathString = nil;
    
    if (pathString == nil) {
        pathString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        pathString = [pathString lastPathComponent];
    }
    
    return pathString;
}

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath {
    NSRange rangeOfSubstring = [totalPath rangeOfString:[Helper pathForOffline]];
    NSString *relativePath = [totalPath substringFromIndex:rangeOfSubstring.length];
    return relativePath;
}

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory {
    
    NSString *destinationPath = NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [node base64Handle];
    NSString *destinationFilePath = nil;
    destinationFilePath = [directory isEqualToString:@""] ? [destinationPath stringByAppendingPathComponent:fileName]
    :[[destinationPath stringByAppendingPathComponent:directory] stringByAppendingPathComponent:fileName];
    
    return destinationFilePath;
}

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path {
    return [self pathForNode:node searchPath:path directory:@""];
}

+ (NSString *)pathForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory {
    return [self pathForHandle:node.base64Handle inSharedSandboxCacheDirectory:directory];
}

+ (NSString *)pathWithOriginalNameForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory {
    NSString *folderParentPath = [self pathForHandle:node.base64Handle inSharedSandboxCacheDirectory:directory];
    if (![NSFileManager.defaultManager fileExistsAtPath:folderParentPath isDirectory:nil]) {
        NSError *error;
        if (![NSFileManager.defaultManager createDirectoryAtPath:folderParentPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }

    return [folderParentPath stringByAppendingPathComponent:node.name];
}

+ (NSString *)pathForHandle:(NSString *)base64Handle inSharedSandboxCacheDirectory:(NSString *)directory {
    NSString *destinationPath = [Helper pathForSharedSandboxCacheDirectory:directory];
    return [destinationPath stringByAppendingPathComponent:base64Handle];
}

+ (NSString *)pathForSharedSandboxCacheDirectory:(NSString *)directory {
    return [[self urlForSharedSandboxCacheDirectory:directory] path];
}

+ (NSURL *)urlForSharedSandboxCacheDirectory:(NSString *)directory {
    NSURL *containerURL = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier];
    NSURL *destinationURL = [[containerURL URLByAppendingPathComponent:MEGAExtensionCacheFolder isDirectory:YES] URLByAppendingPathComponent:directory isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:destinationURL withIntermediateDirectories:YES attributes:nil error:nil];
    return destinationURL;
}

#pragma mark - Utils for transfers

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink {
    NSNumber *nodeSizeNumber;
    
    if ([node type] == MEGANodeTypeFile) {
        nodeSizeNumber = [node size];
    } else if ([node type] == MEGANodeTypeFolder) {
        if (isFolderLink) {
            nodeSizeNumber = [[MEGASdkManager sharedMEGASdkFolder] sizeForNode:node];
        } else {
            nodeSizeNumber = [[MEGASdkManager sharedMEGASdk] sizeForNode:node];
        }
    }
    
    NSError *error;
    uint64_t freeSpace = [NSFileManager.defaultManager mnz_fileSystemFreeSizeWithError:error];
    if (error) {
        return YES;
    }
    
    if (freeSpace < [nodeSizeNumber longLongValue]) {
#ifdef MAIN_APP_TARGET
        dispatch_async(dispatch_get_main_queue(), ^{
            StorageFullModalAlertViewController *warningVC = StorageFullModalAlertViewController.alloc.init;
            [warningVC showWithRequiredStorage:nodeSizeNumber.longLongValue];
        });
#endif
        return NO;
    }
    return YES;
}

+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink {
    [self downloadNode:node folderPath:folderPath isFolderLink:isFolderLink isTopPriority:NO];
}

+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink isTopPriority:(BOOL)isTopPriority {
    // Can't create Inbox folder on documents folder, Inbox is reserved for use by Apple
    if ([node.name isEqualToString:@"Inbox"] && [folderPath isEqualToString:[self relativePathForOffline]]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"folderInboxError", nil)];
        return;
    }
    
    MEGASdk *api;
    if (isFolderLink) {
        api = [MEGASdkManager sharedMEGASdkFolder];
        node = [api authorizeNode:node];
    } else {
        api = [MEGASdkManager sharedMEGASdk];
    }
    
    NSString *offlineNameString = [api escapeFsIncompatible:node.name destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
    NSString *relativeFilePath = [folderPath stringByAppendingPathComponent:offlineNameString];
    if (isTopPriority) {
        [MEGASdkManager.sharedMEGASdk startDownloadTopPriorityWithNode:node localPath:relativeFilePath appData:nil];
    } else {
        [MEGASdkManager.sharedMEGASdk startDownloadNode:node localPath:relativeFilePath];
    }
}

+ (void)downloadNodeTopPriority:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink {
    [self downloadNode:node folderPath:folderPath isFolderLink:isFolderLink isTopPriority:YES];
}

+ (void)copyNode:(MEGANode *)node from:(NSString *)itemPath to:(NSString *)relativeFilePath api:(MEGASdk *)api {
    NSRange replaceRange = [relativeFilePath rangeOfString:@"Documents/"];
    if (replaceRange.location != NSNotFound) {
        NSString *result = [relativeFilePath stringByReplacingCharactersInRange:replaceRange withString:@""];
        NSError *error;
        if ([[NSFileManager defaultManager] copyItemAtPath:itemPath toPath:[NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath] error:&error]) {
            [[MEGAStore shareInstance] insertOfflineNode:node api:api path:result.decomposedStringWithCanonicalMapping];
        } else {
            MEGALogError(@"Failed to copy from %@ to %@ with error: %@", itemPath, relativeFilePath, error);
        }
    }
}

+ (void)moveNode:(MEGANode *)node from:(NSString *)itemPath to:(NSString *)relativeFilePath api:(MEGASdk *)api {
    NSRange replaceRange = [relativeFilePath rangeOfString:@"Documents/"];
    if (replaceRange.location != NSNotFound) {
        NSString *result = [relativeFilePath stringByReplacingCharactersInRange:replaceRange withString:@""];
        NSError *error;
        if ([[NSFileManager defaultManager] moveItemAtPath:itemPath toPath:[NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath] error:&error]) {
            [[MEGAStore shareInstance] insertOfflineNode:node api:api path:result.decomposedStringWithCanonicalMapping];
        } else {
            MEGALogError(@"Failed to move from %@ to %@ with error: %@", itemPath, relativeFilePath, error);
        }
    }
}

+ (NSMutableArray *)uploadingNodes {
    static NSMutableArray *uploadingNodes = nil;
    if (!uploadingNodes) {
        uploadingNodes = [[NSMutableArray alloc] init];
    }
    
    return uploadingNodes;
}

+ (void)startUploadTransferWithTransferRecordDTO:(TransferRecordDTO *)transferRecordDTO {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[transferRecordDTO.localIdentifier]
                                                      options:nil].firstObject;
    
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:transferRecordDTO.parentNodeHandle.unsignedLongLongValue];
    
    MEGAProcessAsset *processAsset = [[MEGAProcessAsset alloc] initWithAsset:asset parentNode:parentNode cameraUploads:NO filePath:^(NSString *filePath) {
        NSString *name = filePath.lastPathComponent.mnz_fileNameWithLowercaseExtension;
        NSString *newName = [name mnz_sequentialFileNameInParentNode:parentNode];
        
        NSString *appData = [NSString new];
        
        appData = [appData mnz_appDataToSaveCoordinates:[filePath mnz_coordinatesOfPhotoOrVideo]];
        appData = [appData mnz_appDataToLocalIdentifier:transferRecordDTO.localIdentifier];
        
        if (![name isEqualToString:newName]) {
            NSString *newFilePath = [[NSFileManager defaultManager].uploadsDirectory stringByAppendingPathComponent:newName];
            
            NSError *error = nil;
            NSString *absoluteFilePath = [NSHomeDirectory() stringByAppendingPathComponent:filePath];
            if (![[NSFileManager defaultManager] moveItemAtPath:absoluteFilePath toPath:newFilePath error:&error]) {
                MEGALogError(@"Move item at path failed with error: %@", error);
            }
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newFilePath.mnz_relativeLocalPath parent:parentNode appData:appData isSourceTemporary:NO];
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:filePath.mnz_relativeLocalPath parent:parentNode appData:appData isSourceTemporary:NO];
        }
        
        if (transferRecordDTO.localIdentifier) {
            [[Helper uploadingNodes] addObject:transferRecordDTO.localIdentifier];
        }
        [[MEGAStore shareInstance] deleteUploadTransferWithLocalIdentifier:transferRecordDTO.localIdentifier];
    } error:^(NSError *error) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudError"] status:[NSString stringWithFormat:@"%@ %@ \r %@", NSLocalizedString(@"Transfer failed:", nil), asset.localIdentifier, error.localizedDescription]];
        [[MEGAStore shareInstance] deleteUploadTransferWithLocalIdentifier:transferRecordDTO.localIdentifier];
        [Helper startPendingUploadTransferIfNeeded];
    }];
    
    [processAsset prepare];
}

+ (void)startPendingUploadTransferIfNeeded {
    BOOL allUploadTransfersPaused = YES;
    
    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] uploadTransfers];
    
    for (int i = 0; i < transferList.size.intValue; i++) {
        MEGATransfer *transfer = [transferList transferAtIndex:i];
        
        if (transfer.state == MEGATransferStateActive) {
            allUploadTransfersPaused = NO;
            break;
        }
    }
    
    if (allUploadTransfersPaused) {
        TransferRecordDTO *transferRecordDTO = [MEGAStore.shareInstance fetchUploadTransfers].firstObject;
        if (transferRecordDTO != nil) {
            [self startUploadTransferWithTransferRecordDTO:transferRecordDTO];
        }
    }
}

#pragma mark - Utils

+ (void)saveSortOrder:(MEGASortOrderType)selectedSortOrderType for:(_Nullable id)object {
    SortingPreference sortingPreference = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreference];

    if (object && sortingPreference == SortingPreferencePerFolder) {
        MEGASortOrderType currentSortOrderType = [Helper sortTypeFor:object];
        
        if (currentSortOrderType == selectedSortOrderType) {
            return;
        }
        
        if ([object isKindOfClass:MEGANode.class]) {
            MEGANode *node = (MEGANode *)object;
            [MEGAStore.shareInstance insertOrUpdateCloudSortTypeWithHandle:node.handle sortType:selectedSortOrderType];
        } else if ([object isKindOfClass:NSString.class]) {
            NSString *offlinePath = (NSString *)object;
            [MEGAStore.shareInstance insertOrUpdateOfflineSortTypeWithPath:offlinePath sortType:selectedSortOrderType];
        }
                
        [NSNotificationCenter.defaultCenter postNotificationName:MEGASortingPreference object:self userInfo:@{MEGASortingPreference : @(sortingPreference), MEGASortingPreferenceType : @(selectedSortOrderType)}];
    } else {
        [NSUserDefaults.standardUserDefaults setInteger:SortingPreferenceSameForAll forKey:MEGASortingPreference];
        [NSUserDefaults.standardUserDefaults setInteger:selectedSortOrderType forKey:MEGASortingPreferenceType];
        
        [NSNotificationCenter.defaultCenter postNotificationName:MEGASortingPreference object:self userInfo:@{MEGASortingPreference : @(SortingPreferenceSameForAll), MEGASortingPreferenceType : @(selectedSortOrderType)}];
    }
}

+ (MEGASortOrderType)sortTypeFor:(_Nullable id)object {
    MEGASortOrderType sortType;
    SortingPreference sortingPreference = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreference];
    if (object) {
        if (sortingPreference == SortingPreferencePerFolder) {
            if ([object isKindOfClass:MEGANode.class]) {
                MEGANode *node = (MEGANode *)object;
                CloudAppearancePreference *cloudAppearancePreference = [MEGAStore.shareInstance fetchCloudAppearancePreferenceWithHandle:node.handle];
                sortType = cloudAppearancePreference ? cloudAppearancePreference.sortType.integerValue : MEGASortOrderTypeDefaultAsc;
            } else if ([object isKindOfClass:NSString.class]) {
                NSString *offlinePath = (NSString *)object;
                OfflineAppearancePreference *offlineAppearancePreference = [MEGAStore.shareInstance fetchOfflineAppearancePreferenceWithPath:offlinePath];
                sortType = offlineAppearancePreference ? offlineAppearancePreference.sortType.integerValue : MEGASortOrderTypeDefaultAsc;
            } else {
                sortType = MEGASortOrderTypeDefaultAsc;
            }
        } else {
            MEGASortOrderType currentSortType = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreferenceType];
            sortType = currentSortType ? currentSortType : Helper.defaultSortType;
        }
    } else {
        MEGASortOrderType currentSortType = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreferenceType];
        sortType = currentSortType ? currentSortType : Helper.defaultSortType;
    }
    
    return sortType;
}

+ (MEGASortOrderType)defaultSortType {
    [NSUserDefaults.standardUserDefaults setInteger:MEGASortOrderTypeDefaultAsc forKey:MEGASortingPreferenceType];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    return MEGASortOrderTypeDefaultAsc;
}

+ (NSString *)memoryStyleStringFromByteCount:(long long)byteCount {
    static NSByteCountFormatter *byteCountFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        byteCountFormatter = NSByteCountFormatter.alloc.init;
        byteCountFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
    });
    
    return [byteCountFormatter stringFromByteCount:byteCount];
}

+ (void)changeApiURL {
    NSString *alertTitle = NSLocalizedString(@"Change to a test server?", @"title of the alert dialog when the user is changing the API URL to staging");
    NSString *alertMessage = NSLocalizedString(@"Are you sure you want to change to a test server? Your account may suffer irrecoverable problems", @"text of the alert dialog when the user is changing the API URL to staging");
    
    UIAlertController *changeApiServerAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Production", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Helper setApiURL:MEGAAPIEnvProduction];
        [Helper apiURLChanged];
    }]];
    
    [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"staging", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Helper setApiURL:MEGAAPIEnvStaging];
        [Helper apiURLChanged];
    }]];
    
    [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:@"Staging:444" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Helper setApiURL:MEGAAPIEnvStaging444];
        [Helper apiURLChanged];
    }]];
    
    [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:@"Sandbox3" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Helper setApiURL:MEGAAPIEnvSandbox3];
        [Helper apiURLChanged];
    }]];
    
    [UIApplication.mnz_visibleViewController presentViewController:changeApiServerAlertController animated:YES completion:nil];
}

+ (void)setApiURL:(MEGAAPIEnv)envType {
    switch (envType) {
        case MEGAAPIEnvProduction:
            [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://g.api.mega.co.nz/" disablepkp:NO];
            [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://g.api.mega.co.nz/" disablepkp:NO];
            break;
        case MEGAAPIEnvStaging:
            [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
            [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
            break;
        case MEGAAPIEnvStaging444:
            [MEGASdkManager.sharedMEGASdk changeApiUrl:@"https://staging.api.mega.co.nz:444/" disablepkp:YES];
            [MEGASdkManager.sharedMEGASdkFolder changeApiUrl:@"https://staging.api.mega.co.nz:444/" disablepkp:YES];
            break;
        case MEGAAPIEnvSandbox3:
            [MEGASdkManager.sharedMEGASdk changeApiUrl:@"https://api-sandbox3.developers.mega.co.nz/" disablepkp:YES];
            [MEGASdkManager.sharedMEGASdkFolder changeApiUrl:@"https://api-sandbox3.developers.mega.co.nz/" disablepkp:YES];
            break;
            
        default:
            break;
    }
    [NSUserDefaults.standardUserDefaults setInteger:envType forKey:@"MEGAAPIEnv"];
}

+ (void)apiURLChanged {
    [SVProgressHUD showSuccessWithStatus:@"API URL changed"];
    
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:[SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]];
        [[MEGASdkManager sharedMEGAChatSdk] refreshUrls];
    }
}

+ (void)restoreAPISetting {
    MEGAAPIEnv APItype = [NSUserDefaults.standardUserDefaults integerForKey:@"MEGAAPIEnv"];
    [Helper setApiURL:APItype];
}

+ (void)cannotPlayContentDuringACallAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"It is not possible to play content while there is a call in progress", @"Message shown when there is an ongoing call and the user tries to play an audio or video") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
}

+ (UIAlertController *)removeUserContactFromSender:(UIView *)sender withConfirmAction:(void (^)(void))confirmAction {

    UIAlertController *removeContactAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [removeContactAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];

    [removeContactAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        confirmAction();
    }]];

    removeContactAlertController.popoverPresentationController.sourceView = sender;
    removeContactAlertController.popoverPresentationController.sourceRect = sender.bounds;
    
    return removeContactAlertController;
}

#pragma mark - Utils for nodes

+ (void)thumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell {
    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
        [Helper setThumbnailForNode:node api:api cell:cell reindexNode:NO];
    } else {
        [api getThumbnailNode:node destinationFilePath:thumbnailFilePath];
        if ([cell isKindOfClass:[NodeTableViewCell class]]) {
            NodeTableViewCell *nodeTableViewCell = cell;
            [nodeTableViewCell.thumbnailImageView mnz_imageForNode:node];
        } else if ([cell isKindOfClass:[PhotoCollectionViewCell class]]) {
            PhotoCollectionViewCell *photoCollectionViewCell = cell;
            [photoCollectionViewCell.thumbnailImageView mnz_imageForNode:node];
        }
    }
}

+ (void)setThumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell reindexNode:(BOOL)reindex {
    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([cell isKindOfClass:[NodeTableViewCell class]]) {
        NodeTableViewCell *nodeTableViewCell = cell;
        [nodeTableViewCell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
        nodeTableViewCell.thumbnailPlayImageView.hidden = !node.name.mnz_isVideoPathExtension;
    } else if ([cell isKindOfClass:[PhotoCollectionViewCell class]]) {
        PhotoCollectionViewCell *photoCollectionViewCell = cell;
        [photoCollectionViewCell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
    }
    
    if (reindex) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [indexer index:node];
        });
    }
}

+ (NSString *)sizeAndCreationHourAndMininuteForNode:(MEGANode *)node api:(MEGASdk *)api {
    return [NSString stringWithFormat:@"%@ • %@", [self sizeForNode:node api:api], node.creationTime.mnz_formattedHourAndMinutes];
}

+ (NSString *)sizeAndCreationDateForNode:(MEGANode *)node api:(MEGASdk *)api {
    return [NSString stringWithFormat:@"%@ • %@", [self sizeForNode:node api:api], node.creationTime.mnz_formattedDateMediumTimeShortStyle];
}

+ (NSString *)sizeAndModicationDateForNode:(MEGANode *)node api:(MEGASdk *)api {
    return [NSString stringWithFormat:@"%@ • %@", [self sizeForNode:node api:api], node.modificationTime.mnz_formattedDateMediumTimeShortStyle];
}

+ (NSString *)sizeAndShareLinkCreateDateForSharedLinkNode:(MEGANode *)node api:(MEGASdk *)api {
    return [NSString stringWithFormat:@"%@ • %@", [self sizeForNode:node api:api], node.publicLinkCreationTime.mnz_formattedDateMediumTimeShortStyle];
}

+ (NSString *)sizeForNode:(MEGANode *)node api:(MEGASdk *)api {
    NSString *size;
    if ([node isFile]) {
        size = [Helper memoryStyleStringFromByteCount:node.size.longLongValue];
    } else {
        size = [Helper memoryStyleStringFromByteCount:[api sizeForNode:node].longLongValue];
    }
    return size;
}

+ (NSString *)filesAndFoldersInFolderNode:(MEGANode *)node api:(MEGASdk *)api {
    NSInteger files = [api numberChildFilesForParent:node];
    NSInteger folders = [api numberChildFoldersForParent:node];
    
    return [NSString mnz_stringByFiles:files andFolders:folders];
}

+ (void)importNode:(MEGANode *)node toShareWithCompletion:(void (^)(MEGANode *node))completion {
    if (node.owner == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
        completion(node);
    } else {
        MEGANode *remoteNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:node.fingerprint];
        if (remoteNode && remoteNode.owner == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
            completion(remoteNode);
        } else {
            MEGACopyRequestDelegate *copyRequestDelegate = [[MEGACopyRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                MEGANode *resultNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                completion(resultNode);
            }];
        
            [MyChatFilesFolderNodeAccess.shared loadNodeWithCompletion:^(MEGANode * _Nullable myChatFilesFolderNode, NSError * _Nullable error) {
                if (error || myChatFilesFolderNode == nil) {
                    MEGALogWarning(@"Coud not load MyChatFiles target folder doe tu error %@", error);
                }
                [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:myChatFilesFolderNode delegate:copyRequestDelegate];
            }];
        }
    }
}

+ (void)setIndexer:(MEGAIndexer* )megaIndexer {
    indexer = megaIndexer;
}

#pragma mark - Utils for UI

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    return [self customNavigationBarLabelWithTitle:title subtitle:subtitle color:UIColor.mnz_label];
}

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle color:(UIColor *)color {
    NSMutableAttributedString *titleMutableAttributedString = [NSMutableAttributedString.alloc initWithString:title attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f weight:UIFontWeightSemibold], NSForegroundColorAttributeName:color}];
    
    UIColor *colorWithAlpha = [color colorWithAlphaComponent:0.8];
    if (![subtitle isEqualToString:@""]) {
        subtitle = [NSString stringWithFormat:@"\n%@", subtitle];
        NSMutableAttributedString *subtitleMutableAttributedString = [NSMutableAttributedString.alloc initWithString:subtitle attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:colorWithAlpha}];
        
        [titleMutableAttributedString appendAttributedString:subtitleMutableAttributedString];
    }
    
    UILabel *label = [[UILabel alloc] init];
    [label setNumberOfLines:[subtitle isEqualToString:@""] ? 1 : 2];
    [label setLineBreakMode:NSLineBreakByClipping];
    
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setAttributedText:titleMutableAttributedString];
    
    return label;
}

+ (UISearchController *)customSearchControllerWithSearchResultsUpdaterDelegate:(id<UISearchResultsUpdating>)searchResultsUpdaterDelegate searchBarDelegate:(id<UISearchBarDelegate>)searchBarDelegate {
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = searchResultsUpdaterDelegate;
    searchController.searchBar.delegate = searchBarDelegate;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchController.searchBar.translucent = NO;
    
    return searchController;
}

#pragma mark - Manage session

+ (BOOL)hasSession_alertIfNot {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        return YES;
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"pleaseLogInToYourAccount", @"Alert title shown when you need to log in to continue with the action you want to do") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
}

#pragma mark - Logout

+ (void)logout {
    [NSNotificationCenter.defaultCenter postNotificationName:MEGALogoutNotification object:self];    
    [Helper cancelAllTransfers];
    
    [Helper clearSession];
    
    [Helper deleteUserData];
    [Helper deleteMasterKey];

    [Helper resetUserData];
    
    [Helper deletePasscode];
}

+ (void)logoutFromConfirmAccount {
    [NSNotificationCenter.defaultCenter postNotificationName:MEGALogoutNotification object:self];
    [Helper cancelAllTransfers];
    
    [Helper clearSession];
    
    [Helper deleteUserData];
    [Helper deleteMasterKey];
    
    [Helper resetUserData];
    
    [Helper deletePasscode];
}

+ (void)cancelAllTransfers {
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:0];
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
    
    [[MEGASdkManager sharedMEGASdkFolder] cancelTransfersForDirection:0];
}

+ (void)clearEphemeralSession {
    [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionId"];
    [SAMKeychain deletePasswordForService:@"MEGA" account:@"email"];
    [SAMKeychain deletePasswordForService:@"MEGA" account:@"name"];
    [SAMKeychain deletePasswordForService:@"MEGA" account:@"base64pwkey"];
}

+ (void)clearSession {
    [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
}

+ (void)deleteUserData {
    NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
    [NSFileManager.defaultManager mnz_removeItemAtPath:thumbsDirectory];
    
    NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
    [NSFileManager.defaultManager mnz_removeItemAtPath:previewsDirectory];
    
    // Remove "Inbox" folder return an error. "Inbox" is reserved by Apple
    NSString *offlineDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:offlineDirectory];
    
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:NSTemporaryDirectory()];
    
    // Delete application support directory content
    NSString *applicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationSupportDirectory error:nil]) {
        if ([file containsString:@"MEGACD"] || [file containsString:@"spotlightTree"] || [file containsString:@"Uploads"] || [file containsString:@"Downloads"]) {
            [NSFileManager.defaultManager mnz_removeItemAtPath:[applicationSupportDirectory stringByAppendingPathComponent:file]];
        }
    }
    
    // Delete files saved by extensions
    NSString *extensionGroup = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier].path;
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:extensionGroup];
    
    // Delete Spotlight index
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[@"nodes"] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"Error deleting spotligth index");
        } else {
            MEGALogInfo(@"Spotlight index deleted");
        }
    }];
}

+ (void)deleteMasterKey {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", NSLocalizedString(@"general.security.recoveryKeyFile", @"Name for the recovery key file")]];
    [[NSFileManager defaultManager] mnz_removeItemAtPath:masterKeyFilePath];
}

+ (void)resetUserData {
    [[Helper uploadingNodes] removeAllObjects];
    
    [NSUserDefaults.standardUserDefaults removePersistentDomainForName:NSBundle.mainBundle.bundleIdentifier];

    //Set default values on logout
    [NSUserDefaults.standardUserDefaults setValue:MEGAFirstRunValue forKey:MEGAFirstRun];
    
    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    [sharedUserDefaults removePersistentDomainForName:MEGAGroupIdentifier];
}

+ (void)deletePasscode {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        if (LTHPasscodeViewController.sharedUser.isLockscreenPresent) {
            [LTHPasscodeViewController deletePasscodeAndClose];
        } else {
            [LTHPasscodeViewController deletePasscode];
        }
    }
}

+ (void)showExportMasterKeyInView:(UIViewController *)viewController completion:(void (^ _Nullable)(void))completion {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", NSLocalizedString(@"general.security.recoveryKeyFile", @"Name for the recovery key file")]];
    
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:masterKeyFilePath contents:[[[MEGASdkManager sharedMEGASdk] masterKey] dataUsingEncoding:NSUTF8StringEncoding] attributes:@{NSFileProtectionKey:NSFileProtectionComplete}];
    if (success) {
        UIAlertController *recoveryKeyAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"masterKeyExported", @"Alert title shown when you have exported your MEGA Recovery Key") message:NSLocalizedString(@"masterKeyExported_alertMessage", @"The Recovery Key has been exported into the Offline section as MEGA-RECOVERYKEY.txt. Note: It will be deleted if you log out, please store it in a safe place.")  preferredStyle:UIAlertControllerStyleAlert];
        [recoveryKeyAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGASdk] masterKeyExported];
            [viewController dismissViewControllerAnimated:YES completion:^{
                if (completion) {
                    completion();
                }
            }];
        }]];
        
        [viewController presentViewController:recoveryKeyAlertController animated:YES completion:nil];
    }
}

+ (void)showMasterKeyCopiedAlert {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [[MEGASdkManager sharedMEGASdk] masterKey];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"recoveryKeyCopiedToClipboard", @"Title of the dialog displayed when copy the user's Recovery Key to the clipboard to be saved or exported - (String as short as possible).") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    
    [[MEGASdkManager sharedMEGASdk] masterKeyExported];
}

#pragma mark - Log

+ (void)enableOrDisableLog {
    BOOL enableLog = ![[NSUserDefaults standardUserDefaults] boolForKey:@"logging"];
    NSString *alertTitle = enableLog ? NSLocalizedString(@"enableDebugMode_title", @"Alert title shown when the DEBUG mode is enabled") :NSLocalizedString(@"disableDebugMode_title", @"Alert title shown when the DEBUG mode is disabled");
    NSString *alertMessage = enableLog ? NSLocalizedString(@"enableDebugMode_message", @"Alert message shown when the DEBUG mode is enabled") :NSLocalizedString(@"disableDebugMode_message", @"Alert message shown when the DEBUG mode is disabled");
    
    UIAlertController *logAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    [logAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [logAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (enableLog) {
#if MAIN_APP_TARGET
            [MEGAChatSdk setLogObject:Logger.shared];
#endif
            [[MEGALogger sharedLogger] preparingForLogging];
        } else {
            [[MEGALogger sharedLogger] stopLogging];
            
#if MAIN_APP_TARGET
            [MEGAChatSdk setLogObject:nil];
            [Logger.shared removeLogsDirectory];
#endif
        }
    }]];
    
    [UIApplication.mnz_presentingViewController presentViewController:logAlertController animated:YES completion:nil];
}

@end
