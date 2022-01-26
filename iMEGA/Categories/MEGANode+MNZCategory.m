
#import "MEGANode+MNZCategory.h"

#import <Photos/Photos.h>

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGALinkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGARenameRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSAttributedString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "BrowserViewController.h"
#import "CloudDriveViewController.h"
#import "MainTabBarController.h"
#import "MEGAAVViewController.h"
#import "MEGANavigationController.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGAQLPreviewController.h"
#import "OnboardingViewController.h"
#import "PreviewDocumentViewController.h"
#import "SharedItemsViewController.h"
#import "SendToViewController.h"
#import "MEGAStartUploadTransferDelegate.h"

@implementation MEGANode (MNZCategory)

- (MEGANode *)parent {
    return [MEGASdkManager.sharedMEGASdk nodeForHandle:self.parentHandle];
}

- (void)navigateToParentAndPresent {
    MainTabBarController *mainTBC = (MainTabBarController *) UIApplication.sharedApplication.delegate.window.rootViewController;
    
    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:self] != MEGAShareTypeAccessOwner) { // Node from inshare
        mainTBC.selectedIndex = TabTypeSharedItems;
        SharedItemsViewController *sharedItemsVC = mainTBC.childViewControllers[TabTypeSharedItems].childViewControllers.firstObject;
        [sharedItemsVC selectSegment:0]; // Incoming
    } else {
        mainTBC.selectedIndex = TabTypeCloudDrive;
    }
    
    UINavigationController *navigationController = [mainTBC.childViewControllers objectAtIndex:mainTBC.selectedIndex];
    [navigationController popToRootViewControllerAnimated:NO];
    
    NSArray *parentTreeArray = self.mnz_parentTreeArray;
    for (MEGANode *node in parentTreeArray) {
        CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        cloudDriveVC.parentNode = node;        
        [navigationController pushViewController:cloudDriveVC animated:NO];
    }
    
    switch (self.type) {
        case MEGANodeTypeFolder:
        case MEGANodeTypeRubbish: {
            CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = self;            
            [navigationController pushViewController:cloudDriveVC animated:NO];
            break;
        }
            
        case MEGANodeTypeFile: {
            if (self.name.mnz_isVisualMediaPathExtension) {
                MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.parentHandle];
                MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:parentNode];
                NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaNodesMutableArrayFromNodeList];
                
                DisplayMode displayMode = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self] == MEGAShareTypeAccessOwner ? DisplayModeCloudDrive : DisplayModeSharedItem;
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:displayMode presentingNode:self preferredIndex:0];
                
                [navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
            } else {
                [self mnz_openNodeInNavigationController:navigationController folderLink:NO fileLink:nil];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink fileLink:(NSString *)fileLink {
    if (self.name.mnz_isMultimediaPathExtension && MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
        [Helper cannotPlayContentDuringACallAlert];
    } else {
        if (self.name.mnz_isMultimediaPathExtension && !self.name.mnz_isVideoPathExtension && self.mnz_isPlayable) {
            UIViewController *presenterVC = [navigationController.viewControllers lastObject];
            if ([presenterVC conformsToProtocol:@protocol(AudioPlayerPresenterProtocol)] && [AudioPlayerManager.shared isPlayerDefined] && [AudioPlayerManager.shared isPlayerAlive] && (isFolderLink || (!isFolderLink && fileLink == nil))) {
                [AudioPlayerManager.shared initMiniPlayerWithNode:self fileLink:fileLink filePaths:nil isFolderLink:isFolderLink presenter:presenterVC shouldReloadPlayerInfo:YES shouldResetPlayer:YES];
            } else {
                [AudioPlayerManager.shared initFullScreenPlayerWithNode:self fileLink:fileLink filePaths:nil isFolderLink:isFolderLink presenter:presenterVC];
            }
        } else {
            UIViewController *viewController = [self mnz_viewControllerForNodeInFolderLink:isFolderLink fileLink:fileLink inViewController:navigationController.viewControllers.lastObject];
            if (viewController) {
                [navigationController presentViewController:viewController animated:YES completion:nil];
            }
        }
    }
}

- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink fileLink:(NSString *)fileLink {
    return [self mnz_viewControllerForNodeInFolderLink:isFolderLink fileLink:fileLink inViewController:nil];
}

- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink fileLink:(NSString *)fileLink inViewController:(UIViewController *)viewController {
    MEGASdk *api = isFolderLink ? [MEGASdkManager sharedMEGASdkFolder] : [MEGASdkManager sharedMEGASdk];
    MEGASdk *apiForStreaming = [MEGASdkManager sharedMEGASdk].isLoggedIn ? [MEGASdkManager sharedMEGASdk] : [MEGASdkManager sharedMEGASdkFolder];
    
    MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:self];
    
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
            AVURLAsset *asset = [AVURLAsset assetWithURL:path];
            
            if (asset.playable) {
                MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:path];
                return megaAVViewController;
            } else {
                MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithFilePath:previewDocumentPath];
                previewController.currentPreviewItemIndex = 0;
                
                return previewController;
            }
        } else if ([viewController conformsToProtocol:@protocol(TextFileEditable)] && self.name.mnz_isEditableTextFilePathExtension) {
            NSStringEncoding encode;
            NSString *textContent = [[NSString alloc] initWithContentsOfFile:previewDocumentPath usedEncoding:&encode error:nil];
            if (textContent != nil) {
                TextFile *textFile = [[TextFile alloc] initWithFileName:self.name content:textContent size: self.size.unsignedIntValue encode:encode];
                return [[TextEditorViewRouter.alloc initWithTextFile:textFile textEditorMode:TextEditorModeView node:self presenter:viewController.navigationController] build];
            }
        }
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"DocumentPreviewer" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
        PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        previewController.api = api;
        previewController.filePath = previewDocumentPath;
        previewController.node = isFolderLink ? [api authorizeNode:self] : self;
        previewController.isLink = isFolderLink;
        previewController.fileLink = fileLink;
        
        return navigationController;
        
    } else if (self.name.mnz_isMultimediaPathExtension && [apiForStreaming httpServerStart:NO port:4443]) {
        if (self.mnz_isPlayable) {
            MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithNode:self folderLink:isFolderLink apiForStreaming:apiForStreaming];
            return megaAVViewController;
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"fileNotSupported", @"Alert title shown when users try to stream an unsupported audio/video file") message:NSLocalizedString(@"message_fileNotSupported", @"Alert message shown when users try to stream an unsupported audio/video file") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            return alertController;
        }
    } else {
        if ([Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
            if ([viewController conformsToProtocol:@protocol(TextFileEditable)] && self.name.mnz_isEditableTextFilePathExtension) {
                TextFile *textFile = [[TextFile alloc] initWithFileName:self.name size: self.size.unsignedIntValue];
                return [[TextEditorViewRouter.alloc initWithTextFile:textFile textEditorMode:TextEditorModeLoad node:self presenter:viewController.navigationController] build];
            }
            
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"DocumentPreviewer" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
            PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
            navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
            previewController.node = isFolderLink ? [api authorizeNode:self] : self;
            previewController.api = api;
            previewController.isLink = isFolderLink;
            previewController.fileLink = fileLink;
            
            return navigationController;
        }
        return nil;
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
    
    [NSFileManager.defaultManager mnz_removeItemAtPath:tmpImagePath];
}

#pragma mark - Actions

- (void)mnz_editTextFileInViewController:(UIViewController *)viewController {
    MEGANavigationController *nav = (MEGANavigationController *)[self mnz_viewControllerForNodeInFolderLink:NO fileLink:nil inViewController:viewController];
    if (nav.viewControllers.lastObject.class == TextEditorViewController.class) {
        TextEditorViewController *tevc = nav.viewControllers.lastObject;
        [tevc editAfterOpen];
    } else {
        PreviewDocumentViewController *pdvc = nav.viewControllers.lastObject;
        pdvc.showUnknownEncodeHud = YES;
    }
    [viewController.navigationController presentViewController:nav animated:YES completion:nil];
}

- (BOOL)mnz_downloadNode {
    return [self mnz_downloadNodeWithApi:[MEGASdkManager sharedMEGASdk]];
}

- (BOOL)mnz_downloadNodeTopPriority {
    return [self mnz_downloadNodeWithApi:[MEGASdkManager sharedMEGASdk] isTopPriority:YES];
}

- (void)mnz_labelActionSheetInViewController:(UIViewController *)viewController {
    UIImageView *checkmarkImageView = [UIImageView.alloc initWithImage:[UIImage imageNamed:@"turquoise_checkmark"]];
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Red", @"A user can mark a folder or file with its own colour, in this case “Red”.") detail:nil accessoryView:(self.label == MEGANodeLabelRed ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Red"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelRed) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelRed];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Orange", @"A user can mark a folder or file with its own colour, in this case “Orange”.") detail:nil accessoryView:(self.label == MEGANodeLabelOrange ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Orange"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelOrange) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelOrange];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Yellow", @"A user can mark a folder or file with its own colour, in this case “Yellow”.") detail:nil accessoryView:(self.label == MEGANodeLabelYellow ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Yellow"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelYellow) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelYellow];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Green", @"A user can mark a folder or file with its own colour, in this case “Green”.") detail:nil accessoryView:(self.label == MEGANodeLabelGreen ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Green"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelGreen) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelGreen];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Blue", @"A user can mark a folder or file with its own colour, in this case “Blue”.") detail:nil accessoryView:(self.label == MEGANodeLabelBlue ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Blue"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelBlue) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelBlue];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Purple", @"A user can mark a folder or file with its own colour, in this case “Purple”.") detail:nil accessoryView:(self.label == MEGANodeLabelPurple ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Purple"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelPurple) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelPurple];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Grey", @"A user can mark a folder or file with its own colour, in this case “Grey”.") detail:nil accessoryView:(self.label == MEGANodeLabelGrey ? checkmarkImageView : nil) image:[UIImage imageNamed:@"Grey"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelGrey) [MEGASdkManager.sharedMEGASdk setNodeLabel:self label:MEGANodeLabelGrey];
    }]];
    
    if (self.label != MEGANodeLabelUnknown) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Remove Label", @"Option shown on the action sheet where you can choose or change the color label of a file or folder. The 'Remove Label' only appears if you have previously selected a label") detail:nil image:[UIImage imageNamed:@"delete"] style:UIAlertActionStyleDestructive actionHandler:^{
            [MEGASdkManager.sharedMEGASdk resetNodeLabel:self];
        }]];
    }
    
    ActionSheetViewController *labelsActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:viewController.navigationItem.rightBarButtonItems.firstObject];
    [viewController presentViewController:labelsActionSheet animated:YES completion:nil];
}

