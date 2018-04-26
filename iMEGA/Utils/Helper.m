#import "Helper.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "MEGAActivityItemProvider.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"

#import "CameraUploads.h"
#import "GetLinkActivity.h"
#import "NodeTableViewCell.h"
#import "OpenInActivity.h"
#import "PhotoCollectionViewCell.h"
#import "RemoveLinkActivity.h"
#import "RemoveSharingActivity.h"
#import "ShareFolderActivity.h"

static MEGANode *linkNode;
static NSInteger linkNodeOption;
static NSMutableArray *nodesFromLinkMutableArray;

static NSUInteger totalOperations;
static BOOL copyToPasteboard;

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
                                 @"he",
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
                                 @"tr",
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
                                @"3gp":@"video",
                                @"7z":@"compressed",
                                @"aac":@"audio",
                                @"ac3":@"audio",
                                @"accdb":@"database",
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
                                @"as":@"fla_lang",
                                @"asc":@"fla_lang",
                                @"ascii":@"text",
                                @"asf":@"video",
                                @"asp":@"web_lang",
                                @"aspx":@"web_lang",
                                @"asx":@"playlist",
                                @"avi":@"video",
                                @"bay":@"raw",
                                @"bmp":@"graphic",
                                @"bz2":@"compressed",
                                @"c":@"source_code",
                                @"cc":@"source_code",
                                @"cdr":@"vector",
                                @"cgi":@"web_lang",
                                @"class":@"java",
                                @"com":@"executable",
                                @"cpp":@"source_code",
                                @"cr2":@"raw",
                                @"css":@"web_data",
                                @"cxx":@"source_code",
                                @"dcr":@"raw",
                                @"db":@"database",
                                @"dbf":@"database",
                                @"dhtml":@"html",
                                @"dll":@"source_code",
                                @"dng":@"raw",
                                @"doc":@"word",
                                @"docx":@"word",
                                @"dotx":@"word",
                                @"dwg":@"cad",
                                @"dwt":@"dreamweaver",
                                @"dxf":@"cad",
                                @"dmg":@"dmg",
                                @"eps":@"vector",
                                @"exe":@"executable",
                                @"fff":@"raw",
                                @"fla":@"flash",
                                @"flac":@"audio",
                                @"flv":@"video",
                                @"fnt":@"font",
                                @"fon":@"font",
                                @"gadget":@"executable",
                                @"gif":@"graphic",
                                @"gpx":@"gis",
                                @"gsheet":@"spreadsheet",
                                @"gz":@"compressed",
                                @"h":@"source_code",
                                @"hpp":@"source_code",
                                @"htm":@"html",
                                @"html":@"html",
                                @"iff":@"audio",
                                @"inc":@"web_lang",
                                @"indd":@"indesign",
                                @"jar":@"java",
                                @"java":@"java",
                                @"jpeg":@"image",
                                @"jpg":@"image",
                                @"js":@"web_data",
                                @"key":@"keynote",
                                @"kml":@"gis",
                                @"log":@"text",
                                @"m":@"source_code",
                                @"mm":@"source_code",
                                @"m3u":@"playlist",
                                @"m4v":@"video",
                                @"m4a":@"audio",
                                @"max":@"3d",
                                @"mdb":@"database",
                                @"mef":@"raw",
                                @"mid":@"midi",
                                @"midi":@"midi",
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
                                @"odt":@"text",
                                @"ogv":@"video",
                                @"otf":@"font",
                                @"ots":@"spreadsheet",
                                @"orf":@"raw",
                                @"pages":@"pages",
                                @"pcast":@"podcast",
                                @"pdb":@"database",
                                @"pdf":@"pdf",
                                @"pef":@"raw",
                                @"php":@"web_lang",
                                @"php3":@"web_lang",
                                @"php4":@"web_lang",
                                @"php5":@"web_lang",
                                @"phtml":@"web_lang",
                                @"pl":@"web_lang",
                                @"pls":@"playlist",
                                @"png":@"graphic",
                                @"ppj":@"premiere",
                                @"pps":@"powerpoint",
                                @"ppt":@"powerpoint",
                                @"pptx":@"powerpoint",
                                @"prproj":@"premiere",
                                @"psb":@"photoshop",
                                @"psd":@"photoshop",
                                @"py":@"web_lang",
                                @"ra":@"real_audio",
                                @"ram":@"real_audio",
                                @"rar":@"compressed",
                                @"rm":@"real_audio",
                                @"rtf":@"text",
                                @"rw2":@"raw",
                                @"rwl":@"raw",
                                @"sh":@"source_code",
                                @"shtml":@"web_data",
                                @"sitx":@"compressed",
                                @"sketch":@"sketch",
                                @"sql":@"database",
                                @"srf":@"raw",
                                @"srt":@"subtitles",
                                @"stl":@"3d",
                                @"svg":@"vector",
                                @"svgz":@"vector",
                                @"swf":@"swf",
                                @"tar":@"compressed",
                                @"tbz":@"compressed",
                                @"tga":@"graphic",
                                @"tgz":@"compressed",
                                @"tif":@"graphic",
                                @"tiff":@"graphic",
                                @"torrent":@"torrent",
                                @"ttf":@"font",
                                @"txt":@"text",
                                @"vcf":@"vcard",
                                @"vob":@"video_vob",
                                @"wav":@"audio",
                                @"webm":@"video",
                                @"wma":@"audio",
                                @"wmv":@"video",
                                @"wpd":@"text",
                                @"wps":@"word",
                                @"xhtml":@"html",
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

