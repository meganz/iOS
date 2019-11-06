#import "Helper.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "MEGAActivityItemProvider.h"
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

#import "GetLinkActivity.h"
#import "NodeTableViewCell.h"
#import "OpenInActivity.h"
#import "PhotoCollectionViewCell.h"
#import "RemoveLinkActivity.h"
#import "RemoveSharingActivity.h"
#import "ShareFolderActivity.h"
#import "SendToChatActivity.h"

static MEGAIndexer *indexer;

@implementation Helper

#pragma mark - Languages

+ (NSArray *)languagesSupportedIDs {
    static NSArray *languagesSupportedIDs = nil;
    
    if (languagesSupportedIDs == nil) {
        languagesSupportedIDs = [NSArray arrayWithObjects:@"ar",
                                 @"de",
                                 @"en",
                                 @"es",
                                 @"fr",
                                 @"id",
                                 @"it",
                                 @"ja",
                                 @"ko",
                                 @"nl",
                                 @"pl",
                                 @"pt-br",
                                 @"ro",
                                 @"ru",
                                 @"th",
                                 @"tl",
                                 @"uk",
                                 @"vi",
                                 @"zh-Hans",
                                 @"zh-Hant",
                                 nil];
    }
    
    return languagesSupportedIDs;
}

+ (BOOL)isLanguageSupported:(NSString *)languageID {
    BOOL isLanguageSupported = [self.languagesSupportedIDs containsObject:languageID];
    if (isLanguageSupported) {
        [[MEGASdkManager sharedMEGASdk] setLanguageCode:languageID];
    }
    return isLanguageSupported;
}

+ (NSString *)languageID:(NSUInteger)index {
    return [self.languagesSupportedIDs objectAtIndex:index];
}

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

+ (UIImage *)genericImage {
    static UIImage *genericImage = nil;
    
    if (genericImage == nil) {
        genericImage = [UIImage imageNamed:@"generic"];
    }
    return genericImage;
}

+ (UIImage *)folderImage {
    static UIImage *folderImage = nil;
    
    if (folderImage == nil) {
        folderImage = [UIImage imageNamed:@"folder"];
    }
    return folderImage;
}

+ (UIImage *)incomingFolderImage {
    static UIImage *incomingFolderImage = nil;
    
    if (incomingFolderImage == nil) {
        incomingFolderImage = [UIImage imageNamed:@"folder_incoming"];
    }
    return incomingFolderImage;
}

+ (UIImage *)outgoingFolderImage {
    static UIImage *outgoingFolderImage = nil;
    
    if (outgoingFolderImage == nil) {
        outgoingFolderImage = [UIImage imageNamed:@"folder_outgoing"];
    }
    return outgoingFolderImage;
}

+ (UIImage *)folderCameraUploadsImage {
    static UIImage *folderCameraUploadsImage = nil;
    
    if (folderCameraUploadsImage == nil) {
        folderCameraUploadsImage = [UIImage imageNamed:@"folder_image"];
    }
    return folderCameraUploadsImage;
}

+ (UIImage *)defaultPhotoImage {
    static UIImage *defaultPhotoImage = nil;
    
    if (defaultPhotoImage == nil) {
        defaultPhotoImage = [UIImage imageNamed:@"image"];
    }
    return defaultPhotoImage;
}

+ (UIImage *)downloadedArrowImage {
    static UIImage *downloadedArrowImage = nil;
    
    if (downloadedArrowImage == nil) {
        downloadedArrowImage = [UIImage imageNamed:@"downloadedArrow"];
    }
    return downloadedArrowImage;
}

+ (UIImage *)downloadingTransferImage {
    static UIImage *downloadingTransferImage = nil;
    
    if (downloadingTransferImage == nil) {
        downloadingTransferImage = [UIImage imageNamed:@"downloading"];
    }
    return downloadingTransferImage;
}

+ (UIImage *)uploadingTransferImage {
    static UIImage *uploadingTransferImage = nil;
    
    if (uploadingTransferImage == nil) {
        uploadingTransferImage = [UIImage imageNamed:@"uploading"];
    }
    return uploadingTransferImage;
}

+ (UIImage *)downloadQueuedTransferImage {
    static UIImage *downloadQueuedTransferImage = nil;
    
    if (downloadQueuedTransferImage == nil) {
        downloadQueuedTransferImage = [UIImage imageNamed:@"downloadQueued"];
    }
    return downloadQueuedTransferImage;
}