- (BOOL)mnz_downloadNodeWithApi:(MEGASdk *)api {
    return [self mnz_downloadNodeWithApi:api isTopPriority:NO];
}

- (BOOL)mnz_downloadNodeWithApi:(MEGASdk *)api isTopPriority:(BOOL)isTopPriority {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        BOOL isFolderLink = api != [MEGASdkManager sharedMEGASdk];
        if ([Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
            [Helper downloadNode:self folderPath:[Helper relativePathForOffline] isFolderLink:isFolderLink isTopPriority:isTopPriority];
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)mnz_saveToPhotos {
    [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"saveToPhotos"] status:NSLocalizedString(@"Saving to Photos…", @"Text shown when starting the process to save a photo or video to Photos app")];
            [SVProgressHUD dismissWithDelay:1.0];
            NSString *temporaryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:self.base64Handle] stringByAppendingPathComponent:self.name];
            NSString *temporaryFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:temporaryPath];
            if ([temporaryFingerprint isEqualToString:self.fingerprint]) {
                [self mnz_copyToGalleryFromTemporaryPath:temporaryPath];
            } else if (MEGAReachabilityManager.isReachableHUDIfNot) {
                NSString *downloadsDirectory = [NSFileManager.defaultManager downloadsDirectory];
                downloadsDirectory = downloadsDirectory.mnz_relativeLocalPath;
                NSString *offlineNameString = [MEGASdkManager.sharedMEGASdkFolder escapeFsIncompatible:self.name destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
                NSString *localPath = [downloadsDirectory stringByAppendingPathComponent:offlineNameString];
                [MEGASdkManager.sharedMEGASdk startDownloadNode:self localPath:localPath appData:[[NSString new] mnz_appDataToSaveInPhotosApp]];
            }
        } else {
            [DevicePermissionsHelper alertPhotosPermission];
        }
    }];
}