+ (NSString *)fileTypeIconForExtension:(NSString *)extension {
    NSString *fileTypeIconString = [self.fileTypesDictionary valueForKey:extension];
    if (fileTypeIconString == nil) {
        fileTypeIconString = @"generic";
    }
    return fileTypeIconString;
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

+ (UIImage *)imageForNode:(MEGANode *)node {
    
    switch ([node type]) {
        case MEGANodeTypeFolder: {
            if ([node.name isEqualToString:@"Camera Uploads"]) {
                return [self folderCameraUploadsImage];
            } else {
                if (node.isInShare) {
                    return [self incomingFolderImage];
                } else if (node.isOutShare) {
                    return [self outgoingFolderImage];
                } else {
                    return [self folderImage];
                }
            }
            break;
        }
            
        case MEGANodeTypeFile: {
            NSString *nodePathExtension = node.name.pathExtension;
            return [self imageForExtension:nodePathExtension];
            break;
        }
            
        default:
            return [self genericImage];
    }
}

+ (UIImage *)imageForExtension:(NSString *)extension {
    extension = extension.lowercaseString;
    UIImage *image;
    if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
        image = [Helper defaultPhotoImage];
    } else {
        NSString *filetypeImage = [self.fileTypesDictionary valueForKey:extension];
        if (filetypeImage && filetypeImage.length > 0) {
            image = [UIImage imageNamed:filetypeImage];
        } else {
            return [self genericImage];
        }
    }
    return image;
}

+ (UIImage *)infoImageForNode:(MEGANode *)node {
    
    switch ([node type]) {
        case MEGANodeTypeFolder: {
            if ([node.name isEqualToString:@"Camera Uploads"]) {
                return [UIImage imageNamed:@"info_folder_image"];
            } else {
                if ([[MEGASdkManager sharedMEGASdk] isSharedNode:node]) {
                    return [UIImage imageNamed:@"info_folder_outgoing"];
                } else {
                    return [UIImage imageNamed:@"info_folder"];
                }
            }
            break;
        }
            
        case MEGANodeTypeFile: {
            NSString *nodePathExtension = node.name.pathExtension;
            return [self infoImageForExtension:nodePathExtension];
            break;
        }
            
        default:
            return [UIImage imageNamed:@"info_generic"];
    }
}

+ (UIImage *)infoImageForExtension:(NSString *)extension {
    extension = extension.lowercaseString;
    UIImage *image;
    if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
        image = [UIImage imageNamed:@"info_image"];
    } else {
        NSString *filetypeImage = [self.fileTypesDictionary valueForKey:extension];
        if (filetypeImage && filetypeImage.length > 0) {
            image = [UIImage imageNamed:[NSString stringWithFormat:@"info_%@", filetypeImage]];
        } else {
            return [UIImage imageNamed:@"info_generic"];
        }
    }
    return image;
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
        pathString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        pathString = [pathString stringByAppendingString:@"/"];
    }
    
    return pathString;
}