+ (UIImage *)uploadQueuedTransferImage {
    static UIImage *uploadQueuedTransferImage = nil;
    
    if (uploadQueuedTransferImage == nil) {
        uploadQueuedTransferImage = [UIImage imageNamed:@"uploadQueued"];
    }
    return uploadQueuedTransferImage;
}

+ (UIImage *)permissionsButtonImageForShareType:(MEGAShareType)shareType {
    UIImage *image;
    switch (shareType) {
        case MEGAShareTypeAccessRead:
            image = [UIImage imageNamed:@"readPermissions"];
            break;
            
        case MEGAShareTypeAccessReadWrite:
            image =  [UIImage imageNamed:@"readWritePermissions"];
            break;
            
        case MEGAShareTypeAccessFull:
            image = [UIImage imageNamed:@"fullAccessPermissions"];
            break;
            
        default:
            image = nil;
            break;
    }
    
    return image;
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
    NSString *destinationPath = [Helper pathForSharedSandboxCacheDirectory:directory];
    return [destinationPath stringByAppendingPathComponent:[node base64Handle]];
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

+ (NSMutableDictionary *)downloadingNodes {
    static NSMutableDictionary *downloadingNodes = nil;
    if (!downloadingNodes) {
        downloadingNodes = [[NSMutableDictionary alloc] init];
    }
    return downloadingNodes;
}

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
    
    if ([nodeSizeNumber longLongValue] == 0) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emptyFolderMessage", @"Message fon an alert when the user tries download an empty folder")];
        return NO;
    }
    
    NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
    if ([freeSizeNumber longLongValue] < [nodeSizeNumber longLongValue]) {
        UIAlertController *alertController;
        
        if ([node type] == MEGANodeTypeFile) {
            alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something") message:AMLocalizedString(@"fileTooBigMessage", @"The file you are trying to download is bigger than the avaliable memory.") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        } else if ([node type] == MEGANodeTypeFolder) {
            alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something") message:AMLocalizedString(@"folderTooBigMessage", @"The folder you are trying to download is bigger than the avaliable memory.") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        }
        
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    return YES;
}

+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink shouldOverwrite:(BOOL)overwrite {
    MEGASdk *api;
    
    // Can't create Inbox folder on documents folder, Inbox is reserved for use by Apple
    if ([node.name isEqualToString:@"Inbox"] && [folderPath isEqualToString:[self relativePathForOffline]]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"folderInboxError", nil)];
        return;
    }
    
    if (isFolderLink) {
        api = [MEGASdkManager sharedMEGASdkFolder];
    } else {
        api = [MEGASdkManager sharedMEGASdk];
    }
    
    NSString *offlineNameString = [api escapeFsIncompatible:node.name];
    NSString *relativeFilePath = [folderPath stringByAppendingPathComponent:offlineNameString];
    
    if (node.type == MEGANodeTypeFile) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath]] || overwrite) {
            if (overwrite) { //For node versions
                [NSFileManager.defaultManager mnz_removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath]];
                MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:offlineNameString];
                if (offlineNode) {
                    [[MEGAStore shareInstance] removeOfflineNode:offlineNode];
                }
            }
            MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node];
            
            NSString *temporaryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:[node base64Handle]] stringByAppendingPathComponent:node.name];
            NSString *temporaryFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:temporaryPath];
            
            if (offlineNodeExist) {
                NSString *itemPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
                [Helper copyNode:node from:itemPath to:relativeFilePath api:api];
            } else if ([temporaryFingerprint isEqualToString:node.fingerprint]) {
                if ((node.name.mnz_isImagePathExtension && [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"]) || (node.name.mnz_isVideoPathExtension && [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"])) {
                    [node mnz_copyToGalleryFromTemporaryPath:temporaryPath];
                } else {
                    [Helper moveNode:node from:temporaryPath to:relativeFilePath api:api];
                }
            } else {
                NSString *appData = nil;
                if ((node.name.mnz_isImagePathExtension && [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"]) || (node.name.mnz_isVideoPathExtension && [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"])) {
                    NSString *downloadsDirectory = [[NSFileManager defaultManager] downloadsDirectory];
                    downloadsDirectory = downloadsDirectory.mnz_relativeLocalPath;
                    relativeFilePath = [downloadsDirectory stringByAppendingPathComponent:offlineNameString];
                    
                    appData = [[NSString new] mnz_appDataToSaveInPhotosApp];
                }
                [[MEGASdkManager sharedMEGASdk] startDownloadNode:[api authorizeNode:node] localPath:relativeFilePath appData:appData];
            }
        }
    } else if (node.type == MEGANodeTypeFolder && [[api sizeForNode:node] longLongValue] != 0) {
        NSString *absoluteFilePath = [NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:absoluteFilePath]) {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:absoluteFilePath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error != nil) {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:[NSString stringWithFormat:AMLocalizedString(@"folderCreationError", nil), absoluteFilePath]];
            }
        }
        MEGANodeList *nList = [api childrenForParent:node];
        for (NSInteger i = 0; i < nList.size.integerValue; i++) {
            MEGANode *child = [nList nodeAtIndex:i];
            [self downloadNode:child folderPath:relativeFilePath isFolderLink:isFolderLink shouldOverwrite:overwrite];
        }
    }
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

