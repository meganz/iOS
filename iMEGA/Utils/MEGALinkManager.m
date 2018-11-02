
#import "MEGALinkManager.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"

#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "BrowserViewController.h"
#import "CloudDriveViewController.h"
#import "ConfirmAccountViewController.h"
#import "ContactRequestsViewController.h"
#import "CustomModalAlertViewController.h"
#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "MasterKeyViewController.h"
#import "MEGAContactLinkQueryRequestDelegate.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGAGenericRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPasswordLinkRequestDelegate.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGAQuerySignupLinkRequestDelegate.h"
#import "MEGAQueryRecoveryLinkRequestDelegate.h"
#import "MEGASdkManager.h"
#import "SharedItemsViewController.h"
#import "UnavailableLinkView.h"

static NSURL *linkURL;
static NSURL *linkEncryptedURL;
static URLType urlType;

static NSString *emailOfNewSignUpLink;

static NSMutableArray *nodesFromLinkMutableArray;
static LinkOption linkOption;

static NSString *nodeToPresentBase64Handle;

@implementation MEGALinkManager

#pragma mark - Utils to manage MEGA links

+ (NSURL *)linkURL {
    return linkURL;
}

+ (void)setLinkURL:(NSURL *)link {
    linkURL = link;
}

+ (NSURL *)linkEncryptedURL {
    return linkEncryptedURL;
}

+ (void)setLinkEncryptedURL:(NSURL *)linkEncrypted {
    linkEncryptedURL = linkEncrypted;
}

+ (URLType)urlType {
    return urlType;
}

+ (void)setUrlType:(URLType)type {
    urlType = type;
}

+ (void)resetLinkAndURLType {
    [MEGALinkManager setLinkURL:nil];
    [MEGALinkManager setUrlType:URLTypeDefault];
}

+ (NSString *)emailOfNewSignUpLink {
    return emailOfNewSignUpLink;
}

+ (void)setEmailOfNewSignUpLink:(NSString *)email {
    emailOfNewSignUpLink = email;
}

#pragma mark - Utils to manage links when you are not logged

+ (NSMutableArray *)nodesFromLinkMutableArray {
    if (nodesFromLinkMutableArray == nil) {
        nodesFromLinkMutableArray = [[NSMutableArray alloc] init];
    }
    
    return nodesFromLinkMutableArray;
}

+ (LinkOption)selectedOption {
    return linkOption;
}

+ (void)setSelectedOption:(LinkOption)selectedOption {
    linkOption = selectedOption;
}

+ (void)resetUtilsForLinksWithoutSession {
    [[MEGALinkManager nodesFromLinkMutableArray] removeAllObjects];
    
    [MEGALinkManager setSelectedOption:LinkOptionDefault];
}

+ (void)processSelectedOptionOnLink {
    if ([MEGALinkManager selectedOption] == LinkOptionDefault) {
        return;
    }
    
    switch ([MEGALinkManager selectedOption]) {
        case LinkOptionImportNode: {
            MEGANode *node = [[MEGALinkManager nodesFromLinkMutableArray] firstObject];
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
            
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            browserVC.selectedNodesArray = [NSArray arrayWithObject:node];
            [browserVC setBrowserAction:BrowserActionImport];
            break;
        }
            
        case LinkOptionDownloadNode: {
            MEGANode *node = [[MEGALinkManager nodesFromLinkMutableArray] firstObject];
            if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                return;
            }
            
            MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController;
            [mainTBC showOffline];
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
            [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:NO shouldOverwrite:NO];
            break;
        }
            
        case LinkOptionImportFolderOrNodes: {
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
            browserVC.selectedNodesArray = [NSArray arrayWithArray:[MEGALinkManager nodesFromLinkMutableArray]];
            
            [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
            break;
        }
            
        case LinkOptionDownloadFolderOrNodes: {
            for (MEGANode *node in [MEGALinkManager nodesFromLinkMutableArray]) {
                if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                    return;
                }
            }
            
            MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController;
            [mainTBC showOffline];
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
            for (MEGANode *node in [MEGALinkManager nodesFromLinkMutableArray]) {
                [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:YES shouldOverwrite:NO];
            }
            break;
        }
            
        default:
            break;
    }
    
    [MEGALinkManager resetUtilsForLinksWithoutSession];
}

#pragma mark - Spotlight

+ (NSString *)nodeToPresentBase64Handle {
    return nodeToPresentBase64Handle;
}

+ (void)setNodeToPresentBase64Handle:(NSString *)base64Handle {
    nodeToPresentBase64Handle = base64Handle;
}