+ (NSString *)relativePathForOffline {
    static NSString *pathString = nil;
    
    if (pathString == nil) {
        pathString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES) objectAtIndex:0];
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
    NSString *cacheDirectory = @"Library/Cache/";
    NSString *targetDirectory = [cacheDirectory stringByAppendingString:directory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:targetDirectory] path];
    if (![fileManager fileExistsAtPath:destinationPath]) {
        [fileManager createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return destinationPath;
}

#pragma mark - Utils for links when you are not logged

+ (MEGANode *)linkNode {
    return linkNode;
}

+ (void)setLinkNode:(MEGANode *)node {
    linkNode = node;
}

+ (NSMutableArray *)nodesFromLinkMutableArray {
    if (nodesFromLinkMutableArray == nil) {
        nodesFromLinkMutableArray = [[NSMutableArray alloc] init];
    }
    
    return nodesFromLinkMutableArray;
}

+ (NSInteger)selectedOptionOnLink {
    return linkNodeOption;
}

+ (void)setSelectedOptionOnLink:(NSInteger)option {
    linkNodeOption = option;
}

#pragma mark - Utils download and downloading nodes

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
    
    UIAlertView *alertView;
    if ([nodeSizeNumber longLongValue] == 0) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emptyFolderMessage", @"Message fon an alert when the user tries download an empty folder")];
        return NO;
    }
    
    NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
    if ([freeSizeNumber longLongValue] < [nodeSizeNumber longLongValue]) {
        if ([node type] == MEGANodeTypeFile) {
            alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                   message:AMLocalizedString(@"fileTooBigMessage", @"The file you are trying to download is bigger than the avaliable memory.")
                                                  delegate:self
                                         cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                         otherButtonTitles:nil];
        } else if ([node type] == MEGANodeTypeFolder) {
            alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                   message:AMLocalizedString(@"folderTooBigMessage", @"The folder you are trying to download is bigger than the avaliable memory.")
                                                  delegate:self
                                         cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                         otherButtonTitles:nil];
        }
        
        [alertView show];
        return NO;
    }
    return YES;
}

+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink {
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
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath]]) {
            MOOfflineNode *offlineNodeExist =  [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]];
            
            if (offlineNodeExist) {
                NSRange replaceRange = [relativeFilePath rangeOfString:@"Documents/"];
                if (replaceRange.location != NSNotFound) {
                    NSString *result = [relativeFilePath stringByReplacingCharactersInRange:replaceRange withString:@""];
                    NSString *itemPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
                    [[NSFileManager defaultManager] copyItemAtPath:itemPath toPath:[NSHomeDirectory() stringByAppendingPathComponent:relativeFilePath] error:nil];
                    [[MEGAStore shareInstance] insertOfflineNode:node api:api path:[result decomposedStringWithCanonicalMapping]];
                }
            } else {
                NSString *appData = nil;
                if ((node.name.mnz_isImagePathExtension && [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"]) || (node.name.mnz_videoPathExtension && [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"])) {
                    NSString *downloadsDirectory = [[NSFileManager defaultManager] downloadsDirectory];
                    downloadsDirectory = [downloadsDirectory stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""];
                    relativeFilePath = [downloadsDirectory stringByAppendingPathComponent:offlineNameString];
                    appData = @"SaveInPhotosApp";
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
            [self downloadNode:child folderPath:relativeFilePath isFolderLink:isFolderLink];
        }
    }
}

#pragma mark - Utils

+ (unsigned long long)sizeOfFolderAtPath:(NSString *)path {
    unsigned long long folderSize = 0;
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            folderSize += [Helper sizeOfFolderAtPath:[path stringByAppendingPathComponent:item]];
        } else {
            folderSize += [[attributesDictionary objectForKey:NSFileSize] unsignedLongLongValue];
        }
    }
    
    return folderSize;
}