+ (void)startUploadTransfer:(MOUploadTransfer *)uploadTransfer {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[uploadTransfer.localIdentifier] options:nil].firstObject;
    
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:uploadTransfer.parentNodeHandle.unsignedLongLongValue];
    MEGAProcessAsset *processAsset = [[MEGAProcessAsset alloc] initWithAsset:asset parentNode:parentNode cameraUploads:NO filePath:^(NSString *filePath) {
        NSString *name = filePath.lastPathComponent.mnz_fileNameWithLowercaseExtension;
        NSString *newName = [name mnz_sequentialFileNameInParentNode:parentNode];
        
        NSString *appData = [NSString new];
        
        appData = [appData mnz_appDataToSaveCoordinates:[filePath mnz_coordinatesOfPhotoOrVideo]];
        appData = [appData mnz_appDataToLocalIdentifier:uploadTransfer.localIdentifier];
        
        if (![name isEqualToString:newName]) {
            NSString *newFilePath = [[NSFileManager defaultManager].uploadsDirectory stringByAppendingPathComponent:newName];
            
            NSError *error = nil;
            NSString *absoluteFilePath = [NSHomeDirectory() stringByAppendingPathComponent:filePath];
            if (![[NSFileManager defaultManager] moveItemAtPath:absoluteFilePath toPath:newFilePath error:&error]) {
                MEGALogError(@"Move item at path failed with error: %@", error);
            }
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newFilePath.mnz_relativeLocalPath parent:parentNode appData:appData isSourceTemporary:YES];
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:filePath.mnz_relativeLocalPath parent:parentNode appData:appData isSourceTemporary:YES];
        }
        
        if (uploadTransfer.localIdentifier) {
            [[Helper uploadingNodes] addObject:uploadTransfer.localIdentifier];
        }
        [[MEGAStore shareInstance] deleteUploadTransfer:uploadTransfer];
    } node:^(MEGANode *node) {
        if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:node] handle] == parentNode.handle) {
            MEGALogDebug(@"The asset exists in MEGA in the parent folder");
        } else {
            [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:parentNode];
        }
        [[MEGAStore shareInstance] deleteUploadTransfer:uploadTransfer];
        [Helper startPendingUploadTransferIfNeeded];
    } error:^(NSError *error) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudError"] status:[NSString stringWithFormat:@"%@ %@ \r %@", AMLocalizedString(@"Transfer failed:", nil), asset.localIdentifier, error.localizedDescription]];
        [[MEGAStore shareInstance] deleteUploadTransfer:uploadTransfer];
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
        NSArray<MOUploadTransfer *> *queuedUploadTransfers = [[MEGAStore shareInstance] fetchUploadTransfers];
        if (queuedUploadTransfers.count) {
            [Helper startUploadTransfer:queuedUploadTransfers.firstObject];
        }
    }
}