+ (void)presentNode {
    uint64_t handle = [MEGASdk handleForBase64Handle:nodeToPresentBase64Handle];
    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:handle];
    if (node) {
        MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController;
        
        UINavigationController *navigationController;
        if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) { // node from inshare
            mainTBC.selectedIndex = SHARES;
            SharedItemsViewController *sharedItemsVC = mainTBC.childViewControllers[SHARES].childViewControllers[0];
            [sharedItemsVC selectSegment:0]; // Incoming
        } else {
            mainTBC.selectedIndex = CLOUD;
        }
        navigationController = [mainTBC.childViewControllers objectAtIndex:mainTBC.selectedIndex];
        
        [MEGALinkManager presentNode:node inNavigationController:navigationController];
    } else {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            UIAlertController *theContentIsNotAvailableAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"theContentIsNotAvailableForThisAccount", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [theContentIsNotAvailableAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            [theContentIsNotAvailableAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSError *error;
                NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] error:&error];
                if (error) {
                    MEGALogError(@"Contents of directory at path failed with error: %@", error);
                }
                
                BOOL isInboxDirectory = NO;
                for (NSString *directoryElement in directoryContent) {
                    if ([directoryElement isEqualToString:@"Inbox"]) {
                        NSString *inboxPath = [[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"];
                        [[NSFileManager defaultManager] fileExistsAtPath:inboxPath isDirectory:&isInboxDirectory];
                        break;
                    }
                }
                
                if (directoryContent.count > 0) {
                    if (directoryContent.count == 1 && isInboxDirectory) {
                        [[MEGASdkManager sharedMEGASdk] logout];
                        return;
                    }
                    
                    UIAlertController *warningAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"warning", nil) message:AMLocalizedString(@"allFilesSavedForOfflineWillBeDeletedFromYourDevice", @"Alert message shown when the user perform logout and has files in the Offline directory") preferredStyle:UIAlertControllerStyleAlert];
                    [warningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
                    [warningAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [[MEGASdkManager sharedMEGASdk] logout];
                    }]];
                    
                    [UIApplication.mnz_visibleViewController presentViewController:warningAlertController animated:YES completion:nil];
                } else {
                    [[MEGASdkManager sharedMEGASdk] logout];
                }
            }]];
            
            [UIApplication.mnz_visibleViewController presentViewController:theContentIsNotAvailableAlertController animated:YES completion:nil];
        }
    }
    
    nodeToPresentBase64Handle = nil;
}