- (void)mnz_renameNodeInViewController:(UIViewController *)viewController {
    [self mnz_renameNodeInViewController:viewController completion:nil];
}

- (void)mnz_renameNodeInViewController:(UIViewController *)viewController completion:(void(^)(MEGARequest *request))completion {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *renameAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") message:NSLocalizedString(@"renameNodeMessage", @"Hint text to suggest that the user have to write the new name for the file or folder") preferredStyle:UIAlertControllerStyleAlert];
        
        [renameAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = self.name;
            textField.text = self.name;
            textField.returnKeyType = UIReturnKeyDone;
            textField.delegate = self;
            [textField addTarget:self action:@selector(renameAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [renameAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *renameAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *alertViewTextField = renameAlertController.textFields.firstObject;
                MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.parentHandle];
                MEGANodeList *childrenNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:parentNode searchString:alertViewTextField.text recursive:NO];
                
                if (self.isFolder) {
                    if ([childrenNodeList mnz_existsFolderWithName:alertViewTextField.text]) {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"There is already a folder with the same name", @"A tooltip message which is shown when a folder name is duplicated during renaming or creation.")];
                    } else {
                        MEGARenameRequestDelegate *delegate = [[MEGARenameRequestDelegate alloc] initWithCompletion:completion];
                        [[MEGASdkManager sharedMEGASdk] renameNode:self newName:alertViewTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds delegate:delegate];
                    }
                } else {
                    if ([childrenNodeList mnz_existsFileWithName:alertViewTextField.text]) {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"There is already a file with the same name", @"A tooltip message which shows when a file name is duplicated during renaming.")];
                    } else {
                        MEGARenameRequestDelegate *delegate = [[MEGARenameRequestDelegate alloc] initWithCompletion:completion];
                        [[MEGASdkManager sharedMEGASdk] renameNode:self newName:alertViewTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds delegate:delegate];
                    }
                }
            }
        }];
        renameAlertAction.enabled = NO;
        [renameAlertController addAction:renameAlertAction];
        
        [viewController presentViewController:renameAlertController animated:YES completion:nil];
    }
}

