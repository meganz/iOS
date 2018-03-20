
#import "MEGANode+MNZCategory.h"

#import <Photos/Photos.h>

#import "Helper.h"
#import "MEGAAVViewController.h"
#import "MEGANode.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAQLPreviewController.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

#import "PreviewDocumentViewController.h"

#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"

#import "MEGAMoveRequestDelegate.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGARenameRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"

#import "UIApplication+MNZCategory.h"

@implementation MEGANode (MNZCategory)

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode {
    [self mnz_openImageInNavigationController:navigationController withNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:YES];
}

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin {
    MEGAPhotoBrowserViewController *photoBrowserVC = [self mnz_photoBrowserWithNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:enableMoveToRubbishBin];
    [navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
}

- (MEGAPhotoBrowserViewController *)mnz_photoBrowserWithNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin {
    return [self mnz_photoBrowserWithNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:enableMoveToRubbishBin hideControls:NO];
}

- (MEGAPhotoBrowserViewController *)mnz_photoBrowserWithNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin hideControls:(BOOL)hideControls {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MEGAPhotoBrowserViewController" bundle:nil];
    MEGAPhotoBrowserViewController *photoBrowserVC = [storyboard instantiateViewControllerWithIdentifier:@"MEGAPhotoBrowserViewControllerID"];
    photoBrowserVC.api = isFolderLink ? [MEGASdkManager sharedMEGASdkFolder] : [MEGASdkManager sharedMEGASdk];;
    photoBrowserVC.node = self;
    photoBrowserVC.nodesArray = nodesArray;
    
    return photoBrowserVC;
}

- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink {
    UIViewController *viewController = [self mnz_viewControllerForNodeInFolderLink:isFolderLink];
    if (viewController) {
        [navigationController presentViewController:viewController animated:YES completion:nil];
    }
}

- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink {
    MEGASdk *api = isFolderLink ? [MEGASdkManager sharedMEGASdkFolder] : [MEGASdkManager sharedMEGASdk];
    
    MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:self api:api];
    
    NSString *previewDocumentPath = nil;
    if (offlineNodeExist) {
        previewDocumentPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
    } else {
        NSString *nodeFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.base64Handle];
        NSString *tmpFilePath = [nodeFolderPath stringByAppendingPathComponent:self.name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tmpFilePath isDirectory:nil]) {
            previewDocumentPath = tmpFilePath;
        }
    }
    
    if (previewDocumentPath) {
        if (self.name.mnz_isMultimediaPathExtension) {
            NSURL *path = [NSURL fileURLWithPath:previewDocumentPath];
            MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:path];
            return megaAVViewController;
        } else {
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
            PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
            previewController.node = self;
            previewController.api = api;
            return navigationController;
        }
    } else if (self.name.mnz_isAudiovisualContentUTI && [api httpServerStart:YES port:4443]) {
        MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithNode:self folderLink:isFolderLink];
        return megaAVViewController;
    } else {
        if ([[[api downloadTransfers] size] integerValue] > 0) {
            UIAlertController *documentOpeningAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"documentOpening_alertTitle", @"Alert title shown when you try to open a Cloud Drive document and is not posible because there's some active download") message:AMLocalizedString(@"documentOpening_alertMessage", @"Alert message shown when you try to open a Cloud Drive document and is not posible because there's some active download") preferredStyle:UIAlertControllerStyleAlert];
            
            [documentOpeningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            return documentOpeningAlertController;
        } else {
            if ([Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
                PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
                previewController.node = self;
                previewController.api = api;
                return navigationController;
            }
            return nil;
        }
    }
}

- (void)mnz_generateThumbnailForVideoAtPath:(NSURL *)path {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CMTime requestedTime = CMTimeMake(1, 60);
    CGImageRef imgRef = [generator copyCGImageAtTime:requestedTime actualTime:NULL error:NULL];
    UIImage *image = [[UIImage alloc] initWithCGImage:imgRef];
    
    NSString *tmpImagePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:self.base64Handle] stringByAppendingPathExtension:@"jpg"];
    
    [UIImageJPEGRepresentation(image, 1) writeToFile:tmpImagePath atomically:YES];
    
    CGImageRelease(imgRef);
    
    NSString *thumbnailFilePath = [Helper pathForNode:self inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    [[MEGASdkManager sharedMEGASdk] createThumbnail:tmpImagePath destinatioPath:thumbnailFilePath];
    [[MEGASdkManager sharedMEGASdk] setThumbnailNode:self sourceFilePath:thumbnailFilePath];
    
    NSString *previewFilePath = [Helper pathForNode:self searchPath:NSCachesDirectory directory:@"previewsV3"];
    [[MEGASdkManager sharedMEGASdk] createPreview:tmpImagePath destinatioPath:previewFilePath];
    [[MEGASdkManager sharedMEGASdk] setPreviewNode:self sourceFilePath:previewFilePath];
    
    [[NSFileManager defaultManager] removeItemAtPath:tmpImagePath error:nil];
}