+ (void)presentNode:(MEGANode *)node inNavigationController:(UINavigationController *)navigationController {
    [navigationController popToRootViewControllerAnimated:NO];
    
    NSArray *parentTreeArray = node.mnz_parentTreeArray;
    for (MEGANode *node in parentTreeArray) {
        CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        cloudDriveVC.parentNode = node;
        [navigationController pushViewController:cloudDriveVC animated:NO];
    }
    
    switch (node.type) {
        case MEGANodeTypeFolder:
        case MEGANodeTypeRubbish: {
            CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = node;
            [navigationController pushViewController:cloudDriveVC animated:NO];
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.parentHandle];
                MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:parentNode];
                NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaNodesMutableArrayFromNodeList];
                
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeCloudDrive presentingNode:node preferredIndex:0];
                
                [navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
            } else {
                [node mnz_openNodeInNavigationController:navigationController folderLink:NO];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Manage MEGA links

+ (void)processLinkURL:(NSURL *)url {
    if (!url) {
        return;
    }
    
    [MEGALinkManager setUrlType:url.mnz_type];
    switch ([MEGALinkManager urlType]) {
        case URLTypeDefault:
            [Helper presentSafariViewControllerWithURL:[MEGALinkManager linkURL]];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeOpenInLink:
            [MEGALinkManager openIn];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeFileLink:
            [MEGALinkManager showFileLinkView];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeFolderLink:
            [MEGALinkManager showFolderLinkView];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeEncryptedLink:
            [MEGALinkManager setLinkEncryptedURL:MEGALinkManager.linkURL];
            [MEGALinkManager showEncryptedLinkAlert:url.mnz_MEGAURL];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeConfirmationLink:
        case URLTypeNewSignUpLink: {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"alreadyLoggedInAlertTitle", @"Warning title shown when you try to confirm an account but you are logged in with another one") message:AMLocalizedString(@"alreadyLoggedInAlertMessage", @"Warning message shown when you try to confirm an account but you are logged in with another one") preferredStyle:UIAlertControllerStyleAlert];
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [MEGALinkManager resetLinkAndURLType];
                }]];
                
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    MEGAGenericRequestDelegate *logoutRequestDelegate = [[MEGAGenericRequestDelegate alloc] initWithRequestCompletion:^(MEGARequest *request) {
                        MEGAQuerySignupLinkRequestDelegate *querySignupLinkRequestDelegate = [[MEGAQuerySignupLinkRequestDelegate alloc] initWithCompletion:nil urlType:[MEGALinkManager urlType]];
                        [[MEGASdkManager sharedMEGASdk] querySignupLink:url.mnz_MEGAURL delegate:querySignupLinkRequestDelegate];
                    } errorCompletion:nil];
                    [[MEGASdkManager sharedMEGASdk] logoutWithDelegate:logoutRequestDelegate];
                }]];
                
                [UIApplication.mnz_visibleViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
            } else {
                MEGAQuerySignupLinkRequestDelegate *querySignupLinkRequestDelegate = [[MEGAQuerySignupLinkRequestDelegate alloc] initWithCompletion:nil urlType:[MEGALinkManager urlType]];
                [[MEGASdkManager sharedMEGASdk] querySignupLink:url.mnz_MEGAURL delegate:querySignupLinkRequestDelegate];
            }
            break;
        }
            
        case URLTypeBackupLink:
            [MEGALinkManager showBackupLinkView];
            break;
            
        case URLTypeIncomingPendingContactsLink:
            [MEGALinkManager showContactRequestsView];
            break;
            
        case URLTypeChangeEmailLink: {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                MEGAQueryRecoveryLinkRequestDelegate *queryRecoveryLinkRequestDelegate = [[MEGAQueryRecoveryLinkRequestDelegate alloc] initWithRequestCompletion:nil urlType:URLTypeChangeEmailLink];
                [[MEGASdkManager sharedMEGASdk] queryChangeEmailLink:url.mnz_MEGAURL delegate:queryRecoveryLinkRequestDelegate];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"needToBeLoggedInToCompleteYourEmailChange", @"Error message when a user attempts to change their email without an active login session.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
            }
            break;
        }
            
        case URLTypeCancelAccountLink: {
            if ([Helper hasSession_alertIfNot]) {
                MEGAQueryRecoveryLinkRequestDelegate *queryRecoveryLinkRequestDelegate = [[MEGAQueryRecoveryLinkRequestDelegate alloc] initWithRequestCompletion:nil urlType:URLTypeCancelAccountLink];
                [[MEGASdkManager sharedMEGASdk] queryCancelLink:url.mnz_MEGAURL delegate:queryRecoveryLinkRequestDelegate];
            }
            break;
        }
            
        case URLTypeRecoverLink: {
            MEGAQueryRecoveryLinkRequestDelegate *queryRecoveryLinkRequestDelegate = [[MEGAQueryRecoveryLinkRequestDelegate alloc] initWithRequestCompletion:nil urlType:URLTypeRecoverLink];
            [[MEGASdkManager sharedMEGASdk] queryResetPasswordLink:url.mnz_MEGAURL delegate:queryRecoveryLinkRequestDelegate];
            break;
        }
            
        case URLTypeContactLink:
            if ([Helper hasSession_alertIfNot]) {
                [MEGALinkManager handleContactLink];
            }
            break;
            
        case URLTypeChatLink: {
            MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController;
            mainTBC.selectedIndex = CHAT;
            break;
        }
            
        case URLTypeLoginRequiredLink: {
            NSString *session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
            if (session) {
                [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionV3"];
                [SAMKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
            }
            break;
        }
            
        case URLTypeHandleLink:
            [MEGALinkManager setNodeToPresentBase64Handle:[url.mnz_afterSlashesString substringFromIndex:1]];
            [MEGALinkManager presentNode];
            
            break;
            
        case URLTypeAchievementsLink: {
            MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.sharedApplication.keyWindow.rootViewController;
            [mainTBC showAchievements];
            break;
        }
            
        default:
            break;
    }
}

+ (void)showLinkNotValid {
    [MEGALinkManager showEmptyStateViewWithImageNamed:@"invalidFileLink" title:AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid") text:@""];
    
    [MEGALinkManager resetLinkAndURLType];
}

+ (void)showEmptyStateViewWithImageNamed:(NSString *)imageName title:(NSString *)title text:(NSString *)text {
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options:nil] firstObject];
    unavailableLinkView.imageView.image = [UIImage imageNamed:imageName];
    unavailableLinkView.imageView.contentMode = UIViewContentModeScaleAspectFit;
    unavailableLinkView.titleLabel.text = title;
    unavailableLinkView.textLabel.text = text;
    unavailableLinkView.frame = [[UIScreen mainScreen] bounds];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    [viewController.view addSubview:unavailableLinkView];
    viewController.navigationItem.title = title;
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:viewController];
    [navigationController addCancelButton];
    [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
}