- (void)mnz_askToMoveToTheRubbishBinInViewController:(UIViewController *)viewController {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        void (^completion)(void) = nil;
        if (![viewController isKindOfClass:MEGAPhotoBrowserViewController.class]) {
            completion = ^{
                [viewController dismissViewControllerAnimated:YES completion:nil];
            };
        }
        [self mnz_moveToTheRubbishBinWithCompletion:completion];
    }
}

- (void)mnz_moveToTheRubbishBinWithCompletion:(void (^)(void))completion {
    if (MEGAReachabilityManager.isReachableHUDIfNot) {
        MEGAMoveRequestDelegate *moveRequestDelegate = [MEGAMoveRequestDelegate.alloc initToMoveToTheRubbishBinWithFiles:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:completion];
        [MEGASdkManager.sharedMEGASdk moveNode:self newParent:MEGASdkManager.sharedMEGASdk.rubbishNode delegate:moveRequestDelegate];
    }
}

- (void)mnz_removeInViewController:(UIViewController *)viewController {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = NSLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
        NSString *alertMessage = (self.type == MEGANodeTypeFolder) ? NSLocalizedString(@"removeFolderToRubbishBinMessage", @"Alert message shown on the Rubbish Bin when you want to remove '1 folder'") : NSLocalizedString(@"removeFileToRubbishBinMessage", @"Alert message shown on the Rubbish Bin when you want to remove '1 file'");
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                void (^completion)(void) = nil;
                if (![viewController isKindOfClass:MEGAPhotoBrowserViewController.class]) {
                    completion = ^{
                        if (self.isFolder) {
                            [MEGAStore.shareInstance deleteCloudAppearancePreferenceWithHandle:self.handle];
                        }
                        
                        [viewController dismissViewControllerAnimated:YES completion:nil];
                    };
                }
                MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:1 files:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:completion];
                [[MEGASdkManager sharedMEGASdk] removeNode:self delegate:removeRequestDelegate];
            }
        }]];
        
        [viewController presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)mnz_leaveSharingInViewController:(UIViewController *)viewController {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = NSLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
        NSString *alertMessage = NSLocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
        
        MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:self];
        NSUInteger outSharesForNodeCount = outSharesForNodeShareList.size.unsignedIntegerValue;
        for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
            MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
            if (share.user != nil) {
                [outSharesForNodeMutableArray addObject:share];
            }
        }
        NSString *alertMessage = outSharesForNodeMutableArray.count == 1 ? NSLocalizedString(@"removeOneShareOneContactMessage", nil) : [NSString stringWithFormat:NSLocalizedString(@"removeOneShareMultipleContactsMessage", nil), outSharesForNodeMutableArray.count];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"removeSharing", nil) message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:outSharesForNodeMutableArray.count completion:nil];
            for (MEGAShare *share in outSharesForNodeMutableArray) {
                [[MEGASdkManager sharedMEGASdk] shareNode:self withEmail:share.user level:MEGAShareTypeAccessUnknown delegate:shareRequestDelegate];
            }
        }]];
        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)mnz_restore {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.restoreHandle];
        MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initWithFiles:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:nil];
        moveRequestDelegate.restore = YES;
        [[MEGASdkManager sharedMEGASdk] moveNode:self newParent:restoreNode delegate:moveRequestDelegate];
    }
}

- (void)mnz_removeLink {
    MEGAExportRequestDelegate *requestDelegate = [MEGAExportRequestDelegate.alloc initWithCompletion:^(MEGARequest *request) {
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"linkRemoved", @"Message shown when the links to a file or folder has been removed")];
    } multipleLinks:NO];
    
    [MEGASdkManager.sharedMEGASdk disableExportNode:self delegate:requestDelegate];
}