+ (uint64_t)freeDiskSpace {
    uint64_t totalFreeSpace = 0;
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    } else {
        MEGALogError(@"Obtaining System Memory Info failed with error: %@", error);
    }
    
    return totalFreeSpace;
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
            [nodeTableViewCell.thumbnailImageView setImage:[Helper imageForNode:node]];
        } else if ([cell isKindOfClass:[PhotoCollectionViewCell class]]) {
            PhotoCollectionViewCell *photoCollectionViewCell = cell;
            [photoCollectionViewCell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
    }
}

+ (void)setThumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell reindexNode:(BOOL)reindex {
    NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([cell isKindOfClass:[NodeTableViewCell class]]) {
        NodeTableViewCell *nodeTableViewCell = cell;
        [nodeTableViewCell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
        nodeTableViewCell.thumbnailPlayImageView.hidden = !node.name.mnz_videoPathExtension;
    } else if ([cell isKindOfClass:[PhotoCollectionViewCell class]]) {
        PhotoCollectionViewCell *photoCollectionViewCell = cell;
        [photoCollectionViewCell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
        photoCollectionViewCell.thumbnailPlayImageView.hidden = !node.name.mnz_videoPathExtension;
        photoCollectionViewCell.thumbnailVideoOverlayView.hidden = !(node.name.mnz_videoPathExtension && node.duration>-1);
    }
    
    if (reindex) {
        [indexer index:node];
    }
}

+ (NSString *)sizeAndDateForNode:(MEGANode *)node api:(MEGASdk *)api {
    NSString *size;
    time_t rawtime;
    if ([node isFile]) {
        size = [NSByteCountFormatter stringFromByteCount:node.size.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory];
        rawtime = [[node modificationTime] timeIntervalSince1970];
    } else {
        size = [NSByteCountFormatter stringFromByteCount:[[api sizeForNode:node] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
        rawtime = [[node creationTime] timeIntervalSince1970];
    }
    
    NSString *date = [self dateWithISO8601FormatOfRawTime:rawtime];
    
    return [NSString stringWithFormat:@"%@ • %@", size, date];
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

+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray button:(UIBarButtonItem *)shareBarButtonItem {
    totalOperations = nodesArray.count;
    
    UIActivityViewController *activityVC;
    NSMutableArray *activityItemsMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *excludedActivityTypesMutableArray = [[NSMutableArray alloc] initWithArray:@[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]];
    
    GetLinkActivity *getLinkActivity = [[GetLinkActivity alloc] initWithNodes:nodesArray];
    [activitiesMutableArray addObject:getLinkActivity];
    [Helper setCopyToPasteboard:NO];
    
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
            OpenInActivity *openInActivity = [[OpenInActivity alloc] initOnBarButtonItem:shareBarButtonItem];
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
    
    activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItemsMutableArray applicationActivities:activitiesMutableArray];
    [activityVC setExcludedActivityTypes:excludedActivityTypesMutableArray];
    [activityVC.popoverPresentationController setBarButtonItem:shareBarButtonItem];
    
    return activityVC;
}

+ (void)setTotalOperations:(NSUInteger)total {
    totalOperations = total;
}

+ (NSUInteger)totalOperations {
    return totalOperations;
}

+ (void)setCopyToPasteboard:(BOOL)boolValue {
    copyToPasteboard = boolValue;
}

+ (BOOL)copyToPasteboard {
    return copyToPasteboard;
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
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]];
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

#pragma mark - Utils for UI

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    NSMutableAttributedString *titleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    
    subtitle = [NSString stringWithFormat:@"\n%@", subtitle];
    NSMutableAttributedString *subtitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:subtitle attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_gray666666]}];
    
    [titleMutableAttributedString appendAttributedString:subtitleMutableAttributedString];
    
    UILabel *label = [[UILabel alloc] init];
    [label setNumberOfLines:2];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setAttributedText:titleMutableAttributedString];
    
    return label;
}

#pragma mark - Logout