#pragma mark - Utils

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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pointToStaging"]) {
        [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://g.api.mega.co.nz/" disablepkp:NO];
        [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://g.api.mega.co.nz/" disablepkp:NO];
        [Helper apiURLChanged];
    } else {
        NSString *alertTitle = AMLocalizedString(@"Change to a test server?", @"title of the alert dialog when the user is changing the API URL to staging");
        NSString *alertMessage = AMLocalizedString(@"Are you sure you want to change to a test server? Your account may suffer irrecoverable problems", @"text of the alert dialog when the user is changing the API URL to staging");
        
        UIAlertController *changeApiServerAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
            [[MEGASdkManager sharedMEGASdkFolder] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
            [Helper apiURLChanged];
        }]];
        
        [changeApiServerAlertController addAction:[UIAlertAction actionWithTitle:@"Staging:444" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [MEGASdkManager.sharedMEGASdk changeApiUrl:@"https://staging.api.mega.co.nz:444/" disablepkp:YES];
            [MEGASdkManager.sharedMEGASdkFolder changeApiUrl:@"https://staging.api.mega.co.nz:444/" disablepkp:YES];
            [Helper apiURLChanged];
        }]];
        
        [UIApplication.mnz_visibleViewController presentViewController:changeApiServerAlertController animated:YES completion:nil];
    }
}

+ (void)apiURLChanged {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pointToStaging"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"pointToStaging"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"pointToStaging"];
    }
    
    [SVProgressHUD showSuccessWithStatus:@"API URL changed"];
    
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:[SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]];
        [[MEGASdkManager sharedMEGAChatSdk] refreshUrls];
    }
}

+ (void)cannotPlayContentDuringACallAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:AMLocalizedString(@"It is not possible to play content while there is a call in progress", @"Message shown when there is an ongoing call and the user tries to play an audio or video") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
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

+ (NSString *)sizeAndDateForNode:(MEGANode *)node api:(MEGASdk *)api {
    return [NSString stringWithFormat:@"%@ • %@", [self sizeForNode:node api:api], [self dateWithISO8601FormatOfRawTime:node.creationTime.timeIntervalSince1970]];
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

+ (NSString *)dateWithISO8601FormatOfRawTime:(time_t)rawtime {
    struct tm *timeinfo = localtime(&rawtime);
    char buffer[80];
    strftime(buffer, 80, "%Y-%m-%d %H:%M:%S", timeinfo);
    
    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
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
            [MEGASdkManager.sharedMEGASdk getMyChatFilesFolderWithCompletion:^(MEGANode *myChatFilesNode) {
                [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:myChatFilesNode delegate:copyRequestDelegate];
            }];
        }
    }
}