- (void)mnz_sendToChatInViewController:(UIViewController *)viewController {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"SendToNavigationControllerID"];
    SendToViewController *sendToViewController = navigationController.viewControllers.firstObject;
    sendToViewController.nodes = @[self];
    sendToViewController.sendMode = SendModeCloud;
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)mnz_moveInViewController:(UIViewController *)viewController {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [viewController presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.selectedNodesArray = @[self];
    browserVC.browserAction = BrowserActionMove;
    
    [viewController setEditing:NO animated:YES];
}

- (void)mnz_copyInViewController:(UIViewController *)viewController {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [viewController presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.selectedNodesArray = @[self];
    browserVC.browserAction = BrowserActionCopy;
    
    [viewController setEditing:NO animated:YES];
}

- (void)mnz_showNodeVersionsInViewController:(UIViewController *)viewController {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Node" bundle:nil] instantiateViewControllerWithIdentifier:@"NodeVersionsNC"];
    NodeVersionsViewController *versionController = navigationController.viewControllers.firstObject;
    versionController.node = self;
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - File links

- (void)mnz_fileLinkDownloadFromViewController:(UIViewController *)viewController isFolderLink:(BOOL)isFolderLink {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
            return;
        }

        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            [Helper downloadNode:self folderPath:Helper.relativePathForOffline isFolderLink:isFolderLink];
            
            [viewController dismissViewControllerAnimated:YES completion:^{
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", nil)];
            }];
        } else {
            if (isFolderLink) {
                [MEGALinkManager.nodesFromLinkMutableArray addObject:self];
                MEGALinkManager.selectedOption = LinkOptionDownloadFolderOrNodes;
            } else {
                [MEGALinkManager.nodesFromLinkMutableArray addObject:self];
                MEGALinkManager.selectedOption = LinkOptionDownloadNode;
            }
            
            OnboardingViewController *onboardingVC = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault];
            if (viewController.navigationController) {
                [viewController.navigationController pushViewController:onboardingVC animated:YES];
            } else {
                MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:onboardingVC];
                [navigationController addRightCancelButton];
                [viewController presentViewController:navigationController animated:YES completion:nil];
            }
        }
    }
}

- (void)presentBrowserViewControllerWithBrowserAction:(BrowserAction)browserAction {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.selectedNodesArray = [NSArray arrayWithObject:self];
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    
    browserVC.browserAction = browserAction;
}

- (void)mnz_fileLinkImportFromViewController:(UIViewController *)viewController isFolderLink:(BOOL)isFolderLink {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            BrowserAction browserAction = isFolderLink ? BrowserActionImportFromFolderLink : BrowserActionImport;
            if (isFolderLink) {
                [self presentBrowserViewControllerWithBrowserAction:browserAction];
            } else {
                [viewController dismissViewControllerAnimated:YES completion:^{
                    [self presentBrowserViewControllerWithBrowserAction:browserAction];
                }];
            }
        } else {
            if (isFolderLink) {
                [MEGALinkManager.nodesFromLinkMutableArray addObject:self];
                MEGALinkManager.selectedOption = LinkOptionImportFolderOrNodes;
            } else {
                [MEGALinkManager.nodesFromLinkMutableArray addObject:self];
                MEGALinkManager.selectedOption = LinkOptionImportNode;
            }
            
            OnboardingViewController *onboardingVC = [OnboardingViewController instanciateOnboardingWithType:OnboardingTypeDefault];
            if (viewController.navigationController) {
                [viewController.navigationController pushViewController:onboardingVC animated:YES];
            } else {
                MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:onboardingVC];
                [navigationController addRightCancelButton];
                [viewController presentViewController:navigationController animated:YES completion:nil];
            }
        }
    }
}

#pragma mark - Utils

