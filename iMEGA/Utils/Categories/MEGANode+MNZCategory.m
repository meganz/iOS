#import "MEGANode+MNZCategory.h"

#import <Photos/Photos.h>

#import "SAMKeychain.h"
#import "SVProgressHUD.h"


#import "Helper.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGALinkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSAttributedString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "BrowserViewController.h"
#import "MainTabBarController.h"
#import "MEGANavigationController.h"
#import "MEGAPhotoBrowserViewController.h"
#import "OnboardingViewController.h"
#import "PreviewDocumentViewController.h"
#import "SharedItemsViewController.h"
#import "SendToViewController.h"

@import ChatRepo;
#import "LocalizationHelper.h"
@import MEGAAppPresentation;
@import MEGAAppSDKRepo;

@implementation MEGANode (MNZCategory)

- (void)navigateToParentAndPresent {
    if (!UIApplication.mainTabBarRootViewController) {
        return;
    }
    MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
    
    if ([MEGASdk.shared accessLevelForNode:self] != MEGAShareTypeAccessOwner) { // Node from inshare
        mainTBC.selectedIndex = [TabManager sharedItemsTabIndex];
        SharedItemsViewController *sharedItemsVC = mainTBC.childViewControllers[[TabManager sharedItemsTabIndex]].childViewControllers.firstObject;
        [sharedItemsVC selectSegment:0]; // Incoming
    } else {
        mainTBC.selectedIndex = [TabManager driveTabIndex];
    }
    
    UINavigationController *navigationController = [mainTBC.childViewControllers objectAtIndex:mainTBC.selectedIndex];
    [navigationController popToRootViewControllerAnimated:NO];
    
    NSArray *parentTreeArray = self.mnz_parentTreeArray;
    
    __block MEGANode *backupsRootNode = [BackupRootNodeAccess.shared isTargetNodeFor:self] ? self : nil;
    if (backupsRootNode == nil) {
        [self.mnz_parentTreeArray enumerateObjectsUsingBlock:^(MEGANode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([BackupRootNodeAccess.shared isTargetNodeFor:node]) {
                backupsRootNode = node;
                *stop = YES;
            };
        }];
    }
    
    BOOL isBackupNode = backupsRootNode != nil;
    for (MEGANode *node in parentTreeArray) {
        if (node.handle != backupsRootNode.parentHandle) {
            [self pushCloudDriveForNode:node
                            displayMode:isBackupNode ? DisplayModeBackup : DisplayModeCloudDrive
                   navigationController:navigationController];
        }
    }
    
    switch (self.type) {
        case MEGANodeTypeFolder:
        case MEGANodeTypeRubbish: {
            DisplayMode displayMode;
            if (isBackupNode) {
                displayMode = DisplayModeBackup;
            } else {
                displayMode = self.type == MEGANodeTypeRubbish ? DisplayModeRubbishBin : DisplayModeCloudDrive;
            }
            [self pushCloudDriveForNode:self displayMode:displayMode navigationController:navigationController];
            [UIApplication.mnz_presentingViewController dismissView];
            break;
        }
            
        case MEGANodeTypeFile: {
            if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:self.name]) {
                MEGANode *parentNode = [MEGASdk.shared nodeForHandle:self.parentHandle];
                MEGANodeList *nodeList = [MEGASdk.shared childrenForParent:parentNode];
                NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaNodesMutableArrayFromNodeList];
                
                DisplayMode displayMode;
                if (isBackupNode) {
                    displayMode = DisplayModeBackup;
                } else {
                    displayMode = [MEGASdk.shared accessLevelForNode:self] == MEGAShareTypeAccessOwner ? DisplayModeCloudDrive : DisplayModeSharedItem;
                }
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:MEGASdk.shared displayMode:displayMode isFromSharedItem:NO presentingNode:self];
                
                [navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
            } else {
                [self mnz_openNodeInNavigationController:navigationController folderLink:NO fileLink:nil messageId:nil chatId:nil isFromSharedItem:NO allNodes: nil];
            }
            break;
        }
            
        default:
            [UIApplication.mnz_presentingViewController dismissView];
            break;
    }
}

- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink fileLink:(NSString *)fileLink messageId:(nullable NSNumber * )messageId chatId:(nullable NSNumber *)chatId isFromSharedItem:(BOOL)isFromSharedItem allNodes: (NSArray *_Nullable)allNodes {
    if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:self.name] && MEGAChatSdk.shared.mnz_existsActiveCall) {
        [Helper cannotPlayContentDuringACallAlert];
    } else {
        if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:self.name] && ![FileExtensionGroupOCWrapper verifyIsVideo:self.name] && self.mnz_isPlayable) {
            UIViewController *presenterVC = [navigationController.viewControllers lastObject];
            if ([presenterVC conformsToProtocol:@protocol(AudioPlayerPresenterProtocol)] && [AudioPlayerManager.shared isPlayerDefined] && [AudioPlayerManager.shared isPlayerAlive] && (isFolderLink || (!isFolderLink && fileLink == nil))) {
                [AudioPlayerManager.shared initMiniPlayerWithNode:self fileLink:fileLink filePaths:nil isFolderLink:isFolderLink presenter:presenterVC shouldReloadPlayerInfo:YES shouldResetPlayer:YES isFromSharedItem:isFromSharedItem];
            } else {
                [self initFullScreenPlayerWithNode:self fileLink:fileLink filePaths:nil isFolderLink:isFolderLink presenter:presenterVC messageId:messageId chatId:chatId isFromSharedItem:isFromSharedItem allNodes: allNodes];
            }
        } else {
            UIViewController *viewController = [self mnz_viewControllerForNodeInFolderLink:isFolderLink fileLink:fileLink isFromSharedItem:isFromSharedItem inViewController:navigationController.viewControllers.lastObject];
            if (viewController) {
                [navigationController presentViewController:viewController animated:YES completion:nil];
            }
        }
    }
}

- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink fileLink:(NSString *)fileLink {
    return [self mnz_viewControllerForNodeInFolderLink:isFolderLink fileLink:fileLink isFromSharedItem:NO inViewController:nil];
}

- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink fileLink:(NSString *)fileLink isFromSharedItem:(BOOL)isFromSharedItem inViewController:(UIViewController *)viewController {
    MEGASdk *api = isFolderLink ? MEGASdk.sharedFolderLink : MEGASdk.shared;
    MEGASdk *apiForStreaming;
    if(MEGASdk.shared.isLoggedIn) {
        apiForStreaming = MEGASdk.shared;
    } else {
        apiForStreaming = api;
    }
    
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
        if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:self.name]) {
            NSURL *path = [NSURL fileURLWithPath:previewDocumentPath];
            AVURLAsset *asset = [AVURLAsset assetWithURL:path];
            
            if (asset.playable) {
                return [[AVPlayerManager shared] makePlayerControllerFor:path];
            } else {
                MEGAQLPreviewController *previewController = [[MEGAQLPreviewController alloc] initWithArrayOfFiles:@[previewDocumentPath]];
                previewController.currentPreviewItemIndex = 0;
                return previewController;
            }
        } else if ([viewController conformsToProtocol:@protocol(TextFileEditable)] && [FileExtensionGroupOCWrapper verifyIsEditableText:self.name]) {
            NSStringEncoding encode;
            NSString *textContent = [[NSString alloc] initWithContentsOfFile:previewDocumentPath usedEncoding:&encode error:nil];
            if (textContent != nil) {
                TextFile *textFile = [[TextFile alloc] initWithFileName:self.name content:textContent size: self.size.unsignedIntValue encode:encode];
                return [[TextEditorViewRouter.alloc initWithTextFile:textFile textEditorMode:TextEditorModeView isFromSharedItem:isFromSharedItem node:self presenter:viewController.navigationController] build];
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
        previewController.isFromSharedItem = isFromSharedItem;
        
        return navigationController;
        
    } else if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:self.name] && [apiForStreaming httpServerStart:NO port:4443]) {
        if (self.mnz_isPlayable) {
            return [[AVPlayerManager shared] makePlayerControllerFor:self folderLink:isFolderLink sdk:apiForStreaming];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"fileNotSupported", @"Alert title shown when users try to stream an unsupported audio/video file") message:LocalizedString(@"message_fileNotSupported", @"Alert message shown when users try to stream an unsupported audio/video file") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
            return alertController;
        }
    } else {
        if ([Helper isFreeSpaceEnoughToDownloadNode:self isFolderLink:isFolderLink]) {
            if ([viewController conformsToProtocol:@protocol(TextFileEditable)] && [FileExtensionGroupOCWrapper verifyIsEditableText:self.name]) {
                TextFile *textFile = [[TextFile alloc] initWithFileName:self.name size: self.size.unsignedIntValue];
                return [[TextEditorViewRouter.alloc initWithTextFile:textFile textEditorMode:TextEditorModeLoad isFromSharedItem:isFromSharedItem node:self presenter:viewController.navigationController] build];
            }
            
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"DocumentPreviewer" bundle:nil] instantiateViewControllerWithIdentifier:@"previewDocumentNavigationID"];
            PreviewDocumentViewController *previewController = navigationController.viewControllers.firstObject;
            navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
            previewController.node = isFolderLink ? [api authorizeNode:self] : self;
            previewController.api = api;
            previewController.isLink = isFolderLink;
            previewController.fileLink = fileLink;
            previewController.isFromSharedItem = isFromSharedItem;
            
            return navigationController;
        }
        
        // Mike: This log is specificially intended for tracking non-fatal event with domain "nz.mega.megaphotobrowserviewcontroller"
        NSDictionary *logInfo = @{@"Node Handle": self.base64Handle ? self.base64Handle : @"nil",
                                  @"Node Name": self.name ? self.name : @"nil",
                                  @"Node Size": self.size ? self.size : @"nil",
                                  @"isFolderLink": [NSNumber numberWithBool:isFolderLink],
                                  @"fileLink": fileLink ? fileLink : @"nil"};
        [CrashlyticsLogger logWithCategory:LogCategoryGeneral
                                       msg:[NSString stringWithFormat: @"Could not get viewController, debug info: %@", logInfo]
                                      file:@(__FILENAME__)
                                  function:@(__FUNCTION__)];
        return nil;
    }
}

