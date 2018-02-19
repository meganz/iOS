
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

#import "MEGAMoveRequestDelegate.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGARenameRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"

#import "UIApplication+MNZCategory.h"

@implementation MEGANode (MNZCategory)

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode {
    [self mnz_openImageInNavigationController:navigationController withNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:YES];
}

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin {
    MEGAPhotoBrowserViewController *photoBrowserVC = [self mnz_photoBrowserWithNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:enableMoveToRubbishBin];
    [navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
}

- (MEGAPhotoBrowserViewController *)mnz_photoBrowserWithNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin {
    return [self mnz_photoBrowserWithNodes:nodesArray folderLink:isFolderLink displayMode:displayMode enableMoveToRubbishBin:enableMoveToRubbishBin hideControls:NO];
}

- (MEGAPhotoBrowserViewController *)mnz_photoBrowserWithNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin hideControls:(BOOL)hideControls {
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

- (BOOL)mnz_downloadNode {
    MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:self api:[MEGASdkManager sharedMEGASdk]];
    if (!offlineNodeExist) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            if (![Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:NO]) {
                return NO;
            } else {
                [Helper downloadNode:self folderPath:[Helper relativePathForOffline] isFolderLink:NO];
                return YES;
            }
        } else {
            return NO;
        }
    } else {
        return YES;
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
            if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString] || newName.mnz_isEmpty) {
                enableRightButton = NO;
            } else {
                enableRightButton = YES;
            }
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

- (BOOL)hasVersions {
    return [[MEGASdkManager sharedMEGASdk] hasVersionsForNode:self];
}

- (NSInteger)numberOfVersions {
    if ([self hasVersions]) {
        return [[MEGASdkManager sharedMEGASdk] numberOfVersionsForNode:self];
    } else {
        return 0;
    }
}

@end
