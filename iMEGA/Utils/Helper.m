#import "Helper.h"
#import "MEGASdkManager.h"
#import "SSKeychain.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"

@interface Helper ()

+ (NSDictionary *)fileTypesDictionary;

+ (UIImage *)genericImage;
+ (UIImage *)folderImage;
+ (UIImage *)folderSharedImage;
+ (UIImage *)defaultPhotoImage;

@end

@implementation Helper

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
                                @"aep":@"aftereffects",
                                @"aet":@"aftereffects",
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
                                @"c":@"sourcecode",
                                @"cc":@"sourcecode",
                                @"cdr":@"vector",
                                @"cgi":@"web_lang",
                                @"class":@"java",
                                @"com":@"executable",
                                @"cpp":@"sourcecode",
                                @"cr2":@"raw",
                                @"css":@"web_data",
                                @"cxx":@"sourcecode",
                                @"dcr":@"raw",
                                @"db":@"database",
                                @"dbf":@"database",
                                @"dhtml":@"html",
                                @"dll":@"sourcecode",
                                @"dng":@"raw",
                                @"doc":@"word",
                                @"docx":@"word",
                                @"dotx":@"word",
                                @"dwg":@"cad",
                                @"dwt":@"dreamweaver",
                                @"dxf":@"cad",
                                @"eps":@"vector",
                                @"exe":@"executable",
                                @"fff":@"raw",
                                @"fla":@"flash",
                                @"flac":@"audio",
                                @"flv":@"flash_video",
                                @"fnt":@"font",
                                @"fon":@"font",
                                @"gadget":@"executable",
                                @"gif":@"graphic",
                                @"gpx":@"gis",
                                @"gsheet":@"spreadsheet",
                                @"gz":@"compressed",
                                @"h":@"sourcecode",
                                @"hpp":@"sourcecode",
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
                                @"m":@"sourcecode",
                                @"mm":@"sourcecode",
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
                                @"sh":@"sourcecode",
                                @"shtml":@"web_data",
                                @"sitx":@"compressed",
                                @"sql":@"database",
                                @"srf":@"raw",
                                @"srt":@"video_subtitles",
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

+ (UIImage *)defaultPhotoImage {
    static UIImage *defaultPhotoImage = nil;
    
    if (defaultPhotoImage == nil) {
        defaultPhotoImage = [UIImage imageNamed:@"image"];
    }
    return defaultPhotoImage;
}

+ (UIImage *)imageForNode:(MEGANode *)node {
    
    MEGANodeType nodeType = [node type];
    
    switch (nodeType) {
        case MEGANodeTypeFolder: {
            if ([[MEGASdkManager sharedMEGASdk] isSharedNode:node])
                return [self folderSharedImage];
            else
                return [self folderImage];
            }
            
        case MEGANodeTypeRubbish:
            return [self folderImage];
            
        case MEGANodeTypeFile: {
            NSString *im = [self.fileTypesDictionary valueForKey:[node name].pathExtension.lowercaseString];
            if (im && im.length>0) {
                return [UIImage imageNamed:im];
            }
        }
            
        default:
            return [self genericImage];
    }
    
}

+ (NSString *)pathForOfflineDirectory:(NSString *)directory {
    
    NSString *pathString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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

+ (void)downloadNode:(MEGANode *)node folder:(NSString *)folderPath folderLink:(BOOL)isFolderLink {
    
    if ([folderPath isEqualToString:@""]) {
        folderPath = [Helper pathForOffline];
    }
    
    NSString *offlineNameString = [[[node base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] nameToLocal:[node name]]];
    
    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL thumbnailExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
    if (!thumbnailExists && [node hasThumbnail]) {
        if (isFolderLink) {
            [[MEGASdkManager sharedMEGASdkFolder] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
        } else {
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
        }
    }
    NSString *absoluteFilePath = [folderPath stringByAppendingPathComponent:offlineNameString];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:absoluteFilePath];
    if (!fileExists) {
        if (isFolderLink) {
            [[MEGASdkManager sharedMEGASdkFolder] startDownloadNode:node localPath:absoluteFilePath];
        } else {
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:absoluteFilePath];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"fileAlreadyExist", @"The file you want to download already exists on Offline")];
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
            NSString *childFolderName = [[[node base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] nameToLocal:[node name]]];
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
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"folderCreationError", nil), folderNameString]];
            return NO;
        } else {
            return YES;
        }
    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"folderAlreadyExist", @"The folder you want to download already exists on Offline")];
        return NO;
    }
}

+ (void)logout {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] setIsLoginFromView:YES];
    [SSKeychain deletePasswordForService:@"MEGA" account:@"session"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    for (NSString *file in [fm contentsOfDirectoryAtPath:cacheDirectory error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", cacheDirectory, file] error:&error];
        if (!success || error) {
            NSLog(@"remove file error %@", error);
        }
    }
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    for (NSString *file in [fm contentsOfDirectoryAtPath:documentDirectory error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentDirectory, file] error:&error];
        if (!success || error) {
            NSLog(@"remove file error %@", error);
        }
    }
    
    for (NSString *file in [fm contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), file] error:&error];
        if (!success || error) {
            NSLog(@"remove file error %@", error);
        }
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
    
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:0];
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastUploadPhotoDate"];
}

@end