- (MEGANode *)mnz_firstbornInShareOrOutShareParentNode {
    MEGANode *parentNode = self;
    while (parentNode != nil) {
        if (parentNode.isInShare || parentNode.isOutShare) {
            break;
        }
        
        parentNode = [MEGASdkManager.sharedMEGASdk parentNodeForNode:parentNode];
    }
    
    return parentNode;
}

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
    NSDictionary *fileTypesForExtension = @{   @"3ds":@"general.filetype.3ds",
                                               @"3dm":@"general.filetype.3DModel",
                                               @"3fr":@"general.filetype.rawImage",
                                               @"3g2":@"general.filetype.3g2",
                                               @"3gp":@"general.filetype.3DModel",
                                               @"7z":@"general.filetype.7z",
                                               @"accdb":@"general.filetype.database",
                                               @"aep":@"After Effects",
                                               @"aet":@"After Effects",
                                               @"ai":@"Illustrator",
                                               @"aif":@"general.filetype.audioInterchange",
                                               @"aiff":@"general.filetype.audioInterchange",
                                               @"ait":@"Illustrator",
                                               @"ans":@"general.filetype.ans",
                                               @"apk":@"general.filetype.apk",
                                               @"app":@"general.filetype.app",
                                               @"arw":@"general.filetype.rawImage",
                                               @"as":@"ActionScript",
                                               @"asc":@"ActionScript Com",
                                               @"ascii":@"general.filetype.ascii",
                                               @"asf":@"general.filetype.asf",
                                               @"asp":@"Active Server",
                                               @"aspx":@"Active Server",
                                               @"asx":@"general.filetype.asx",
                                               @"avi":@"general.filetype.avi",
                                               @"bat":@"general.filetype.bat",
                                               @"bay":@"general.filetype.bay",
                                               @"bmp":@"general.filetype.bmp",
                                               @"bz2":@"general.filetype.bz2",
                                               @"c":@"general.filetype.c",
                                               @"cc":@"general.filetype.cpp",
                                               @"cdr":@"general.filetype.cdr",
                                               @"cgi":@"general.filetype.cgi",
                                               @"class":@"general.filetype.class",
                                               @"com":@"general.filetype.com",
                                               @"cpp":@"general.filetype.cpp",
                                               @"cr2":@"general.filetype.rawImage",
                                               @"css":@"general.filetype.css",
                                               @"cxx":@"general.filetype.cpp",
                                               @"db":@"general.filetype.database",
                                               @"dbf":@"general.filetype.database",
                                               @"dcr":@"general.filetype.rawImage",
                                               @"dhtml":@"general.filetype.dhtml",
                                               @"dll":@"general.filetype.dll",
                                               @"dng":@"Digital Negative",
                                               @"doc":@"MS Word",
                                               @"docx":@"MS Word",
                                               @"dotx":@"general.filetype.wordTemplate",
                                               @"dwg":@"Drawing DB File",
                                               @"dwt":@"Dreamweaver",
                                               @"dxf":@"general.filetype.dxf",
                                               @"eps":@"general.filetype.eps",
                                               @"exe":@"general.filetype.exe",
                                               @"fff":@"general.filetype.rawImage",
                                               @"fla":@"Adobe Flash",
                                               @"flac":@"general.filetype.flac",
                                               @"flv":@"general.filetype.flv",
                                               @"fnt":@"general.filetype.fnt",
                                               @"fon":@"general.filetype.fon",
                                               @"gadget":@"general.filetype.gadget",
                                               @"gif":@"general.filetype.gif",
                                               @"gpx":@"general.filetype.gpx",
                                               @"gsheet":@"general.filetype.spreadsheet",
                                               @"gz":@"general.filetype.gz",
                                               @"h":@"general.filetype.header",
                                               @"hpp":@"general.filetype.header",
                                               @"htm":@"general.filetype.htmlDocument",
                                               @"html":@"general.filetype.htmlDocument",
                                               @"iff":@"general.filetype.iff",
                                               @"inc":@"Include",
                                               @"indd":@"Adobe InDesign",
                                               @"iso":@"general.filetype.iso",
                                               @"jar":@"general.filetype.jar",
                                               @"java":@"general.filetype.java",
                                               @"jpeg":@"general.filetype.jpeg",
                                               @"jpg":@"general.filetype.jpeg",
                                               @"js":@"JavaScript",
                                               @"kml":@"Keyhole Markup",
                                               @"log":@"general.filetype.log",
                                               @"m3u":@"general.filetype.m3u",
                                               @"m4a":@"general.filetype.m4a",
                                               @"max":@"general.filetype.max",
                                               @"mdb":@"MS Access",
                                               @"mef":@"general.filetype.rawImage",
                                               @"mid":@"general.filetype.mid",
                                               @"midi":@"general.filetype.mid",
                                               @"mkv":@"general.filetype.mkv",
                                               @"mov":@"general.filetype.mov",
                                               @"mp3":@"general.filetype.mp3",
                                               @"mp4":@"general.filetype.mp4",
                                               @"mpeg":@"general.filetype.mpeg",
                                               @"mpg":@"general.filetype.mpeg",
                                               @"mrw":@"general.filetype.rawImage",
                                               @"msi":@"general.filetype.msi",
                                               @"nb":@"Mathematica",
                                               @"numbers":@"Numbers",
                                               @"nef":@"general.filetype.rawImage",
                                               @"obj":@"Wavefront",
                                               @"ods":@"general.filetype.spreadsheet",
                                               @"odt":@"general.filetype.textDocument",
                                               @"otf":@"general.filetype.otf",
                                               @"ots":@"general.filetype.spreadsheet",
                                               @"orf":@"general.filetype.rawImage",
                                               @"pages":@"general.filetype.pages",
                                               @"pcast":@"general.filetype.podcast",
                                               @"pdb":@"general.filetype.database",
                                               @"pdf":@"general.filetype.pdf",
                                               @"pef":@"general.filetype.rawImage",
                                               @"php":@"general.filetype.php",
                                               @"php3":@"general.filetype.php",
                                               @"php4":@"general.filetype.php",
                                               @"php5":@"general.filetype.php",
                                               @"phtml":@"PHTML Web",
                                               @"pl":@"general.filetype.pl",
                                               @"pls":@"general.filetype.pls",
                                               @"png":@"general.filetype.png",
                                               @"ppj":@"Adobe Premiere",
                                               @"pps":@"MS PowerPoint",
                                               @"ppt":@"MS PowerPoint",
                                               @"pptx":@"MS PowerPoint",
                                               @"prproj":@"Adobe Premiere",
                                               @"ps":@"PostScript",
                                               @"psb":@"Photoshop",
                                               @"psd":@"Photoshop",
                                               @"py":@"general.filetype.py",
                                               @"ra":@"Real Audio",
                                               @"ram":@"Real Audio",
                                               @"rar":@"general.filetype.rar",
                                               @"rm":@"Real Media",
                                               @"rtf":@"general.filetype.rtf",
                                               @"rw2":@"general.filetype.rw2",
                                               @"rwl":@"general.filetype.rawImage",
                                               @"sh":@"general.filetype.sh",
                                               @"shtml":@"general.filetype.shtml",
                                               @"sitx":@"general.filetype.sitx",
                                               @"sql":@"general.filetype.sql",
                                               @"srf":@"general.filetype.srf",
                                               @"srt":@"general.filetype.subtitle",
                                               @"svg":@"general.filetype.vectorImage",
                                               @"svgz":@"general.filetype.vectorImage",
                                               @"swf":@"general.filetype.swf",
                                               @"tar":@"general.filetype.tar",
                                               @"tbz":@"general.filetype.compressed",
                                               @"tga":@"general.filetype.tga",
                                               @"tgz":@"general.filetype.compressed",
                                               @"tif":@"general.filetype.tif",
                                               @"tiff":@"general.filetype.tiff",
                                               @"torrent":@"Torrent",
                                               @"ttf":@"general.filetype.ttf",
                                               @"txt":@"general.filetype.textDocument",
                                               @"vcf":@"vCard",
                                               @"wav":@"general.filetype.wav",
                                               @"webm":@"general.filetype.webm",
                                               @"wma":@"general.filetype.wma",
                                               @"wmv":@"general.filetype.wmv",
                                               @"wpd":@"WordPerfect",
                                               @"wps":@"MS Works",
                                               @"xhtml":@"XHTML Web",
                                               @"xlr":@"MS Works",
                                               @"xls":@"MS Excel",
                                               @"xlsx":@"MS Excel",
                                               @"xlt":@"MS Excel",
                                               @"xltm":@"MS Excel",
                                               @"xml":@"general.filetype.xml",
                                               @"zip":@"general.filetype.zip"};
    
    NSString *fileType = [fileTypesForExtension objectForKey:self.name.pathExtension];
    if (fileType.length == 0) {
        fileType = [NSString stringWithFormat:@"%@ %@", self.name.pathExtension.localizedUppercaseString, NSLocalizedString(@"file", @"Label to desing a file matching").localizedCapitalizedString];
    } else {
        if ([fileType containsString:@"general.filetype"]) {
            NSString *localizedFiletype = NSLocalizedString(fileType, nil);
            if (localizedFiletype) {
                return localizedFiletype;
            }
        }
    }
    
    return fileType;
}

