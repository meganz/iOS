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

#import "Helper.h"
#import "MEGASdkManager.h"
#import "SSKeychain.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "CameraUploads.h"
#import "LTHPasscodeViewController.h"

static NSMutableDictionary *downloadedNodes;
static NSString *pathForPreview;
static NSString *renamePathForPreview;

static MEGANode *linkNode;
static NSInteger linkNodeOption;

@implementation Helper

#pragma mark - Images

+ (NSDictionary *)fileTypesDictionary {
    static NSDictionary *fileTypesDictionary = nil;
    
    if (fileTypesDictionary == nil) {
        fileTypesDictionary = @{@"3ds":@"3D",
                                @"3dm":@"3D",
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
                                @"flv":@"video_flash",
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
                                @"key":@"generic",
                                @"kml":@"gis",
                                @"log":@"text",
                                @"m":@"source_code",
                                @"mm":@"source_code",
                                @"m3u":@"playlist",
                                @"m4a":@"audio",
                                @"max":@"3D",
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
                                @"numbers":@"spreadsheet",
                                @"nef":@"raw",
                                @"obj":@"3D",
                                @"odp":@"generic",
                                @"ods":@"spreadsheet",
                                @"odt":@"text",
                                @"ogv":@"video",
                                @"otf":@"font",
                                @"ots":@"spreadsheet",
                                @"orf":@"raw",
                                @"pages":@"text",
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
                                @"sql":@"database",
                                @"srf":@"raw",
                                @"srt":@"subtitles",
                                @"stl":@"3D",
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
        folderSharedImage = [UIImage imageNamed:@"folder_shared"];
    }
    return folderSharedImage;
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

+ (UIImage *)downloadingArrowImage {
    static UIImage *downloadingArrowImage = nil;
    
    if (downloadingArrowImage == nil) {
        downloadingArrowImage = [UIImage imageNamed:@"downloadingArrow"];
    }
    return downloadingArrowImage;
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

+ (NSString *)pathForOfflineDirectory:(NSString *)directory {
    
    NSString *pathString = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Offline"];
    pathString = [directory isEqualToString:@""] ? [pathString stringByAppendingString:@"/"] : [pathString stringByAppendingPathComponent:directory];
    
    return pathString;
}

+ (NSString *)pathForOffline {
    return [self pathForOfflineDirectory:@""];
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

+ (NSString *)pathForPreviewDocument {
    return pathForPreview;
}

+ (void)setPathForPreviewDocument:(NSString *)path {
    pathForPreview = path;
}

+ (NSString *)renamePathForPreviewDocument {
    return renamePathForPreview;

}

+ (void)setRenamePathForPreviewDocument:(NSString *)path {
    renamePathForPreview = path;
}

#pragma mark - Utils for links when you are not logged

+ (MEGANode *)linkNode {
    return linkNode;
}

+ (void)setLinkNode:(MEGANode *)node {
    linkNode = node;
}

+ (NSInteger)selectedOptionOnLink {
    return linkNodeOption;
}

+ (void)setSelectedOptionOnLink:(NSInteger)option {
    linkNodeOption = option;
}

#pragma mark - Utils for download and downloading nodes

+ (NSMutableDictionary *)downloadingNodes {
    static NSMutableDictionary *downloadingNodes = nil;
    if (!downloadingNodes) {
        downloadingNodes = [[NSMutableDictionary alloc] init];
    }
    return downloadingNodes;
}

+ (NSMutableDictionary *)downloadedNodes {
    if (!downloadedNodes) {
        downloadedNodes = [[NSMutableDictionary alloc] init];
    }
    return downloadedNodes;
}

+ (void)setDownloadedNodes {
    downloadedNodes = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadedNodes"]];
}

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node {
    NSNumber *nodeSizeNumber;
    if ([node type] == MEGANodeTypeFile) {
        nodeSizeNumber = [node size];
    } else if ([node type] == MEGANodeTypeFolder) {
        nodeSizeNumber = [[MEGASdkManager sharedMEGASdk] sizeForNode:node];
    }
    NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
    if ([freeSizeNumber longLongValue] < [nodeSizeNumber longLongValue]) {
        UIAlertView *alertView;
        if ([node type] == MEGANodeTypeFile) {
            alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"fileTooBig", @"You need more free space")
                                                   message:AMLocalizedString(@"fileTooBigMessage", @"The file you are trying to download is bigger than the avaliable memory.")
                                                  delegate:self
                                         cancelButtonTitle:AMLocalizedString(@"ok", @"OK")
                                         otherButtonTitles:nil];
        } else if ([node type] == MEGANodeTypeFolder) {
            alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"folderTooBig", @"You need more free space")
                                                   message:AMLocalizedString(@"folderTooBigMessage", @"The folder you are trying to download is bigger than the avaliable memory.")
                                                  delegate:self
                                         cancelButtonTitle:AMLocalizedString(@"ok", @"OK")
                                         otherButtonTitles:nil];
        }
        
        [alertView show];
        return NO;
    }
    return YES;
}