#pragma mark - Actions

- (void)mnz_editTextFileInViewController:(UIViewController *)viewController {
    MEGANavigationController *nav = (MEGANavigationController *)[self mnz_viewControllerForNodeInFolderLink:NO fileLink:nil isFromSharedItem:NO inViewController:viewController];
    
    if (nav == nil) {
        return;
    }
    
    if (nav.viewControllers.lastObject.class == TextEditorViewController.class) {
        TextEditorViewController *tevc = nav.viewControllers.lastObject;
        [tevc editAfterOpen];
    } else {
        PreviewDocumentViewController *pdvc = nav.viewControllers.lastObject;
        pdvc.showUnknownEncodeHud = YES;
    }
    [viewController.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)mnz_labelActionSheetInViewController:(UIViewController *)viewController {
    UIImageView *checkmarkImageView = [UIImageView.alloc initWithImage:[UIImage megaImageWithNamed:@"turquoise_checkmark"]];
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Red", @"A user can mark a folder or file with its own colour, in this case “Red”.") detail:nil accessoryView:(self.label == MEGANodeLabelRed ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Red"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelRed) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelRed];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Orange", @"A user can mark a folder or file with its own colour, in this case “Orange”.") detail:nil accessoryView:(self.label == MEGANodeLabelOrange ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Orange"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelOrange) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelOrange];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Yellow", @"A user can mark a folder or file with its own colour, in this case “Yellow”.") detail:nil accessoryView:(self.label == MEGANodeLabelYellow ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Yellow"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelYellow) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelYellow];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Green", @"A user can mark a folder or file with its own colour, in this case “Green”.") detail:nil accessoryView:(self.label == MEGANodeLabelGreen ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Green"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelGreen) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelGreen];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Blue", @"A user can mark a folder or file with its own colour, in this case “Blue”.") detail:nil accessoryView:(self.label == MEGANodeLabelBlue ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Blue"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelBlue) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelBlue];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Purple", @"A user can mark a folder or file with its own colour, in this case “Purple”.") detail:nil accessoryView:(self.label == MEGANodeLabelPurple ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Purple"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelPurple) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelPurple];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Grey", @"A user can mark a folder or file with its own colour, in this case “Grey”.") detail:nil accessoryView:(self.label == MEGANodeLabelGrey ? checkmarkImageView : nil) image:[UIImage megaImageWithNamed:@"Grey"] style:UIAlertActionStyleDefault actionHandler:^{
        if (self.label != MEGANodeLabelGrey) [MEGASdk.shared setNodeLabel:self label:MEGANodeLabelGrey];
    }]];
    
    if (self.label != MEGANodeLabelUnknown) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"Remove Label", @"Option shown on the action sheet where you can choose or change the color label of a file or folder. The 'Remove Label' only appears if you have previously selected a label") detail:nil image:[UIImage megaImageWithNamed:@"delete"] style:UIAlertActionStyleDestructive actionHandler:^{
            [MEGASdk.shared resetNodeLabel:self];
        }]];
    }
    
    ActionSheetViewController *labelsActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:viewController.navigationItem.rightBarButtonItems.firstObject];
    [viewController presentViewController:labelsActionSheet animated:YES completion:nil];
}

