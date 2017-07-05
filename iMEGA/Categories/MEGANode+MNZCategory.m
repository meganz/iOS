
#import "MEGANode+MNZCategory.h"

#import "MWPhotoBrowser.h"

#import "Helper.h"
#import "MEGAAVViewController.h"
#import "MEGANode.h"
#import "MEGAQLPreviewController.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

#import "PreviewDocumentViewController.h"

@implementation MEGANode (MNZCategory)

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode {
    int offsetIndex = 0;
    NSMutableArray *imagesMutableArray = [[NSMutableArray alloc] init];
    
    NSUInteger nodesCount = nodesArray.count;
    for (NSUInteger i = 0; i < nodesCount; i++) {
        MEGANode *node = [nodesArray objectAtIndex:i];
        if (node.name.mnz_isImagePathExtension && node.isFile) {
            MWPhoto *photo = [[MWPhoto alloc] initWithNode:node];
            photo.isFromFolderLink = isFolderLink;
            [imagesMutableArray addObject:photo];
            if (node.handle == self.handle) {
                offsetIndex = (int)imagesMutableArray.count - 1;
            }
        }
    }
    
    MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithPhotos:imagesMutableArray];
    photoBrowser.displayActionButton = YES;
    photoBrowser.displayNavArrows = YES;
    photoBrowser.displaySelectionButtons = NO;
    photoBrowser.zoomPhotosToFill = YES;
    photoBrowser.alwaysShowControls = NO;
    photoBrowser.enableGrid = YES;
    photoBrowser.startOnGrid = NO;
    photoBrowser.displayMode = displayMode;
    
    [navigationController pushViewController:photoBrowser animated:YES];
    
    [photoBrowser showNextPhotoAnimated:YES];
    [photoBrowser showPreviousPhotoAnimated:YES];
    [photoBrowser setCurrentPhotoIndex:offsetIndex];
}

- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink {
    MEGASdk *api = isFolderLink ? [MEGASdkManager sharedMEGASdkFolder] : [MEGASdkManager sharedMEGASdk];
    
    MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:self]];
    
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
            [navigationController presentViewController:megaAVViewController animated:YES completion:nil];
            return;
        } else {
            MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithFilePath:previewDocumentPath];
            [navigationController presentViewController:previewController animated:YES completion:nil];
        }
    } else if (self.name.mnz_isAudiovisualContentUTI && [api httpServerStart:YES port:4443]) {
        MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithNode:self folderLink:isFolderLink];
        [navigationController presentViewController:megaAVViewController animated:YES completion:nil];
    } else {
        if ([[[api downloadTransfers] size] integerValue] > 0) {
            UIAlertController *documentOpeningAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"documentOpening_alertTitle", @"Alert title shown when you try to open a Cloud Drive document and is not posible because there's some active download") message:AMLocalizedString(@"documentOpening_alertMessage", @"Alert message shown when you try to open a Cloud Drive document and is not posible because there's some active download") preferredStyle:UIAlertControllerStyleAlert];
            
            [documentOpeningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            [navigationController presentViewController:documentOpeningAlertController animated:YES completion:nil];
        } else {
            if (![Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
                return;
            }
            
            PreviewDocumentViewController *previewDocumentVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentID"];
            previewDocumentVC.node = self;
            previewDocumentVC.api = api;
            [navigationController pushViewController:previewDocumentVC animated:YES];
        }
    }
}

@end