+ (void)presentConfirmViewWithURLType:(URLType)urlType link:(NSString *)link email:(NSString *)email {
    MEGANavigationController *confirmAccountNavigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ConfirmAccountNavigationControllerID"];
    
    ConfirmAccountViewController *confirmAccountVC = confirmAccountNavigationController.viewControllers.firstObject;
    confirmAccountVC.urlType = urlType;
    confirmAccountVC.confirmationLinkString = link;
    confirmAccountVC.emailString = email;
    
    [UIApplication.mnz_visibleViewController presentViewController:confirmAccountNavigationController animated:YES completion:nil];
}

+ (void)openIn {
    if ([Helper hasSession_alertIfNot]) {
        MEGANavigationController *browserNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = browserNavigationController.viewControllers.firstObject;
        browserVC.localpath = linkURL.path; // "file://" = 7 characters
        browserVC.browserAction = BrowserActionOpenIn;
        
        [UIApplication.mnz_visibleViewController presentViewController:browserNavigationController animated:YES completion:nil];
    }
}

+ (void)showEncryptedLinkAlert:(NSString *)encryptedLinkURLString {
    MEGAPasswordLinkRequestDelegate *delegate = [[MEGAPasswordLinkRequestDelegate alloc] initForDecryptionWithCompletion:^(MEGARequest *request) {
        NSString *url = [NSString stringWithFormat:@"mega://%@", [[request.text componentsSeparatedByString:@"/"] lastObject]];
        [MEGALinkManager setLinkURL:[NSURL URLWithString:url]];
        [MEGALinkManager processLinkURL:[NSURL URLWithString:url]];
    } onError:^(MEGARequest *request) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyNotValid", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [MEGALinkManager showEncryptedLinkAlert:request.link];
        }]];
        
        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"decryptionKeyAlertTitle", nil) message:AMLocalizedString(@"decryptionKeyAlertMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = AMLocalizedString(@"decryptionKey", nil);
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[MEGASdkManager sharedMEGASdk] decryptPasswordProtectedLink:encryptedLinkURLString password:alertController.textFields.firstObject.text delegate:delegate];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [MEGALinkManager resetLinkAndURLType];
        [MEGALinkManager setLinkEncryptedURL:nil];
    }]];
    
    [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)showFileLinkView {
    NSString *fileLinkURLString = [MEGALinkManager linkURL].mnz_MEGAURL;
    MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (error.type) {
            [MEGALinkManager presentFileLinkViewForLink:fileLinkURLString request:request error:error];
        } else {
            MEGANode *node = request.publicNode;
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
                if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
                    NSError *nserror;
                    if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&nserror]) {
                        MEGALogError(@"Create directory at path failed with error: %@", nserror);
                    }
                }
                
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[node].mutableCopy api:[MEGASdkManager sharedMEGASdkFolder] displayMode:DisplayModeFileLink presentingNode:node preferredIndex:0];
                photoBrowserVC.publicLink = fileLinkURLString;
                photoBrowserVC.encryptedLink = MEGALinkManager.linkEncryptedURL.absoluteString;
                
                [UIApplication.mnz_visibleViewController presentViewController:photoBrowserVC animated:YES completion:nil];
            } else {
                [MEGALinkManager presentFileLinkViewForLink:fileLinkURLString request:request error:error];
            }
        }
        
        [SVProgressHUD dismiss];
    }];
    delegate.savePublicHandle = YES;
    
    [SVProgressHUD show];
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:fileLinkURLString delegate:delegate];
}