+ (UIActivityViewController *)activityViewControllerForChatMessages:(NSArray<MEGAChatMessage *> *)messages sender:(id)sender {
    NSUInteger stringCount = 0, fileCount = 0;

    NSMutableArray *activityItemsMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *excludedActivityTypesMutableArray = [[NSMutableArray alloc] initWithArray:@[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]];
    
    NSMutableArray<MEGANode *> *nodes = [[NSMutableArray<MEGANode *> alloc] init];
    
    for (MEGAChatMessage *message in messages) {
        switch (message.type) {
            case MEGAChatMessageTypeNormal:
            case MEGAChatMessageTypeContainsMeta:
                [activityItemsMutableArray addObject:message.content];
                stringCount++;
                
                break;
                
            case MEGAChatMessageTypeContact: {
                for (NSUInteger i = 0; i < message.usersCount; i++) {
                    CNMutableContact *cnMutableContact = [[CNMutableContact alloc] init];
                    
                    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:[message userHandleAtIndex:i]];
                    
                    if (moUser.firstName) {
                        cnMutableContact.givenName = moUser.firstname;
                    }
                    
                    if (moUser.lastname) {
                        cnMutableContact.familyName = moUser.lastname;
                    }
                    
                    if (!moUser.firstName && !moUser.lastname) {
                        cnMutableContact.givenName = [message userNameAtIndex:i];
                    }
                    
                    cnMutableContact.emailAddresses = @[[CNLabeledValue labeledValueWithLabel:CNLabelHome value:[message userEmailAtIndex:i]]];
                    
                    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:[MEGASdk base64HandleForUserHandle:[message userHandleAtIndex:i]]];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
                        UIImage *avatarImage = [UIImage imageWithContentsOfFile:avatarFilePath];
                        cnMutableContact.imageData = UIImageJPEGRepresentation(avatarImage, 1.0f);
                    }
                    NSData *vCardData = [CNContactVCardSerialization dataWithContacts:@[cnMutableContact] error:nil];
                    NSString* vcString = [[NSString alloc] initWithData:vCardData encoding:NSUTF8StringEncoding];
                    NSString* base64Image = [cnMutableContact.imageData base64EncodedStringWithOptions:0];
                    if (base64Image) {
                        NSString* vcardImageString = [[@"PHOTO;TYPE=JPEG;ENCODING=BASE64:" stringByAppendingString:base64Image] stringByAppendingString:@"\n"];
                        vcString = [vcString stringByReplacingOccurrencesOfString:@"END:VCARD" withString:[vcardImageString stringByAppendingString:@"END:VCARD"]];
                    }
                    vCardData = [vcString dataUsingEncoding:NSUTF8StringEncoding];
                    
                    NSString *fullName = [message userNameAtIndex:i];
                    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[fullName stringByAppendingString:@".vcf"]];
                    if ([vCardData writeToFile:tempPath atomically:YES]) {
                        [activityItemsMutableArray addObject:[NSURL fileURLWithPath:tempPath]];
                        fileCount++;
                    }
                }
                
                break;
            }
                
            case MEGAChatMessageTypeAttachment:
            case MEGAChatMessageTypeVoiceClip: {
                MEGANode *node = [message.nodeList mnz_nodesArrayFromNodeList].firstObject;
                MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node];
                if (offlineNodeExist) {
                    NSURL *offlineURL = [NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath]];
                    [activityItemsMutableArray addObject:offlineURL];
                    fileCount++;
                } else {
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    double delayInSeconds = 10.0;
                    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    
                    [self importNode:node toShareWithCompletion:^(MEGANode *node) {
                        [nodes addObject:node];
                        MEGAActivityItemProvider *activityItemProvider = [[MEGAActivityItemProvider alloc] initWithPlaceholderString:node.name node:node];
                        [activityItemsMutableArray addObject:activityItemProvider];
                        dispatch_semaphore_signal(semaphore);
                    }];
                    if (dispatch_semaphore_wait(semaphore, waitTime)) {
                        MEGALogError(@"Semaphore timeout importing message attachment to share");
                        return nil;
                    }
                }

                break;
            }
                
            default:
                break;
        }
    }
    
    if (stringCount == 0 && fileCount < 5 && nodes.count == 0) {
        [excludedActivityTypesMutableArray removeObject:UIActivityTypeSaveToCameraRoll];
    }
    
    if (stringCount == 0 && fileCount == 0 && nodes.count == 1) {
        [excludedActivityTypesMutableArray removeObject:UIActivityTypeAirDrop];
    }
    
    if (stringCount == 0 && fileCount == 0 && nodes.count > 0) {
        GetLinkActivity *getLinkActivity = [[GetLinkActivity alloc] initWithNodes:nodes];
        [activitiesMutableArray addObject:getLinkActivity];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItemsMutableArray applicationActivities:activitiesMutableArray];
    [activityVC setExcludedActivityTypes:excludedActivityTypesMutableArray];
    
    if ([[sender class] isEqual:UIBarButtonItem.class]) {
        activityVC.popoverPresentationController.barButtonItem = sender;
    } else {
        UIView *presentationView = (UIView *)sender;
        activityVC.popoverPresentationController.sourceView = presentationView;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(0, 0, presentationView.frame.size.width/2, presentationView.frame.size.height/2);
    }
    
    return activityVC;
}