- (BOOL)mnz_isRestorable {
    MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.restoreHandle];
    if (restoreNode && ![[MEGASdkManager sharedMEGASdk] isNodeInRubbish:restoreNode] && [[MEGASdkManager sharedMEGASdk] isNodeInRubbish:self]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)mnz_isInRubbishBin {
    return [[MEGASdkManager sharedMEGASdk] isNodeInRubbish:self];
}

- (BOOL)mnz_isPlayable {
    BOOL supportedShortFormat = NO;
    BOOL supportedVideoCodecId = NO;
    
    // When media information is not available, try to play the node
    if (self.shortFormat == -1 && self.videoCodecId == -1) {
        return YES;
    }
    
    NSArray<NSNumber *> *shortFormats = @[@(1),
                                          @(2),
                                          @(3),
                                          @(4),
                                          @(5),
                                          @(13),
                                          @(27),
                                          @(44),
                                          @(49),
                                          @(50),
                                          @(51),
                                          @(52)];
    
    NSArray<NSNumber *> *videoCodecIds = @[@(15),
                                           @(37),
                                           @(144),
                                           @(215),
                                           @(224),
                                           @(266),
                                           @(346),
                                           @(348),
                                           @(393),
                                           @(405),
                                           @(523),
                                           @(532),
                                           @(551),
                                           @(630),
                                           @(703),
                                           @(740),
                                           @(802),
                                           @(887),
                                           @(957),
                                           @(961),
                                           @(973),
                                           @(1108),
                                           @(1114),
                                           @(1119),
                                           @(1129),
                                           @(1132),
                                           @(1177)];
    
    supportedShortFormat = [shortFormats containsObject:@(self.shortFormat)];
    supportedVideoCodecId = [videoCodecIds containsObject:@(self.videoCodecId)];
    
    return supportedShortFormat || supportedVideoCodecId;
}

- (NSString *)mnz_voiceCachePath {
    
    NSString *nodeFilePath = [Helper pathForNode:self inSharedSandboxCacheDirectory:@"voiceCaches"];
    
    return nodeFilePath;
}

