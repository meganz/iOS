
#import "MEGANode+MNZCategory.h"

#import "Helper.h"
#import "MEGAAVViewController.h"
#import "MEGANode.h"
#import "MEGAQLPreviewController.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

#import "PreviewDocumentViewController.h"

@implementation MEGANode (MNZCategory)

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode {
    [self mnz_openImageInNavigationController:navigationController withNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:YES];
}

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin {
    MWPhotoBrowser *photoBrowser = [self mnz_photoBrowserWithNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:enableMoveToRubbishBin];
    [navigationController pushViewController:photoBrowser animated:YES];
}

- (MWPhotoBrowser *)mnz_photoBrowserWithNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin {
    return [self mnz_photoBrowserWithNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:enableMoveToRubbishBin hideControls:NO];
}

- (MWPhotoBrowser *)mnz_photoBrowserWithNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin hideControls:(BOOL)hideControls {
    NSInteger offsetIndex = 0;
    NSMutableArray *imagesMutableArray = [[NSMutableArray alloc] init];
    
    NSUInteger nodesCount = nodesArray.count;
    for (NSUInteger i = 0; i < nodesCount; i++) {
        MEGANode *node = [nodesArray objectAtIndex:i];
        if (node.name.mnz_isImagePathExtension && node.isFile) {
            MWPhoto *photo = [[MWPhoto alloc] initWithNode:node];
            photo.isFromFolderLink = isFolderLink;
            [imagesMutableArray addObject:photo];
            if (node.handle == self.handle) {
                offsetIndex = imagesMutableArray.count - 1;
            }
        }
    }
    
    MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithPhotos:imagesMutableArray];
    photoBrowser.displayActionButton = YES;
    photoBrowser.displayNavArrows = YES;
    photoBrowser.displaySelectionButtons = NO;
    photoBrowser.zoomPhotosToFill = YES;
    photoBrowser.alwaysShowControls = NO;
    photoBrowser.enableGrid = (imagesMutableArray.count > 1);
    photoBrowser.startOnGrid = NO;
    photoBrowser.displayMode = displayMode;
    photoBrowser.enableMoveToRubbishBin = enableMoveToRubbishBin;
    
    [photoBrowser showNextPhotoAnimated:YES];
    [photoBrowser showPreviousPhotoAnimated:YES];
    [photoBrowser setCurrentPhotoIndex:offsetIndex];
    
    if (hideControls) {
        [photoBrowser setControlsHidden:YES animated:NO permanent:NO];
    }
    
    return photoBrowser;
}

- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink {
    UIViewController *viewController = [self mnz_viewControllerForNodeInFolderLink:isFolderLink];
    if (viewController) {
        if (viewController.class == PreviewDocumentViewController.class) {
            [navigationController pushViewController:viewController animated:YES];
        } else {
            [navigationController presentViewController:viewController animated:YES completion:nil];
        }
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
            NSURL *path = [NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingString:offlineNodeExist.localPath]];
            MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:path];
            return megaAVViewController;
        } else {
            MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithFilePath:previewDocumentPath];
            return previewController;
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
            if (![Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
                return nil;
            }
            
            PreviewDocumentViewController *previewDocumentVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentID"];
            previewDocumentVC.node = self;
            previewDocumentVC.api = api;
            return previewDocumentVC;
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

@end