+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray sender:(id)sender {
    NSMutableArray *activityItemsMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *excludedActivityTypesMutableArray = [[NSMutableArray alloc] initWithArray:@[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]];
    
    GetLinkActivity *getLinkActivity = [[GetLinkActivity alloc] initWithNodes:nodesArray];
    [activitiesMutableArray addObject:getLinkActivity];
    
    NodesAre nodesAre = [Helper checkPropertiesForSharingNodes:nodesArray];
    
    BOOL allNodesExistInOffline = NO;
    NSMutableArray *filesURLMutableArray;
    if (NodesAreFolders == (nodesAre & NodesAreFolders)) {
        ShareFolderActivity *shareFolderActivity = [[ShareFolderActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:shareFolderActivity];
    } else if (NodesAreFiles == (nodesAre & NodesAreFiles)) {
        filesURLMutableArray = [[NSMutableArray alloc] initWithArray:[Helper checkIfAllOfTheseNodesExistInOffline:nodesArray]];
        if ([filesURLMutableArray count]) {
            allNodesExistInOffline = YES;
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
            SendToChatActivity *sendToChatActivity = [[SendToChatActivity alloc] initWithNodes:nodesArray];
            [activitiesMutableArray addObject:sendToChatActivity];
        }
    }
    
    if (allNodesExistInOffline) {
        for (NSURL *fileURL in filesURLMutableArray) {
            [activityItemsMutableArray addObject:fileURL];
        }
        
        [excludedActivityTypesMutableArray removeObjectsInArray:@[UIActivityTypePrint, UIActivityTypeAirDrop]];
        
        if (nodesArray.count < 5) {
            [excludedActivityTypesMutableArray removeObject:UIActivityTypeSaveToCameraRoll];
        }
        
        if (nodesArray.count == 1) {
            OpenInActivity *openInActivity;
            if ([sender isKindOfClass:[UIBarButtonItem class]]) {
                openInActivity = [[OpenInActivity alloc] initOnBarButtonItem:sender];
            } else {
                openInActivity = [[OpenInActivity alloc] initOnView:sender];
            }
            
            [activitiesMutableArray addObject:openInActivity];
        }
    } else {
        for (MEGANode *node in nodesArray) {
            MEGAActivityItemProvider *activityItemProvider = [[MEGAActivityItemProvider alloc] initWithPlaceholderString:node.name node:node];
            [activityItemsMutableArray addObject:activityItemProvider];
        }
        
        if (nodesArray.count == 1) {
            [excludedActivityTypesMutableArray removeObject:UIActivityTypeAirDrop];
        }
    }
    
    if (NodesAreExported == (nodesAre & NodesAreExported)) {
        RemoveLinkActivity *removeLinkActivity = [[RemoveLinkActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:removeLinkActivity];
    }
    
    if (NodesAreOutShares == (nodesAre & NodesAreOutShares)) {
        RemoveSharingActivity *removeSharingActivity = [[RemoveSharingActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:removeSharingActivity];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItemsMutableArray applicationActivities:activitiesMutableArray];
    [activityVC setExcludedActivityTypes:excludedActivityTypesMutableArray];
    
    if ([[sender class] isEqual:UIBarButtonItem.class]) {
        activityVC.popoverPresentationController.barButtonItem = sender;
    } else {
        UIView *presentationView = (UIView *)sender;
        activityVC.popoverPresentationController.sourceView = presentationView;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(0, 0, presentationView.frame.size.width/2, presentationView.frame.size.height/2);
    }
    
    return activityVC;
}

+ (NodesAre)checkPropertiesForSharingNodes:(NSArray *)nodesArray {
    NSInteger numberOfFolders = 0;
    NSInteger numberOfFiles = 0;
    NSInteger numberOfNodesExported = 0;
    NSInteger numberOfNodesOutShares = 0;
    for (MEGANode *node in nodesArray) {
        if ([node type] == MEGANodeTypeFolder) {
            numberOfFolders += 1;
        } else if ([node type] == MEGANodeTypeFile) {
            numberOfFiles += 1;
        }
        
        if ([node isExported]) {
            numberOfNodesExported += 1;
        }
        
        if (node.isOutShare) {
            numberOfNodesOutShares += 1;
        }
    }
    
    NodesAre nodesAre = 0;
    if (numberOfFolders  == nodesArray.count) {
        nodesAre = NodesAreFolders;
    } else if (numberOfFiles  == nodesArray.count) {
        nodesAre = NodesAreFiles;
    }
    
    if (numberOfNodesExported == nodesArray.count) {
        nodesAre = nodesAre | NodesAreExported;
    }
    
    if (numberOfNodesOutShares == nodesArray.count) {
        nodesAre = nodesAre | NodesAreOutShares;
    }
    
    return nodesAre;
}

+ (NSArray *)checkIfAllOfTheseNodesExistInOffline:(NSArray *)nodesArray {
    NSMutableArray *filesURLMutableArray = [[NSMutableArray alloc] init];
    for (MEGANode *node in nodesArray) {
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node];
        if (offlineNodeExist) {
            [filesURLMutableArray addObject:[NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingPathComponent:[offlineNodeExist localPath]]]];
        } else {
            [filesURLMutableArray removeAllObjects];
            break;
        }
    }
    
    return [filesURLMutableArray copy];
}

+ (void)setIndexer:(MEGAIndexer* )megaIndexer {
    indexer = megaIndexer;
}

#pragma mark - Utils for empty states

+ (UIEdgeInsets)capInsetsForEmptyStateButton {
    UIEdgeInsets capInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    
    return capInsets;
}

+ (UIEdgeInsets)rectInsetsForEmptyStateButton {
    UIEdgeInsets rectInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
            rectInsets = UIEdgeInsetsMake(0.0, -20.0, 0.0, -20.0);
        } else if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat emptyStateButtonWidth = ([[UIScreen mainScreen] bounds].size.height);
            CGFloat leftOrRightInset = ([[UIScreen mainScreen] bounds].size.width - emptyStateButtonWidth) / 2;
            rectInsets = UIEdgeInsetsMake(0.0, -leftOrRightInset, 0.0, -leftOrRightInset);
        }
    } else if ([[UIDevice currentDevice] iPadDevice]) {
        CGFloat emptyStateButtonWidth = 400.0f;
        CGFloat leftOrRightInset = ([[UIScreen mainScreen] bounds].size.width - emptyStateButtonWidth) / 2;
        rectInsets = UIEdgeInsetsMake(0.0, -leftOrRightInset, 0.0, -leftOrRightInset);
    }
    
    return rectInsets;
}