#pragma mark - Actions

- (BOOL)mnz_downloadNodeOverwriting:(BOOL)overwrite {
    MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:self api:[MEGASdkManager sharedMEGASdk]];
    if (offlineNodeExist) {
        return YES;
    } else {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            if ([Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:NO]) {
                [Helper downloadNode:self folderPath:[Helper relativePathForOffline] isFolderLink:NO shouldOverwrite:overwrite];
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    }
}

- (void)mnz_renameNodeInViewController:(UIViewController *)viewController {
    [self mnz_renameNodeInViewController:viewController completion:nil];
}

- (void)mnz_renameNodeInViewController:(UIViewController *)viewController completion:(void(^)(MEGARequest *request))completion {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *renameAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") message:AMLocalizedString(@"renameNodeMessage", @"Hint text to suggest that the user have to write the new name for the file or folder") preferredStyle:UIAlertControllerStyleAlert];
        
        [renameAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.delegate = self;
            textField.text = self.name;
            [textField addTarget:self action:@selector(renameAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [renameAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *renameAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *alertViewTextField = renameAlertController.textFields.firstObject;
                MEGARenameRequestDelegate *delegate = [[MEGARenameRequestDelegate alloc] initWithCompletion:completion];
                [[MEGASdkManager sharedMEGASdk] renameNode:self newName:alertViewTextField.text delegate:delegate];
            }
        }];
        renameAlertAction.enabled = NO;
        [renameAlertController addAction:renameAlertAction];
        
        [viewController presentViewController:renameAlertController animated:YES completion:nil];
    }
}

- (void)mnz_moveToTheRubbishBinInViewController:(UIViewController *)viewController {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
        NSString *alertMessage = (self.type == MEGANodeTypeFolder) ? AMLocalizedString(@"moveFolderToRubbishBinMessage", @"Alert message to confirm if the user wants to move to the Rubbish Bin '1 folder'") : AMLocalizedString(@"moveFileToRubbishBinMessage", @"Alert message to confirm if the user wants to move to the Rubbish Bin '1 file'");
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                void (^completion)(void) = ^{
                    [viewController dismissViewControllerAnimated:YES completion:nil];
                };
                MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:completion];
                [[MEGASdkManager sharedMEGASdk] moveNode:self newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:moveRequestDelegate];
            }
        }]];
        
        [viewController presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)mnz_removeInViewController:(UIViewController *)viewController {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
        NSString *alertMessage = (self.type == MEGANodeTypeFolder) ? AMLocalizedString(@"removeFolderToRubbishBinMessage", @"Alert message shown on the Rubbish Bin when you want to remove '1 folder'") : AMLocalizedString(@"removeFileToRubbishBinMessage", @"Alert message shown on the Rubbish Bin when you want to remove '1 file'");
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                void (^completion)(void) = ^{
                    [viewController dismissViewControllerAnimated:YES completion:nil];
                };
                MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:1 files:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:completion];
                [[MEGASdkManager sharedMEGASdk] removeNode:self delegate:removeRequestDelegate];
            }
        }]];
        
        [viewController presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)mnz_leaveSharingInViewController:(UIViewController *)viewController {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
        NSString *alertMessage = AMLocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                void (^completion)(void) = ^{
                    [viewController dismissViewControllerAnimated:YES completion:nil];
                };
                MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:2 files:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:completion];
                [[MEGASdkManager sharedMEGASdk] removeNode:self delegate:removeRequestDelegate];
            }
        }]];
        
        [viewController presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)mnz_removeSharing {
    NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
    
    MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:self];
    NSUInteger outSharesForNodeCount = outSharesForNodeShareList.size.unsignedIntegerValue;
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if (share.user != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:outSharesForNodeMutableArray.count completion:nil];
    for (MEGAShare *share in outSharesForNodeMutableArray) {
        [[MEGASdkManager sharedMEGASdk] shareNode:self withEmail:share.user level:MEGAShareTypeAccessUnkown delegate:shareRequestDelegate];
    }
}