+ (void)logout {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [Helper cancelAllTransfers];
    
    [Helper clearSession];
    
    [Helper deleteUserData];
    [Helper deleteMasterKey];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [UIView transitionWithView:window duration:0.5 options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent) animations:^{
        [window setRootViewController:viewController];
    } completion:nil];
        
    [Helper resetCameraUploadsSettings];
    [Helper resetUserData];
    
    [Helper deletePasscode];
}

+ (void)logoutFromConfirmAccount {    
    [Helper cancelAllTransfers];
    
    [Helper clearSession];
    
    [Helper deleteUserData];
    [Helper deleteMasterKey];
    
    [Helper resetCameraUploadsSettings];
    [Helper resetUserData];
    
    [Helper deletePasscode];
}

+ (void)cancelAllTransfers {
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:0];
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
    
    [[MEGASdkManager sharedMEGASdkFolder] cancelTransfersForDirection:0];
}

+ (void)clearSession {
    [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
}

+ (void)deleteUserData {
    // Delete app's directories: Library/Cache/thumbs - Library/Cache/previews - Documents - tmp
    NSError *error;
    
    NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:thumbsDirectory error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:previewsDirectory error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
    // Remove "Inbox" folder return an error. "Inbox" is reserved by Apple
    NSString *offlineDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:offlineDirectory error:&error]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[offlineDirectory stringByAppendingPathComponent:file] error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&error]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:file] error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
    // Delete v2 thumbnails & previews directory
    NSString *thumbs2Directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbs2Directory]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:thumbs2Directory error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
    NSString *previews2Directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:previews2Directory]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:previews2Directory error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
    // Delete application support directory content
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationSupportDirectory error:&error]) {
        if ([file containsString:@"MEGACD"] || [file containsString:@"spotlightTree"] || [file containsString:@"Uploads"] || [file containsString:@"Downloads"]) {
            if (![[NSFileManager defaultManager] removeItemAtPath:[applicationSupportDirectory stringByAppendingPathComponent:file] error:&error]) {
                MEGALogError(@"Remove item at path failed with error: %@", error);
            }
        }
    }
    
    // Delete files saved by extensions
    NSString *extensionGroup = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"].path;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:extensionGroup error:&error]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[extensionGroup stringByAppendingPathComponent:file] error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
    
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
    NSError *error;
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"]]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:masterKeyFilePath error:&error]) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
}

+ (void)resetUserData {
    [[Helper downloadingNodes] removeAllObjects];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"agreedCopywriteWarning"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DownloadedNodes"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TransfersPaused"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IsSavePhotoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IsSaveVideoToGalleryEnabled"];
    
    //Set default order on logout
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"SortOrderType"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"OfflineSortOrderType"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
    [sharedUserDefaults removeObjectForKey:@"extensions"];
    [sharedUserDefaults removeObjectForKey:@"extensions-passcode"];
    [sharedUserDefaults removeObjectForKey:@"treeCompleted"];
    [sharedUserDefaults removeObjectForKey:@"useHttpsOnly"];
    [sharedUserDefaults synchronize];
}

+ (void)resetCameraUploadsSettings {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUploadPhotoDate];
    [CameraUploads syncManager].lastUploadPhotoDate = [NSDate dateWithTimeIntervalSince1970:0];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUploadVideoDate];
    [CameraUploads syncManager].lastUploadVideoDate = [NSDate dateWithTimeIntervalSince1970:0];

    [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCameraUploadsNodeHandle];
}

+ (void)deletePasscode {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [LTHPasscodeViewController deletePasscode];
    }
}

#pragma mark - Log

+ (UIAlertView *)logAlertView:(BOOL)enableLog {
    UIAlertView *logAlertView;
    NSString *title = enableLog ? AMLocalizedString(@"enableDebugMode_title", nil) :AMLocalizedString(@"disableDebugMode_title", nil);
    NSString *message = enableLog ? AMLocalizedString(@"enableDebugMode_message", nil) :AMLocalizedString(@"disableDebugMode_message", nil);
    logAlertView = [[UIAlertView alloc] initWithTitle:title
                                              message:message
                                             delegate:nil
                                    cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                    otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
    logAlertView.tag = enableLog ? 1 : 0;
    
    return logAlertView;
}

@end