- (void)mnz_renameNodeInViewController:(UIViewController *)viewController {
    [self mnz_renameNodeInViewController:viewController completion:nil];
}

- (void)mnz_renameNodeInViewController:(UIViewController *)viewController completion:(void(^)(MEGARequest *request))completion {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *renameAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") message:LocalizedString(@"renameNodeMessage", @"Hint text to suggest that the user have to write the new name for the file or folder") preferredStyle:UIAlertControllerStyleAlert];
        
        [renameAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = self.name;
            textField.text = self.name;
            textField.returnKeyType = UIReturnKeyDone;
            textField.delegate = self;
            [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [renameAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *renameAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                NSString *alertViewTextFieldText = renameAlertController.textFields.firstObject.text;
                MEGANode *parentNode = [MEGASdk.shared nodeForHandle:self.parentHandle];
                
                MEGANodeType nodeType = MEGANodeTypeFile;
                if (self.isFolder) {
                    nodeType = MEGANodeTypeFolder;
                }
                
                MEGANode *existingChildNode = [MEGASdk.shared childNodeForParent:parentNode name:alertViewTextFieldText type:nodeType];
                
                if (existingChildNode) {
                    NSString *duplicateErrorMessage = LocalizedString(@"There is already a file with the same name", @"A tooltip message which shows when a file name is duplicated during renaming.");
                    if (self.isFolder) {
                        duplicateErrorMessage = LocalizedString(@"There is already a folder with the same name", @"A tooltip message which is shown when a folder name is duplicated during renaming or creation.");
                    }
                    [SVProgressHUD showErrorWithStatus:duplicateErrorMessage];
                } else if (![alertViewTextFieldText.pathExtension isEqualToString:self.name.pathExtension]) {
                    [self showRenameNodeConfirmationAlertFrom:viewController completion:^{
                        [self mnz_renameNode:alertViewTextFieldText.mnz_removeWhitespacesAndNewlinesFromBothEnds completion:completion];
                    }];
                } else {
                    [self mnz_renameNode:alertViewTextFieldText.mnz_removeWhitespacesAndNewlinesFromBothEnds completion:completion];
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
        [MEGASdk.shared moveNode:self newParent:MEGASdk.shared.rubbishNode delegate:moveRequestDelegate];
    }
}

- (void)mnz_removeInViewController:(UIViewController *)viewController completion:(void (^)(BOOL shouldRemove))actionCompletion {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = LocalizedString(@"general.menuAction.deletePermanently", @"Title for the action that allows to remove a file or folder");
        NSString *alertMessage = [self alertMessageForRemoved:self.type];
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];

        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (actionCompletion) {
                actionCompletion(NO);
            }
        }]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
                [MEGASdk.shared removeNode:self delegate:removeRequestDelegate];
                
                if (actionCompletion) {
                    actionCompletion(YES);
                }
            }
        }]];
        
        [viewController presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)mnz_leaveSharingInViewController:(UIViewController *)viewController completion:(void (^ _Nullable)(BOOL))completion {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *alertTitle = LocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
        NSString *alertMessage = LocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
        
        UIAlertController *moveRemoveLeaveAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (completion) {
                completion(NO);
            }
        }]];
        
        [moveRemoveLeaveAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                void (^comp)(void) = ^{
                    [viewController dismissViewControllerAnimated:YES completion:nil];
                    if (completion) {
                        completion(YES);
                    }
                };
                MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:2 files:(self.isFile ? 1 : 0) folders:(self.isFolder ? 1 : 0) completion:comp];
                [MEGASdk.shared removeNode:self delegate:removeRequestDelegate];
            }
        }]];
        
        [viewController presentViewController:moveRemoveLeaveAlertController animated:YES completion:nil];
    }
}