- (NSAttributedString *)mnz_attributedTakenDownNameWithHeight:(CGFloat)height {
    NSAssert(self.isTakenDown, @"Attributed string is only supported for takedown nodes");

    NSMutableAttributedString *nameAttributedString = [NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"%@ ", self.name]].mutableCopy;
    NSString *takedownImageName = @"isTakedown";
    NSAttributedString *takedownImageAttributedString = [NSAttributedString mnz_attributedStringFromImageNamed:takedownImageName fontCapHeight:height];
    [nameAttributedString appendAttributedString:takedownImageAttributedString];
    
    return nameAttributedString;
}

#pragma mark - Shares

- (nonnull NSMutableArray <MEGAShare *> *)outShares {
    NSMutableArray *outSharesForNodeMutableArray = NSMutableArray.new;
    
    MEGAShareList *outSharesForNodeShareList = [MEGASdkManager.sharedMEGASdk outSharesForNode:self];
    NSUInteger outSharesForNodeCount = outSharesForNodeShareList.size.unsignedIntegerValue;
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if (share.user != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    return outSharesForNodeMutableArray;
}

#pragma mark - Versions

- (NSInteger)mnz_numberOfVersions {
    return ([[MEGASdkManager sharedMEGASdk] hasVersionsForNode:self]) ? ([[MEGASdkManager sharedMEGASdk] numberOfVersionsForNode:self]) : 0;
}


- (NSArray<MEGANode *> *)mnz_versions {
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL shouldReturn = YES;
    UIAlertController *renameAlertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if ([renameAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = renameAlertController.actions.lastObject;
        shouldReturn = rightButtonAction.enabled;
    }
    
    return shouldReturn;

}

- (void)renameAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *renameAlertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if ([renameAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = renameAlertController.actions.lastObject;
        BOOL enableRightButton = NO;
        
        NSString *newName = textField.text;
        NSString *nodeNameString = self.name;
        
        if (self.isFile || self.isFolder) {
            BOOL containsInvalidChars = textField.text.mnz_containsInvalidChars;
            if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString] || newName.mnz_isEmpty || containsInvalidChars || (self.isFile && [newName.mnz_fileNameWithoutExtension isEqualToString:@""])) {
                enableRightButton = NO;
                if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString] || newName.mnz_isEmpty) {
                    renameAlertController.title = NSLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder");
                } else if (containsInvalidChars) {
                    renameAlertController.title = NSLocalizedString(@"general.error.charactersNotAllowed", @"Error message shown when trying to rename or create a folder with characters that are not allowed. We need the \ before quotation mark, so it can be shown on code");
                }
            } else {
                enableRightButton = YES;
                renameAlertController.title = NSLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder");
            }
            textField.textColor = containsInvalidChars ? UIColor.mnz_redError : UIColor.mnz_label;
        }
        
        rightButtonAction.enabled = enableRightButton;
    }
}

- (void)mnz_copyToGalleryFromTemporaryPath:(NSString *)path {
    if (self.name.mnz_isVideoPathExtension) {
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        } else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Could not save Item", @"Text shown when an error occurs when trying to save a photo or video to Photos app")];
            MEGALogError(@"The video can be saved to the Camera Roll album");
        }
    }
    
    if (self.name.mnz_isImagePathExtension) {
        NSURL *imageURL = [NSURL fileURLWithPath:path];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *assetCreationRequest = [PHAssetCreationRequest creationRequestForAsset];
            [assetCreationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
            
        } completionHandler:^(BOOL success, NSError * _Nullable nserror) {
            [NSFileManager.defaultManager mnz_removeItemAtPath:path];
            if (nserror) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Could not save Item", @"Text shown when an error occurs when trying to save a photo or video to Photos app")];
                MEGALogError(@"Add asset to camera roll: %@ (Domain: %@ - Code:%td)", nserror.localizedDescription, nserror.domain, nserror.code);
            } else {
                [SVProgressHUD showImage:[UIImage imageNamed:@"saveToPhotos"] status:NSLocalizedString(@"Saved to Photos", @"Text shown when a photo or video is saved to Photos app")];
            }
            [SVProgressHUD dismissWithDelay:1.0];
        }];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Could not save Item", @"Text shown when an error occurs when trying to save a photo or video to Photos app")];
        MEGALogError(@"Save video to Camera roll: %@ (Domain: %@ - Code:%td)", error.localizedDescription, error.domain, error.code);
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"saveToPhotos"] status:NSLocalizedString(@"Saved to Photos", @"Text shown when a photo or video is saved to Photos app")];
        [NSFileManager.defaultManager mnz_removeItemAtPath:videoPath];
    }
    [SVProgressHUD dismissWithDelay:1.0];
}

@end