#pragma mark - Utils

- (NSMutableArray *)mnz_parentTreeArray {
    NSMutableArray *parentTreeArray = [[NSMutableArray alloc] init];
    
    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:self] == MEGAShareTypeAccessOwner) {
        uint64_t rootHandle;
        if ([[[MEGASdkManager sharedMEGASdk] nodePathForNode:self] hasPrefix:@"//bin"]) {
            rootHandle = [[MEGASdkManager sharedMEGASdk] rubbishNode].parentHandle;
        } else {
            rootHandle = [[MEGASdkManager sharedMEGASdk] rootNode].handle;
        }
        
        uint64_t tempHandle = self.parentHandle;
        while (tempHandle != rootHandle) {
            MEGANode *tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:tempHandle];
            if (tempNode) {
                [parentTreeArray insertObject:tempNode atIndex:0];
                tempHandle = tempNode.parentHandle;
            } else {
                break;
            }
        }
    } else {
        MEGANode *tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.parentHandle];
        while (tempNode != nil) {
            [parentTreeArray insertObject:tempNode atIndex:0];
            tempNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:tempNode.parentHandle];
        }
    }
    
    return parentTreeArray;
}

- (NSString *)mnz_fileType {
    NSDictionary *fileTypesForExtension = @{   @"3ds":@"3D Scene",
                                               @"3dm":@"3D Model",
                                               @"3fr":@"RAW Image",
                                               @"3g2":@"Multimedia",
                                               @"3gp":@"3D Model",
                                               @"7z":@"7-Zip Compressed",
                                               @"accdb":@"Database",
                                               @"aep":@"After Effects",
                                               @"aet":@"After Effects",
                                               @"ai":@"Illustrator",
                                               @"aif":@"Audio Interchange",
                                               @"aiff":@"Audio Interchange",
                                               @"ait":@"Illustrator",
                                               @"ans":@"ANSI Text File",
                                               @"apk":@"Android App",
                                               @"app":@"Mac OSX App",
                                               @"arw":@"RAW Image",
                                               @"as":@"ActionScript",
                                               @"asc":@"ActionScript Com",
                                               @"ascii":@"ASCII Text",
                                               @"asf":@"Streaming Video",
                                               @"asp":@"Active Server",
                                               @"aspx":@"Active Server",
                                               @"asx":@"Advanced Stream",
                                               @"avi":@"A/V Interleave",
                                               @"bat":@"DOS Batch",
                                               @"bay":@"Casio RAW Image",
                                               @"bmp":@"Bitmap Image",
                                               @"bz2":@"UNIX Compressed",
                                               @"c":@"C/C++ Source Code",
                                               @"cc":@"C++ Source Code",
                                               @"cdr":@"CorelDRAW Image",
                                               @"cgi":@"CGI Script",
                                               @"class":@"Java Class",
                                               @"com":@"DOS Command",
                                               @"cpp":@"C++ Source Code",
                                               @"cr2":@"Raw Image",
                                               @"css":@"CSS Style Sheet",
                                               @"cxx":@"C++ Source Code",
                                               @"dcr":@"RAW Image",
                                               @"db":@"Database",
                                               @"dbf":@"Database",
                                               @"dhtml":@"Dynamic HTML",
                                               @"dll":@"Dynamic Link Library",
                                               @"dng":@"Digital Negative",
                                               @"doc":@"MS Word",
                                               @"docx":@"MS Word",
                                               @"dotx":@"MS Word Template",
                                               @"dwg":@"Drawing DB File",
                                               @"dwt":@"Dreamweaver",
                                               @"dxf":@"DXF Image",
                                               @"eps":@"EPS Image",
                                               @"exe":@"Executable",
                                               @"fff":@"RAW Image",
                                               @"fla":@"Adobe Flash",
                                               @"flac":@"Lossless Audio",
                                               @"flv":@"Flash Video",
                                               @"fnt":@"Windows Font",
                                               @"fon":@"Font",
                                               @"gadget":@"Windows Gadget",
                                               @"gif":@"GIF Image",
                                               @"gpx":@"GPS Exchange",
                                               @"gsheet":@"Spreadsheet",
                                               @"gz":@"Gnu Compressed",
                                               @"h":@"Header",
                                               @"hpp":@"Header",
                                               @"htm":@"HTML Document",
                                               @"html":@"HTML Document",
                                               @"iff":@"Interchange",
                                               @"inc":@"Include",
                                               @"indd":@"Adobe InDesign",
                                               @"iso":@"ISO Image",
                                               @"jar":@"Java Archive",
                                               @"java":@"Java Code",
                                               @"jpeg":@"JPEG Image",
                                               @"jpg":@"JPEG Image",
                                               @"js":@"JavaScript",
                                               @"kml":@"Keyhole Markup",
                                               @"log":@"Log",
                                               @"m3u":@"Media Playlist",
                                               @"m4a":@"MPEG-4 Audio",
                                               @"max":@"3ds Max Scene",
                                               @"mdb":@"MS Access",
                                               @"mef":@"RAW Image",
                                               @"mid":@"MIDI Audio",
                                               @"midi":@"MIDI Audio",
                                               @"mkv":@"MKV Video",
                                               @"mov":@"QuickTime Movie",
                                               @"mp3":@"MP3 Audio",
                                               @"mpeg":@"MPEG Movie",
                                               @"mpg":@"MPEG Movie",
                                               @"mrw":@"Raw Image",
                                               @"msi":@"MS Installer",
                                               @"nb":@"Mathematica",
                                               @"numbers":@"Numbers",
                                               @"nef":@"RAW Image",
                                               @"obj":@"Wavefront",
                                               @"ods":@"Spreadsheet",
                                               @"odt":@"Text Document",
                                               @"otf":@"OpenType Font",
                                               @"ots":@"Spreadsheet",
                                               @"orf":@"RAW Image",
                                               @"pages":@"Pages Doc",
                                               @"pcast":@"Podcast",
                                               @"pdb":@"Database",
                                               @"pdf":@"PDF Document",
                                               @"pef":@"RAW Image",
                                               @"php":@"PHP Code",
                                               @"php3":@"PHP Code",
                                               @"php4":@"PHP Code",
                                               @"php5":@"PHP Code",
                                               @"phtml":@"PHTML Web",
                                               @"pl":@"Perl Script",
                                               @"pls":@"Audio Playlist",
                                               @"png":@"PNG Image",
                                               @"ppj":@"Adobe Premiere",
                                               @"pps":@"MS PowerPoint",
                                               @"ppt":@"MS PowerPoint",
                                               @"pptx":@"MS PowerPoint",
                                               @"prproj":@"Adobe Premiere",
                                               @"ps":@"PostScript",
                                               @"psb":@"Photoshop",
                                               @"psd":@"Photoshop",
                                               @"py":@"Python Script",
                                               @"ra":@"Real Audio",
                                               @"ram":@"Real Audio",
                                               @"rar":@"RAR Compressed",
                                               @"rm":@"Real Media",
                                               @"rtf":@"Rich Text",
                                               @"rw2":@"RAW",
                                               @"rwl":@"RAW Image",
                                               @"sh":@"Bash Shell",
                                               @"shtml":@"Server HTML",
                                               @"sitx":@"X Compressed",
                                               @"sql":@"SQL Database",
                                               @"srf":@"Sony RAW Image",
                                               @"srt":@"Subtitle",
                                               @"svg":@"Vector Image",
                                               @"svgz":@"Vector Image",
                                               @"swf":@"Flash Movie",
                                               @"tar":@"Archive",
                                               @"tbz":@"Compressed",
                                               @"tga":@"Targa Graphic",
                                               @"tgz":@"Compressed",
                                               @"tif":@"TIF Image",
                                               @"tiff":@"TIFF Image",
                                               @"torrent":@"Torrent",
                                               @"ttf":@"TrueType Font",
                                               @"txt":@"Text Document",
                                               @"vcf":@"vCard",
                                               @"wav":@"Wave Audio",
                                               @"webm":@"WebM Video",
                                               @"wma":@"WM Audio",
                                               @"wmv":@"WM Video",
                                               @"wpd":@"WordPerfect",
                                               @"wps":@"MS Works",
                                               @"xhtml":@"XHTML Web",
                                               @"xlr":@"MS Works",
                                               @"xls":@"MS Excel",
                                               @"xlsx":@"MS Excel",
                                               @"xlt":@"MS Excel",
                                               @"xltm":@"MS Excel",
                                               @"xml":@"XML Document",
                                               @"zip":@"ZIP Archive",
                                               @"mp4":@"MP4 Video"};
    
    NSString *fileType = [fileTypesForExtension objectForKey:self.name.pathExtension];
    if (fileType.length == 0) {
        fileType = [NSString stringWithFormat:@"%@ %@", self.name.pathExtension.uppercaseString, AMLocalizedString(@"file", nil).capitalizedString];
    }
    
    return fileType;
}