+ (CGFloat)verticalOffsetForEmptyStateWithNavigationBarSize:(CGSize)navigationBarSize searchBarActive:(BOOL)isSearchBarActive {
    CGFloat verticalOffset = 0.0f;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        if (isSearchBarActive) {
            verticalOffset += -navigationBarSize.height;
        }
    } else if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        if ([[UIDevice currentDevice] iPhoneDevice]) {
            verticalOffset += -navigationBarSize.height/2;
        }
    }
    
    return verticalOffset;
}

+ (CGFloat)spaceHeightForEmptyState {
    CGFloat spaceHeight = 40.0f;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && [[UIDevice currentDevice] iPhoneDevice]) {
        spaceHeight = 11.0f;
    }
    
    return spaceHeight;
}

+ (CGFloat)spaceHeightForEmptyStateWithDescription {
    CGFloat spaceHeight = 20.0f;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && [[UIDevice currentDevice] iPhoneDevice]) {
        spaceHeight = 11.0f;
    }
    
    return spaceHeight;
}

+ (NSDictionary *)titleAttributesForEmptyState {
    return @{NSFontAttributeName:[UIFont systemFontOfSize:18.0f], NSForegroundColorAttributeName:UIColor.mnz_label};
}

+ (NSDictionary *)buttonTextAttributesForEmptyState {
    return @{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:UIColor.whiteColor};
}

#pragma mark - Utils for UI

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    return [self customNavigationBarLabelWithTitle:title subtitle:subtitle color:UIColor.mnz_label];
}

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle color:(UIColor *)color {
    NSMutableAttributedString *titleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:color}];
    
    UIColor *colorWithAlpha = [color colorWithAlphaComponent:0.8];
    if (![subtitle isEqualToString:@""]) {
        subtitle = [NSString stringWithFormat:@"\n%@", subtitle];
        NSMutableAttributedString *subtitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:subtitle attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:colorWithAlpha}];
        
        [titleMutableAttributedString appendAttributedString:subtitleMutableAttributedString];
    }
    
    UILabel *label = [[UILabel alloc] init];
    [label setNumberOfLines:[subtitle isEqualToString:@""] ? 1 : 2];
    
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setAttributedText:titleMutableAttributedString];
    
    return label;
}

+ (UISearchController *)customSearchControllerWithSearchResultsUpdaterDelegate:(id<UISearchResultsUpdating>)searchResultsUpdaterDelegate searchBarDelegate:(id<UISearchBarDelegate>)searchBarDelegate {
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = searchResultsUpdaterDelegate;
    searchController.searchBar.delegate = searchBarDelegate;
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    
    return searchController;
}

+ (void)resetSearchControllerFrame:(UISearchController *)searchController {
    searchController.view.frame = CGRectMake(0, UIApplication.sharedApplication.statusBarFrame.size.height, searchController.view.frame.size.width, searchController.view.frame.size.height);
    searchController.searchBar.superview.frame = CGRectMake(0, 0, searchController.searchBar.superview.frame.size.width, searchController.searchBar.superview.frame.size.height);
    searchController.searchBar.frame = CGRectMake(0, 0, searchController.searchBar.frame.size.width, searchController.searchBar.frame.size.height);
}

#pragma mark - Manage session

+ (BOOL)hasSession_alertIfNot {
    if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
        return YES;
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"pleaseLogInToYourAccount", @"Alert title shown when you need to log in to continue with the action you want to do") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
}

#pragma mark - Logout