- (void)mnz_removeSharingWithCompletion:(void (^ _Nullable)(BOOL))completion {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
        
        MEGAShareList *outSharesForNodeShareList = [MEGASdk.shared outSharesForNode:self];
        NSInteger outSharesForNodeCount = outSharesForNodeShareList.size;
        for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
            MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
            if (share.user != nil) {
                [outSharesForNodeMutableArray addObject:share];
            }
        }
        NSString *alertMessage = outSharesForNodeMutableArray.count == 1 ? LocalizedString(@"removeOneShareOneContactMessage", @"") : [NSString stringWithFormat:LocalizedString(@"removeOneShareMultipleContactsMessage", @""), outSharesForNodeMutableArray.count];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"removeSharing", @"") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (completion) {
                completion(NO);
            }
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:outSharesForNodeMutableArray.count completion:nil];
            for (MEGAShare *share in outSharesForNodeMutableArray) {
                [MEGASdk.shared shareNode:self withEmail:share.user level:MEGAShareTypeAccessUnknown delegate:shareRequestDelegate];
            }
            if (completion) {
                completion(YES);
            }
        }]];
        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)mnz_restore {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANode *restoreNode = [MEGASdk.shared nodeForHandle:self.restoreHandle];
        if (restoreNode == nil || [MEGASdk.shared isNodeInRubbish:restoreNode] ) {
            restoreNode = MEGASdk.shared.rootNode;
        }
        [[NameCollisionRouterOCWrapper.alloc init] moveNodes:@[self] to:restoreNode presenter:UIApplication.mnz_presentingViewController];
    }
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
            
            OnboardingViewController *onboardingVC = [OnboardingViewController instantiateOnboardingWithType:OnboardingTypeDefault];
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
        
        parentNode = [MEGASdk.shared parentNodeForNode:parentNode];
    }
    
    return parentNode;
}

- (NSMutableArray *)mnz_parentTreeArray {
    NSMutableArray *parentTreeArray = [[NSMutableArray alloc] init];
    
    if ([MEGASdk.shared accessLevelForNode:self] == MEGAShareTypeAccessOwner) {
        uint64_t rootHandle;
        if ([[MEGASdk.shared nodePathForNode:self] hasPrefix:@"//bin"]) {
            rootHandle = [MEGASdk.shared rubbishNode].parentHandle;
        } else {
            rootHandle = [MEGASdk.shared rootNode].handle;
        }
        
        uint64_t tempHandle = self.parentHandle;
        while (tempHandle != rootHandle) {
            MEGANode *tempNode = [MEGASdk.shared nodeForHandle:tempHandle];
            if (tempNode) {
                [parentTreeArray insertObject:tempNode atIndex:0];
                tempHandle = tempNode.parentHandle;
            } else {
                break;
            }
        }
    } else {
        MEGANode *tempNode = [MEGASdk.shared nodeForHandle:self.parentHandle];
        while (tempNode != nil) {
            [parentTreeArray insertObject:tempNode atIndex:0];
            tempNode = [MEGASdk.shared nodeForHandle:tempNode.parentHandle];
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
                                               @"avif":@"general.filetype.avif",
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
                                               @"jxl":@"general.filetype.jxl",
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
                                               @"org":@"general.filetype.textDocument",
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
        fileType = [NSString stringWithFormat:@"%@ %@", self.name.pathExtension, LocalizedString(@"chat.match.file", @"Label to desing a file matching")];
    } else {
        if ([fileType containsString:@"general.filetype"]) {
            NSString *localizedFiletype = LocalizedString(fileType, @"");
            if (localizedFiletype) {
                return localizedFiletype;
            }
        }
    }
    
    return fileType;
}

- (BOOL)mnz_isInRubbishBin {
    return [MEGASdk.shared isNodeInRubbish:self];
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

- (BOOL)mnz_isPlaying {
    return self.mnz_isPlayable && [AudioPlayerManager.shared isPlayerAlive] && [AudioPlayerManager.shared isPlayingNode:self];
}

- (NSString *)mnz_voiceCachePath {
    
    NSString *nodeFilePath = [Helper pathForNode:self inSharedSandboxCacheDirectory:@"voiceCaches"];
    
    return nodeFilePath;
}

#pragma mark - Shares

- (nonnull NSMutableArray <MEGAShare *> *)outShares {
    NSMutableArray *outSharesForNodeMutableArray = NSMutableArray.new;
    
    MEGAShareList *outSharesForNodeShareList = [MEGASdk.shared outSharesForNode:self];
    NSInteger outSharesForNodeCount = outSharesForNodeShareList.size;
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
    return ([MEGASdk.shared hasVersionsForNode:self]) ? ([MEGASdk.shared numberOfVersionsForNode:self]) : 0;
}


- (NSArray<MEGANode *> *)mnz_versions {
    return [[MEGASdk.shared versionsForNode:self] mnz_nodesArrayFromNodeList];
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

@end