#pragma mark - Versions

- (NSInteger)mnz_numberOfVersions {
    return ([[MEGASdkManager sharedMEGASdk] hasVersionsForNode:self]) ? ([[MEGASdkManager sharedMEGASdk] numberOfVersionsForNode:self]) : 0;
}


- (NSArray *)mnz_versions {
    return [[[MEGASdkManager sharedMEGASdk] versionsForNode:self] mnz_nodesArrayFromNodeList];
}

- (long long)mnz_versionsSize {
    long long totalSize = 0;
    NSArray *versions = [self mnz_versions];
    for (MEGANode *versionNode in versions) {
        totalSize += versionNode.size.longLongValue;
    }
    
    return totalSize;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSString *nodeName = textField.text;
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextRange *textRange;
    
    switch (self.type) {
        case MEGANodeTypeFile: {
            if ([nodeName.pathExtension isEqualToString:@""] && [nodeName isEqualToString:nodeName.stringByDeletingPathExtension]) { //File without extension
                UITextPosition *end = textField.endOfDocument;
                textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            } else {
                NSRange filenameRange = [nodeName rangeOfString:@"." options:NSBackwardsSearch];
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:filenameRange.location];
                textRange = [textField textRangeFromPosition:beginning  toPosition:beforeExtension];
            }
            textField.selectedTextRange = textRange;
            break;
        }
            
        case MEGANodeTypeFolder: {
            UITextPosition *end = textField.endOfDocument;
            textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shouldChangeCharacters = YES;
    switch (self.type) {
        case MEGANodeTypeFile:
        case MEGANodeTypeFolder:
            shouldChangeCharacters = YES;
            break;
            
        default:
            shouldChangeCharacters = NO;
            break;
    }
    
    return shouldChangeCharacters;
}

- (void)renameAlertTextFieldDidChange:(UITextField *)sender {
    
    UIAlertController *renameAlertController = (UIAlertController*)[UIApplication mnz_visibleViewController];
    if (renameAlertController) {
        UITextField *textField = renameAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = renameAlertController.actions.lastObject;
        BOOL enableRightButton = NO;
        
        NSString *newName = textField.text;
        NSString *nodeNameString = self.name;
        
        if (self.isFile || self.isFolder) {
            BOOL containsInvalidChars = [sender.text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"|*/:<>?\"\\"]].length;
            if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString] || newName.mnz_isEmpty || containsInvalidChars) {
                enableRightButton = NO;
            } else {
                enableRightButton = YES;
            }
            sender.textColor = containsInvalidChars ? UIColor.mnz_redD90007 : UIColor.darkTextColor;
        }
        
        rightButtonAction.enabled = enableRightButton;
    }
}

- (void)mnz_copyToGalleryFromTemporaryPath:(NSString *)path {
    if (self.name.mnz_isVideoPathExtension && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    
    if (self.name.mnz_isImagePathExtension) {
        NSURL *imageURL = [NSURL fileURLWithPath:path];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *assetCreationRequest = [PHAssetCreationRequest creationRequestForAsset];
            [assetCreationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
            
        } completionHandler:^(BOOL success, NSError * _Nullable nserror) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            if (nserror) {
                MEGALogError(@"Add asset to camera roll: %@ (Domain: %@ - Code:%ld)", nserror.localizedDescription, nserror.domain, nserror.code);
            }
        }];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        MEGALogError(@"Save video to Camera roll: %@ (Domain: %@ - Code:%ld)", error.localizedDescription, error.domain, error.code);
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    }
}

@end