+ (void)logout {
    [NSNotificationCenter.defaultCenter postNotificationName:MEGALogoutNotification object:self];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
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

+ (void)logoutAfterPasswordReminder {
    NSError *error;
    NSArray *directoryContent = [NSFileManager.defaultManager contentsOfDirectoryAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject error:&error];
    if (error) {
        MEGALogError(@"Contents of directory at path failed with error: %@", error);
    }
    
    BOOL isInboxDirectory = NO;
    for (NSString *directoryElement in directoryContent) {
        if ([directoryElement isEqualToString:@"Inbox"]) {
            NSString *inboxPath = [[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"];
            [[NSFileManager defaultManager] fileExistsAtPath:inboxPath isDirectory:&isInboxDirectory];
            break;
        }
    }
    
    if (directoryContent.count > 0) {
        if (directoryContent.count == 1 && isInboxDirectory) {
            [[MEGASdkManager sharedMEGASdk] logout];
            return;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"warning", nil) message:AMLocalizedString(@"allFilesSavedForOfflineWillBeDeletedFromYourDevice", @"Alert message shown when the user perform logout and has files in the Offline directory") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGASdk] logout];
        }]];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
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
    // Delete app's directories: Library/Cache/thumbs - Library/Cache/previews - Documents - tmp
    
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
    
    [MEGAStore.shareInstance.storeStack deleteStoreWithError:nil];
    
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
    NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"];
    [[NSFileManager defaultManager] mnz_removeItemAtPath:masterKeyFilePath];
}

+ (void)resetUserData {
    [[Helper downloadingNodes] removeAllObjects];
    [[Helper uploadingNodes] removeAllObjects];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"agreedCopywriteWarning"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TransfersPaused"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IsSavePhotoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IsSaveVideoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ChatVideoQuality"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"logging"];

    //Set default order on logout
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"SortOrderType"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"OfflineSortOrderType"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    [sharedUserDefaults removeObjectForKey:@"extensions"];
    [sharedUserDefaults removeObjectForKey:@"extensions-passcode"];
    [sharedUserDefaults removeObjectForKey:@"treeCompleted"];
    [sharedUserDefaults removeObjectForKey:@"useHttpsOnly"];
    [sharedUserDefaults removeObjectForKey:@"IsChatEnabled"];
    [sharedUserDefaults removeObjectForKey:@"logging"];
    [sharedUserDefaults synchronize];
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

+ (void)showExportMasterKeyInView:(UIViewController *)viewController completion:(void (^ __nullable)(void))completion {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"];
    
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:masterKeyFilePath contents:[[[MEGASdkManager sharedMEGASdk] masterKey] dataUsingEncoding:NSUTF8StringEncoding] attributes:@{NSFileProtectionKey:NSFileProtectionComplete}];
    if (success) {
        UIAlertController *recoveryKeyAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"masterKeyExported", @"Alert title shown when you have exported your MEGA Recovery Key") message:AMLocalizedString(@"masterKeyExported_alertMessage", @"The Recovery Key has been exported into the Offline section as RecoveryKey.txt. Note: It will be deleted if you log out, please store it in a safe place.")  preferredStyle:UIAlertControllerStyleAlert];
        [recoveryKeyAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"recoveryKeyCopiedToClipboard", @"Title of the dialog displayed when copy the user's Recovery Key to the clipboard to be saved or exported - (String as short as possible).") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    
    [[MEGASdkManager sharedMEGASdk] masterKeyExported];
}

#pragma mark - Log

+ (void)enableOrDisableLog {
    BOOL enableLog = ![[NSUserDefaults standardUserDefaults] boolForKey:@"logging"];
    NSString *alertTitle = enableLog ? AMLocalizedString(@"enableDebugMode_title", @"Alert title shown when the DEBUG mode is enabled") :AMLocalizedString(@"disableDebugMode_title", @"Alert title shown when the DEBUG mode is disabled");
    NSString *alertMessage = enableLog ? AMLocalizedString(@"enableDebugMode_message", @"Alert message shown when the DEBUG mode is enabled") :AMLocalizedString(@"disableDebugMode_message", @"Alert message shown when the DEBUG mode is disabled");
    
    UIAlertController *logAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    [logAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [logAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        enableLog ? [[MEGALogger sharedLogger] startLogging] : [[MEGALogger sharedLogger] stopLogging];
    }]];
    
    [UIApplication.mnz_presentingViewController presentViewController:logAlertController animated:YES completion:nil];
}

@end