+ (void)presentFileLinkViewForLink:(NSString *)link request:(MEGARequest *)request error:(MEGAError *)error {
    MEGANavigationController *fileLinkNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkNavigationControllerID"];
    FileLinkViewController *fileLinkVC = fileLinkNavigationController.viewControllers.firstObject;
    fileLinkVC.publicLinkString = link;
    fileLinkVC.linkEncryptedString = MEGALinkManager.linkEncryptedURL.absoluteString;
    fileLinkVC.request = request;
    fileLinkVC.error = error;
    
    [UIApplication.mnz_visibleViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
}

+ (void)showFolderLinkView {
    MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
    
    FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
    
    folderlinkVC.isFolderRootNode = YES;
    folderlinkVC.publicLinkString = MEGALinkManager.linkURL.mnz_MEGAURL;
    folderlinkVC.linkEncryptedString = MEGALinkManager.linkEncryptedURL.absoluteString;
    
    [UIApplication.mnz_visibleViewController presentViewController:folderNavigationController animated:YES completion:nil];
}

+ (void)showBackupLinkView {
    if ([Helper hasSession_alertIfNot]) {
        MasterKeyViewController *masterKeyVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"MasterKeyViewControllerID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:masterKeyVC];
        [navigationController addCancelButton];
        
        [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

+ (void)showContactRequestsView {
    if ([Helper hasSession_alertIfNot]) {
        ContactRequestsViewController *contactsRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:contactsRequestsVC];
        [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

+ (void)handleContactLink {
    NSString *afterSlashesString = [[MEGALinkManager linkURL] mnz_afterSlashesString];
    NSRange rangeOfPrefix = [afterSlashesString rangeOfString:@"C!"];
    NSString *contactLinkHandle = [afterSlashesString substringFromIndex:(rangeOfPrefix.location + rangeOfPrefix.length)];
    uint64_t handle = [MEGASdk handleForBase64Handle:contactLinkHandle];

    MEGAContactLinkQueryRequestDelegate *delegate = [[MEGAContactLinkQueryRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", request.name, request.text];
        [MEGALinkManager presentInviteModalForEmail:request.email fullName:fullName contactLinkHandle:request.nodeHandle image:request.file];
    } onError:^(MEGAError *error) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid")];
    }];

    [[MEGASdkManager sharedMEGASdk] contactLinkQueryWithHandle:handle delegate:delegate];
}

+ (void)presentInviteModalForEmail:(NSString *)email fullName:(NSString *)fullName contactLinkHandle:(uint64_t)contactLinkHandle image:(NSString *)imageOnBase64URLEncoding {
    CustomModalAlertViewController *inviteOrDismissModal = [[CustomModalAlertViewController alloc] init];
    inviteOrDismissModal.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    if (imageOnBase64URLEncoding.mnz_isEmpty) {
        inviteOrDismissModal.image = [UIImage imageForName:fullName.uppercaseString size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor colorFromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:64.0f]];
    } else {
        inviteOrDismissModal.roundImage = YES;
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:[NSString mnz_base64FromBase64URLEncoding:imageOnBase64URLEncoding] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        inviteOrDismissModal.image = [UIImage imageWithData:imageData];
    }
    
    inviteOrDismissModal.viewTitle = fullName;
    
    __weak UIViewController *weakVisibleVC = [UIApplication mnz_visibleViewController];
    __weak CustomModalAlertViewController *weakInviteOrDismissModal = inviteOrDismissModal;
    void (^completion)(void) = ^{
        MEGAInviteContactRequestDelegate *delegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1 presentSuccessOver:weakVisibleVC completion:nil];
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd handle:contactLinkHandle delegate:delegate];
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    void (^onDismiss)(void) = ^{
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:email];
    if (user && user.visibility == MEGAUserVisibilityVisible) {
        inviteOrDismissModal.detail = [AMLocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.") stringByReplacingOccurrencesOfString:@"%s" withString:email];
        inviteOrDismissModal.action = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        inviteOrDismissModal.completion = onDismiss;
    } else {
        BOOL isInOutgoingContactRequest = NO;
        MEGAContactRequestList *outgoingContactRequestList = [[MEGASdkManager sharedMEGASdk] outgoingContactRequests];
        for (NSInteger i = 0; i < outgoingContactRequestList.size.integerValue; i++) {
            MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
            if ([email isEqualToString:contactRequest.targetEmail]) {
                isInOutgoingContactRequest = YES;
                break;
            }
        }
        if (isInOutgoingContactRequest) {
            inviteOrDismissModal.image = [UIImage imageNamed:@"inviteSent"];
            inviteOrDismissModal.viewTitle = AMLocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
            NSString *detailText = AMLocalizedString(@"theUserHasBeenInvited", @"Success message shown when a contact has been invited");
            detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:email];
            inviteOrDismissModal.detail = detailText;
            inviteOrDismissModal.boldInDetail = email;
            inviteOrDismissModal.action = AMLocalizedString(@"close", nil);
            inviteOrDismissModal.completion = onDismiss;
        } else {
            inviteOrDismissModal.detail = email;
            inviteOrDismissModal.action = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
            inviteOrDismissModal.dismiss = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
            inviteOrDismissModal.completion = completion;
            inviteOrDismissModal.onDismiss = onDismiss;
        }
    }
    
    [[UIApplication mnz_visibleViewController] presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

@end