+ (void)downloadNode:(MEGANode *)node folder:(NSString *)folderPath folderLink:(BOOL)isFolderLink {
    
    if ([folderPath isEqualToString:@""]) {
        folderPath = [Helper pathForOffline];
    }
    
    NSString *offlineNameString = [[[node base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[node name]]];
    NSString *absoluteFilePath = [folderPath stringByAppendingPathComponent:offlineNameString];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:absoluteFilePath];
    if (!fileExists) {
        if (isFolderLink) {
            [[MEGASdkManager sharedMEGASdkFolder] startDownloadNode:node localPath:absoluteFilePath];
        } else {
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:absoluteFilePath];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"fileAlreadyExist", @"The file you want to download already exists on Offline")];
    }
}

+ (void)downloadNodesOnFolder:(NSString *)folderPath parentNode:(MEGANode *)parentNode folderLink:(BOOL)isFolderLink {
    
    MEGANodeList *nodeList;
    if (isFolderLink) {
        nodeList = [[MEGASdkManager sharedMEGASdkFolder] childrenForParent:parentNode];
    } else {
        nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:parentNode];
    }
    NSUInteger nodeListSize = [nodeList.size integerValue];
    
    MEGANode *node = nil;
    
    for (NSUInteger i = 0; i < nodeListSize; i++) {
        node = [nodeList nodeAtIndex:i];
        
        if ([node type] == MEGANodeTypeFile) {
            [Helper downloadNode:node folder:folderPath folderLink:isFolderLink];
        } else if ([node type] == MEGANodeTypeFolder){
            NSString *childFolderName = [[[node base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[node name]]];
            NSString *childFolderPath = [folderPath stringByAppendingPathComponent:childFolderName];
            
            if ([Helper createOfflineFolder:childFolderName folderPath:childFolderPath]) {
                [self downloadNodesOnFolder:childFolderPath parentNode:node folderLink:isFolderLink];
            }
        }
    }
}

+ (BOOL)createOfflineFolder:(NSString *)folderName folderPath:(NSString *)folderPath {
    BOOL folderExists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath];
    if (!folderExists) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            NSString *folderNameString = [folderName lastPathComponent];
            NSArray *folderNameComponentsArray = [folderNameString componentsSeparatedByString:@"_"];
            if ([folderNameComponentsArray count] > 2) {
                NSString *handleString = [folderNameComponentsArray objectAtIndex:0];
                folderNameString = [folderNameString substringFromIndex:(handleString.length + 1)];
            } else {
                folderNameString = [folderNameComponentsArray objectAtIndex:1];
            }
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"folderCreationError", nil), folderNameString]];
            return NO;
        } else {
            return YES;
        }
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"folderAlreadyExist", @"The folder you want to download already exists on Offline")];
        return NO;
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

#pragma mark - Logout

+ (void)logout {    
    [Helper cancelAllTransfers];
    
    [Helper clearSession];
    
    [Helper deleteUserData];
    [Helper deleteMasterKey];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
    
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
    [SSKeychain deletePasswordForService:@"MEGA" account:@"session"];
}

+ (void)deleteUserData {
    // Delete app's directories: Library/Cache/thumbs - Library/Cache/previews - Library/Offline - tmp
    NSError *error = nil;
    
    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbs"];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:thumbsDirectory error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previews"];
    success = [[NSFileManager defaultManager] removeItemAtPath:previewsDirectory error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
    }
    
    NSString *offlineDirectory = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Offline"];
    
    success = [[NSFileManager defaultManager] removeItemAtPath:offlineDirectory error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
    }
    
    success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
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
    [[Helper downloadedNodes] removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DownloadedNodes"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TabsOrderInTabBar"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TransfersPaused"];
    
    //Set default order on logout
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"SortOrderType"];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)resetCameraUploadsSettings {
    [[CameraUploads syncManager].assetUploadArray removeAllObjects];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUploadPhotoDate];
    [CameraUploads syncManager].lastUploadPhotoDate = [NSDate dateWithTimeIntervalSince1970:0];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUploadVideoDate];
    [CameraUploads syncManager].lastUploadVideoDate = [NSDate dateWithTimeIntervalSince1970:0];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCameraUploadsNodeHandle];
    
    [CameraUploads syncManager].isCameraUploadsEnabled = NO;
    [CameraUploads syncManager].isUploadVideosEnabled = NO;
    [CameraUploads syncManager].isUseCellularConnectionEnabled = NO;
    [CameraUploads syncManager].isOnlyWhenChargingEnabled = NO;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
}

+ (void)deletePasscode {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [LTHPasscodeViewController deletePasscode];
    }
}

@end
