/**
 * @file Helper.m
 * @brief Common methods for the app.
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

#import <MobileCoreServices/MobileCoreServices.h>

#import "Helper.h"
#import "MEGASdkManager.h"
#import "SSKeychain.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "CameraUploads.h"
#import "LTHPasscodeViewController.h"
#import "MEGAStore.h"

static NSString *pathForPreview;
static NSString *renamePathForPreview;

static MEGANode *linkNode;
static NSInteger linkNodeOption;
static NSMutableArray *nodesFromLinkMutableArray;

@implementation Helper

#pragma mark - Languages

+ (NSArray *)languagesSupportedIDs {
    static NSArray *languagesSupportedIDs = nil;
    
    if (languagesSupportedIDs == nil) {
        languagesSupportedIDs = [NSArray arrayWithObjects:@"ar",
                                 @"bg",
                                 @"cs",
                                 @"de",
                                 @"en",
                                 @"es",
                                 @"fa",
                                 @"fi",
                                 @"fr",
                                 @"he",
                                 @"hu",
                                 @"id",
                                 @"it",
                                 @"ja",
                                 @"ko",
                                 @"nl",
                                 @"pl",
                                 @"pt-br",
                                 @"pt",
                                 @"ro",
                                 @"ru",
                                 @"sk",
                                 @"sl",
                                 @"sr",
                                 @"sv",
                                 //@"th",
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
    return [self.languagesSupportedIDs containsObject:languageID];
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

+ (UIImage *)folderSharedImage {
    static UIImage *folderSharedImage = nil;
    
    if (folderSharedImage == nil) {
        folderSharedImage = [UIImage imageNamed:@"folder_outgoing"];
    }
    return folderSharedImage;
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
                if ([[MEGASdkManager sharedMEGASdk] isSharedNode:node]) {
                    return [self folderSharedImage];
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

#pragma mark - Paths

+ (NSString *)pathForOffline {
    static NSString *pathString = nil;
    
    if (pathString == nil) {
        pathString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        pathString = [pathString stringByAppendingString:@"/"];
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

+ (NSString *)pathForUser:(MEGAUser *)user searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory {
    
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [[user email] stringByAppendingString:@""];
    NSString *destinationFilePath = nil;
    destinationFilePath = [directory isEqualToString:@""] ? [destinationPath stringByAppendingPathComponent:fileName]
    :[[destinationPath stringByAppendingPathComponent:directory] stringByAppendingPathComponent:fileName];
    
    return destinationFilePath;
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
    if ([node.name isEqualToString:@"Inbox"] && [folderPath isEqualToString:[self pathForOffline]]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"folderInboxError", nil)];
        return;
    }
    
    if (isFolderLink) {
        api = [MEGASdkManager sharedMEGASdkFolder];
    } else {
        api = [MEGASdkManager sharedMEGASdk];
    }
    
    NSString *offlineNameString = [api escapeFsIncompatible:node.name];
    NSString *absoluteFilePath = [folderPath stringByAppendingPathComponent:offlineNameString];
    
    if (node.type == MEGANodeTypeFile) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:absoluteFilePath]) {            
            MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[api fingerprintForNode:node]];
            
            if (offlineNodeExist) {
                NSString *itemPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
                [[NSFileManager defaultManager] copyItemAtPath:itemPath toPath:absoluteFilePath error:nil];
                [[MEGAStore shareInstance] insertOfflineNode:node api:api path:[[Helper pathRelativeToOfflineDirectory:absoluteFilePath] decomposedStringWithCanonicalMapping]];
            } else {
                [api startDownloadNode:node localPath:absoluteFilePath];
            }
        } else {
//            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"fileAlreadyExist", @"The file you want to download already exists on Offline")];
        }
    } else if (node.type == MEGANodeTypeFolder && [[api sizeForNode:node] longLongValue] != 0) {
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
            [self downloadNode:child folderPath:absoluteFilePath isFolderLink:isFolderLink];
        }
    }
}

#pragma mark - Utils

+ (void)changeToViewController:(Class)classOfViewController onTabBarController:(UITabBarController *)tabBarController {
    NSArray *viewControllersArray = tabBarController.viewControllers;
    NSUInteger index = 0;
    for (UINavigationController *navigationController in viewControllersArray) {
        if ([navigationController.visibleViewController isKindOfClass:classOfViewController]) {
            [tabBarController setSelectedIndex:index];
            break;
        }
        index += 1;
    }
}

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
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    } else {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]]];
    }
    
    return totalFreeSpace;
}

#pragma mark - Logout

+ (void)logout {    
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
    [SSKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
}

+ (void)deleteUserData {
    // Delete app's directories: Library/Cache/thumbs - Library/Cache/previews - Documents - tmp
    NSError *error = nil;
    
    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:thumbsDirectory error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:previewsDirectory error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
    
    // Remove "Inbox" folder return an error. "Inbox" is reserved by Apple
    NSString *offlineDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:offlineDirectory error:&error]) {
        error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[offlineDirectory stringByAppendingPathComponent:file] error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove temporary directory error: %@", error]];
        }
    }
    
    // Delete v2 thumbnails & previews directory
    NSString *thumbs2Directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbs2Directory]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:thumbs2Directory error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
    
    NSString *previews2Directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:previews2Directory]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:previews2Directory error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
}

+ (void)deleteMasterKey {
    // Remove Master Key exported file if exist
    NSError *error = nil;
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    BOOL existMasterKey = [[NSFileManager defaultManager] fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:@"MasterKey.txt"]];
    
    NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"MasterKey.txt"];
    
    if (existMasterKey) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:masterKeyFilePath error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
}

+ (void)resetUserData {
    [[Helper downloadingNodes] removeAllObjects];
    [[MEGAStore shareInstance] removeAllOfflineNodes];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DownloadedNodes"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TabsOrderInTabBar"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TransfersPaused"];
    
    //Set default order on logout
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"SortOrderType"];

    [[NSUserDefaults standardUserDefaults] synchronize];
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

@end
