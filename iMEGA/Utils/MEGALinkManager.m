
#import "MEGALinkManager.h"

#import <UserNotifications/UserNotifications.h>

#import "SAMKeychain.h"
#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"

#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
#import "ConfirmAccountViewController.h"
#import "ContactRequestsViewController.h"
#import "CustomModalAlertViewController.h"
#import "DevicePermissionsHelper.h"
#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "MasterKeyViewController.h"
#import "MEGAChatGenericRequestDelegate.h"
#import "MEGAContactLinkQueryRequestDelegate.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPasswordLinkRequestDelegate.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGAQuerySignupLinkRequestDelegate.h"
#import "MEGAQueryRecoveryLinkRequestDelegate.h"
#import "MEGASdkManager.h"
#import "UnavailableLinkView.h"
#import "MEGA-Swift.h"

static NSURL *linkURL;
static NSURL *secondaryLinkURL;
static URLType urlType;

static NSString *emailOfNewSignUpLink;

static NSMutableArray *nodesFromLinkMutableArray;
static LinkOption selectedOption;

static NSString *nodeToPresentBase64Handle;

static NSMutableSet<NSString *> *joiningOrLeavingChatBase64Handles;

@implementation MEGALinkManager

#pragma mark - Utils to manage MEGA links

+ (NSURL *)linkURL {
    return linkURL;
}

+ (void)setLinkURL:(NSURL *)link {
    linkURL = link;
}

+ (NSURL *)secondaryLinkURL {
    return secondaryLinkURL;
}

+ (void)setSecondaryLinkURL:(NSURL *)secondaryLink {
    secondaryLinkURL = secondaryLink;
}

+ (URLType)urlType {
    return urlType;
}

+ (void)setUrlType:(URLType)type {
    urlType = type;
}

+ (void)resetLinkAndURLType {
    MEGALinkManager.linkURL = nil;
    MEGALinkManager.urlType = URLTypeDefault;
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
    return selectedOption;
}

+ (void)setSelectedOption:(LinkOption)option {
    selectedOption = option;
}

+ (void)resetUtilsForLinksWithoutSession {
    [MEGALinkManager.nodesFromLinkMutableArray removeAllObjects];
    
    MEGALinkManager.selectedOption = LinkOptionDefault;
}

+ (void)processSelectedOptionOnLink {
    if (MEGALinkManager.selectedOption == LinkOptionDefault) {
        return;
    }
    
    switch (MEGALinkManager.selectedOption) {
        case LinkOptionImportNode: {
            MEGANode *node = [MEGALinkManager.nodesFromLinkMutableArray firstObject];
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
            
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            browserVC.selectedNodesArray = [NSArray arrayWithObject:node];
            [browserVC setBrowserAction:BrowserActionImport];
            break;
        }
            
        case LinkOptionDownloadNode: {
            MEGANode *node = [MEGALinkManager.nodesFromLinkMutableArray firstObject];
            if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                return;
            }
                
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [Helper downloadNode:node folderPath:Helper.relativePathForOffline isFolderLink:NO shouldOverwrite:NO];
            break;
        }
            
        case LinkOptionImportFolderOrNodes: {
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
            BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
            [browserVC setBrowserAction:BrowserActionImportFromFolderLink];
            browserVC.selectedNodesArray = [NSArray arrayWithArray:MEGALinkManager.nodesFromLinkMutableArray];
            
            [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
            break;
        }
            
        case LinkOptionDownloadFolderOrNodes: {
            for (MEGANode *node in MEGALinkManager.nodesFromLinkMutableArray) {
                if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:YES]) {
                    return;
                }
            }
                
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            for (MEGANode *node in MEGALinkManager.nodesFromLinkMutableArray) {
                [Helper downloadNode:node folderPath:Helper.relativePathForOffline isFolderLink:YES shouldOverwrite:NO];
            }
            break;
        }
            
        case LinkOptionJoinChatLink: {
            MEGAChatGenericRequestDelegate *openChatPreviewDelegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                if (error.type != MEGAErrorTypeApiOk && error.type != MEGAErrorTypeApiEExist) {
                    if (error.type == MEGAChatErrorTypeNoEnt) {
                        [SVProgressHUD dismiss];
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"Chat Link Unavailable", @"Shown when an invalid/inexisting/not-available-anymore chat link is opened.") message:AMLocalizedString(@"This chat link is no longer available", @"Shown when an inexisting/unavailable/removed link is tried to be opened.") preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
                    } else {
                        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, AMLocalizedString(error.name, nil)]];
                    }
                    return;
                }
                
                uint64_t chatId = request.chatHandle;
                NSString *chatTitle = request.text;
                MEGAChatGenericRequestDelegate *autojoinOrRejoinPublicChatDelegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                    if (!error.type) {
                        [MEGALinkManager.joiningOrLeavingChatBase64Handles removeObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                        NSString *identifier = [MEGASdk base64HandleForUserHandle:chatId];
                        NSString *notificationText = [NSString stringWithFormat:AMLocalizedString(@"You have joined %@", @"Text shown in a notification to let the user know that has joined a public chat room after login or account creation"), chatTitle];
                        if (DevicePermissionsHelper.shouldAskForNotificationsPermissions) {
                            [SVProgressHUD showSuccessWithStatus:notificationText];
                        } else {
                            [DevicePermissionsHelper notificationsPermissionWithCompletionHandler:^(BOOL granted) {
                                if (granted) {
                                    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                                    content.body = notificationText;
                                    content.sound = UNNotificationSound.defaultSound;
                                    content.userInfo = @{@"chatId" : @(chatId)};
                                    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                                    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                                        if (error) {
                                            [SVProgressHUD showSuccessWithStatus:notificationText];
                                        }
                                    }];
                                } else {
                                    [SVProgressHUD showSuccessWithStatus:notificationText];
                                }
                            }];
                        }
                    }
                }];
                MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:request.chatHandle];
                if (!chatRoom.isPreview && !chatRoom.isActive) {
                    [[MEGASdkManager sharedMEGAChatSdk] autorejoinPublicChat:request.chatHandle publicHandle:request.userHandle delegate:autojoinOrRejoinPublicChatDelegate];
                    [MEGALinkManager.joiningOrLeavingChatBase64Handles addObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                } else {
                    [[MEGASdkManager sharedMEGAChatSdk] autojoinPublicChat:request.chatHandle delegate:autojoinOrRejoinPublicChatDelegate];
                }
            }];
            [[MEGASdkManager sharedMEGAChatSdk] openChatPreview:MEGALinkManager.secondaryLinkURL delegate:openChatPreviewDelegate];
            [MEGALinkManager resetLinkAndURLType];
            MEGALinkManager.secondaryLinkURL = nil;
            
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
        if ([UIApplication.sharedApplication.keyWindow.rootViewController isKindOfClass:MainTabBarController.class]) {
            [node navigateToParentAndPresent];
        }
    } else {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            UIAlertController *theContentIsNotAvailableAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"theContentIsNotAvailableForThisAccount", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [theContentIsNotAvailableAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleCancel handler:nil]];
            
            [UIApplication.mnz_presentingViewController presentViewController:theContentIsNotAvailableAlertController animated:YES completion:nil];
        }
    }
    
    nodeToPresentBase64Handle = nil;
}

#pragma mark - Manage MEGA links

+ (NSString *)buildPublicLink:(NSString *)link withKey:(NSString *)key isFolder:(BOOL)isFolder {
    NSString *stringWithoutSymbols = [[link stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByReplacingOccurrencesOfString:@"!" withString:@""];
    NSString *publicHandle = [stringWithoutSymbols substringFromIndex:stringWithoutSymbols.length - 8];
    
    return [MEGASdkManager.sharedMEGASdk buildPublicLinkForHandle:publicHandle key:key isFolder:isFolder];
}

+ (void)processLinkURL:(NSURL *)url {
    if (!url) {
        return;
    }
    
    MEGALinkManager.urlType = url.mnz_type;
    switch (MEGALinkManager.urlType) {
        case URLTypeDefault:
            [MEGALinkManager.linkURL mnz_presentSafariViewController];
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
            MEGALinkManager.secondaryLinkURL = MEGALinkManager.linkURL;
            [MEGALinkManager showEncryptedLinkAlert:url.mnz_MEGAURL];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeConfirmationLink: {
            MEGAQuerySignupLinkRequestDelegate *querySignupLinkRequestDelegate = [MEGAQuerySignupLinkRequestDelegate.alloc initWithCompletion:nil urlType:MEGALinkManager.urlType];
            [MEGASdkManager.sharedMEGASdk querySignupLink:url.mnz_MEGAURL delegate:querySignupLinkRequestDelegate];
            break;
        }
            
        case URLTypeNewSignUpLink: {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [MEGALinkManager resetLinkAndURLType];

                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:AMLocalizedString(@"This link is not related to this account. Please log in with the correct account.", @"Error message shown when opening a link with an account that not corresponds to the link") preferredStyle:UIAlertControllerStyleAlert];
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDestructive handler:nil]];
                
                [UIApplication.mnz_visibleViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
            } else {
                MEGAQuerySignupLinkRequestDelegate *querySignupLinkRequestDelegate = [[MEGAQuerySignupLinkRequestDelegate alloc] initWithCompletion:nil urlType:MEGALinkManager.urlType];
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
            
        case URLTypeOpenChatSectionLink: {
            if ([Helper hasSession_alertIfNot]) {
                if ([UIApplication.sharedApplication.keyWindow.rootViewController isKindOfClass:MainTabBarController.class]) {
                    MainTabBarController *mainTBC = (MainTabBarController *) UIApplication.sharedApplication.keyWindow.rootViewController;
                    mainTBC.selectedIndex = CHAT;
                }
            }
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
            MEGALinkManager.nodeToPresentBase64Handle = [url.mnz_afterSlashesString substringFromIndex:1];
            [MEGALinkManager presentNode];
            
            break;
            
        case URLTypeAchievementsLink: {
            if ([Helper hasSession_alertIfNot]) {
                if ([UIApplication.sharedApplication.keyWindow.rootViewController isKindOfClass:MainTabBarController.class]) {
                    MainTabBarController *mainTBC = (MainTabBarController *) UIApplication.sharedApplication.keyWindow.rootViewController;
                    [mainTBC showAchievements];
                }
            }
            break;
        }
            
        case URLTypePublicChatLink: {
            [MEGALinkManager handlePublicChatLink];
            [MEGALinkManager resetLinkAndURLType];
            
            break;
        }
            
        case URLTypeChatPeerOptionsLink:
            [MEGALinkManager handleChatPeerOptionsLink];
            [MEGALinkManager resetLinkAndURLType];
            
            break;
            
        default:
            break;
    }
}

+ (void)showLinkNotValid {
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options:nil] firstObject];
    [unavailableLinkView configureInvalidQueryLink];
    unavailableLinkView.frame = [[UIScreen mainScreen] bounds];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    [viewController.view addSubview:unavailableLinkView];
    viewController.navigationItem.title = AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid");
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:viewController];
    [navigationController addRightCancelButton];
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    [MEGALinkManager resetLinkAndURLType];
}

+ (void)presentConfirmViewWithURLType:(URLType)urlType link:(NSString *)link email:(NSString *)email {
    MEGANavigationController *confirmAccountNavigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ConfirmAccountNavigationControllerID"];
    
    ConfirmAccountViewController *confirmAccountVC = confirmAccountNavigationController.viewControllers.firstObject;
    confirmAccountVC.urlType = urlType;
    confirmAccountVC.confirmationLinkString = link;
    confirmAccountVC.emailString = email;
    
    [UIApplication.mnz_presentingViewController presentViewController:confirmAccountNavigationController animated:YES completion:nil];
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
        MEGALinkManager.linkURL = [NSURL URLWithString:request.text];
        [MEGALinkManager processLinkURL:[NSURL URLWithString:request.text]];
    } onError:^(MEGARequest *request) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"To access this link, you will need its password.", @"This dialog message is used on the Password Decrypt dialog. The link is a password protected link so the user needs to enter the password to decrypt the link.") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [MEGALinkManager showEncryptedLinkAlert:request.link];
        }]];
        
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"To access this link, you will need its password.", @"This dialog message is used on the Password Decrypt dialog. The link is a password protected link so the user needs to enter the password to decrypt the link.") message:AMLocalizedString(@"If you do not have the password, contact the creator of the link.", @"This dialog message is used on the Password Decrypt dialog as an instruction for the user.") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = AMLocalizedString(@"Enter the password", @"This placeholder text is used on the Password Decrypt dialog as an instruction for the user.");
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
        textField.secureTextEntry = YES;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[MEGASdkManager sharedMEGASdk] decryptPasswordProtectedLink:encryptedLinkURLString password:alertController.textFields.firstObject.text delegate:delegate];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [MEGALinkManager resetLinkAndURLType];
        MEGALinkManager.secondaryLinkURL = nil;
    }]];
    
    [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)alertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if (alertController) {
        UIAlertAction *rightButtonAction = alertController.actions.firstObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

+ (void)showFileLinkView {
    NSString *fileLinkURLString = MEGALinkManager.linkURL.mnz_MEGAURL;
    MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (error.type) {
            [MEGALinkManager presentFileLinkViewForLink:fileLinkURLString request:request error:error];
        } else {
            MEGANode *node = request.publicNode;
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
                if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
                    NSError *nserror;
                    if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&nserror]) {
                        MEGALogError(@"Create directory at path failed with error: %@", nserror);
                    }
                }
                
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[node].mutableCopy api:[MEGASdkManager sharedMEGASdkFolder] displayMode:DisplayModeFileLink presentingNode:node preferredIndex:0];
                photoBrowserVC.publicLink = fileLinkURLString;
                photoBrowserVC.encryptedLink = MEGALinkManager.secondaryLinkURL.absoluteString;
                
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
    fileLinkVC.linkEncryptedString = MEGALinkManager.secondaryLinkURL.absoluteString;
    fileLinkVC.request = request;
    fileLinkVC.error = error;
    
    [UIApplication.mnz_visibleViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
}

+ (void)showFolderLinkView {
    MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
    
    FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
    
    folderlinkVC.isFolderRootNode = YES;
    folderlinkVC.publicLinkString = MEGALinkManager.linkURL.mnz_MEGAURL;
    folderlinkVC.linkEncryptedString = MEGALinkManager.secondaryLinkURL.absoluteString;
    
    [UIApplication.mnz_visibleViewController presentViewController:folderNavigationController animated:YES completion:nil];
}

+ (void)showBackupLinkView {
    if ([Helper hasSession_alertIfNot]) {
        MasterKeyViewController *masterKeyVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"MasterKeyViewControllerID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:masterKeyVC];
        [navigationController addRightCancelButton];
        
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
    NSString *afterSlashesString = [MEGALinkManager.linkURL mnz_afterSlashesString];
    NSRange rangeOfPrefix = [afterSlashesString rangeOfString:@"C!"];
    NSString *contactLinkHandle = [afterSlashesString substringFromIndex:(rangeOfPrefix.location + rangeOfPrefix.length)];
    uint64_t handle = [MEGASdk handleForBase64Handle:contactLinkHandle];

    MEGAContactLinkQueryRequestDelegate *delegate = [[MEGAContactLinkQueryRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", request.name, request.text];
        [MEGALinkManager presentInviteModalForEmail:request.email fullName:fullName contactLinkHandle:request.nodeHandle image:request.file];
        
        [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:request.nodeHandle] forKey:MEGALastPublicHandleAccessed];
        [NSUserDefaults.standardUserDefaults setInteger:AffiliateTypeContact forKey:MEGALastPublicTypeAccessed];
        [NSUserDefaults.standardUserDefaults setDouble:NSDate.date.timeIntervalSince1970 forKey:MEGALastPublicTimestampAccessed];
        if (@available(iOS 12.0, *)) {} else {
            [NSUserDefaults.standardUserDefaults synchronize];
        }
    } onError:^(MEGAError *error) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid")];
    }];

    [[MEGASdkManager sharedMEGASdk] contactLinkQueryWithHandle:handle delegate:delegate];
}

+ (void)presentInviteModalForEmail:(NSString *)email fullName:(NSString *)fullName contactLinkHandle:(uint64_t)contactLinkHandle image:(NSString *)imageOnBase64URLEncoding {
    CustomModalAlertViewController *inviteOrDismissModal = [[CustomModalAlertViewController alloc] init];
    
    if (imageOnBase64URLEncoding.mnz_isEmpty) {
        inviteOrDismissModal.image = [UIImage imageForName:fullName.mnz_initialForAvatar size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor mnz_fromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:UIColor.whiteColor font:[UIFont systemFontOfSize:64.0f]];
    } else {
        inviteOrDismissModal.roundImage = YES;
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:[NSString mnz_base64FromBase64URLEncoding:imageOnBase64URLEncoding] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        inviteOrDismissModal.image = [UIImage imageWithData:imageData];
    }
    
    inviteOrDismissModal.viewTitle = fullName;
    
    __weak UIViewController *weakVisibleVC = [UIApplication mnz_visibleViewController];
    __weak CustomModalAlertViewController *weakInviteOrDismissModal = inviteOrDismissModal;
    void (^firstCompletion)(void) = ^{
        MEGAInviteContactRequestDelegate *delegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1 presentSuccessOver:weakVisibleVC completion:nil];
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd handle:contactLinkHandle delegate:delegate];
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    void (^dismissCompletion)(void) = ^{
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:email];
    if (user && user.visibility == MEGAUserVisibilityVisible) {
        inviteOrDismissModal.detail = [AMLocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.") stringByReplacingOccurrencesOfString:@"%s" withString:email];
        inviteOrDismissModal.firstButtonTitle = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        inviteOrDismissModal.firstCompletion = dismissCompletion;
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
            inviteOrDismissModal.firstButtonTitle = AMLocalizedString(@"close", nil);
            inviteOrDismissModal.firstCompletion = dismissCompletion;
        } else {
            inviteOrDismissModal.detail = email;
            inviteOrDismissModal.firstButtonTitle = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
            inviteOrDismissModal.dismissButtonTitle = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
            inviteOrDismissModal.firstCompletion = firstCompletion;
            inviteOrDismissModal.dismissCompletion = dismissCompletion;
        }
    }
    
    [UIApplication.mnz_presentingViewController presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

+ (void)handlePublicChatLink {
    NSURL *chatLinkUrl = MEGALinkManager.linkURL;
    [SVProgressHUD show];
    
    MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
        if (error.type != MEGAErrorTypeApiOk && error.type != MEGAErrorTypeApiEExist) {
            if (error.type == MEGAChatErrorTypeNoEnt) {
                [SVProgressHUD dismiss];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"Chat Link Unavailable", @"Shown when an invalid/inexisting/not-available-anymore chat link is opened.") message:AMLocalizedString(@"This chat link is no longer available", @"Shown when an inexisting/unavailable/removed link is tried to be opened.") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
            } else {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, AMLocalizedString(error.name, nil)]];
            }
            return;
        }
        
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:request.chatHandle];
        if (!chatRoom.isPreview && !chatRoom.isActive) {
            MEGAChatGenericRequestDelegate *autorejoinPublicChatDelegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                if (error.type) {
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, AMLocalizedString(error.name, nil)]];
                    return;
                }
                [MEGALinkManager.joiningOrLeavingChatBase64Handles removeObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                [MEGALinkManager createChatAndShow:request.chatHandle publicChatLink:chatLinkUrl];
            }];
            [[MEGASdkManager sharedMEGAChatSdk] autorejoinPublicChat:request.chatHandle publicHandle:request.userHandle delegate:autorejoinPublicChatDelegate];
            [MEGALinkManager.joiningOrLeavingChatBase64Handles addObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
        } else {
            [MEGALinkManager createChatAndShow:request.chatHandle publicChatLink:chatLinkUrl];
        }
        
        [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:request.chatHandle] forKey:MEGALastPublicHandleAccessed];
        [NSUserDefaults.standardUserDefaults setInteger:AffiliateTypeChat forKey:MEGALastPublicTypeAccessed];
        [NSUserDefaults.standardUserDefaults setDouble:NSDate.date.timeIntervalSince1970 forKey:MEGALastPublicTimestampAccessed];
        if (@available(iOS 12.0, *)) {} else {
            [NSUserDefaults.standardUserDefaults synchronize];
        }
        
        [SVProgressHUD dismiss];
    }];
    
    if (![MEGASdkManager sharedMEGAChatSdk]) {
        [MEGASdkManager createSharedMEGAChatSdk];
    }
    MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initState];
    if (chatInit == MEGAChatInitNotDone) {
        chatInit = [[MEGASdkManager sharedMEGAChatSdk] initAnonymous];
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere anonymous failed");
            [[MEGASdkManager sharedMEGAChatSdk] logout];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Error (%td) initializing the chat", chatInit]];
            return;
        }
    }
    
    [MEGASdkManager.sharedMEGAChatSdk connect];
    [[MEGASdkManager sharedMEGAChatSdk] openChatPreview:chatLinkUrl delegate:delegate];
}

+ (void)createChatAndShow:(uint64_t)chatId publicChatLink:(NSURL *)publicChatLink {
    
    if ([UIApplication.mnz_visibleViewController isKindOfClass:ChatViewController.class]) {
        ChatViewController *currentChatViewController = (ChatViewController *)UIApplication.mnz_visibleViewController;
        if (currentChatViewController.chatRoom.chatId == chatId) {
            [SVProgressHUD dismiss];
            return;
        }
    }
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([rootViewController isKindOfClass:MainTabBarController.class]) {
     
        ChatViewController *chatViewController = [ChatViewController.alloc init];
        chatViewController.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatId];
        chatViewController.publicChatLink = publicChatLink;
        
        
        MainTabBarController *mainTBC = (MainTabBarController *)rootViewController;
        mainTBC.selectedIndex = CHAT;
        
        if (mainTBC.presentedViewController) {
            [mainTBC dismissViewControllerAnimated:NO completion:^{
                [MEGALinkManager pushChat:chatViewController tabBar:mainTBC];
            }];
        } else {
            [MEGALinkManager pushChat:chatViewController tabBar:mainTBC];
        }
    } else {
        ChatViewController *chatViewController = [ChatViewController.alloc init];
           chatViewController.chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatId];
           chatViewController.publicChatLink = publicChatLink;
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:chatViewController];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

+ (void)pushChat:(ChatViewController *)chatViewController tabBar:(MainTabBarController *)mainTBC {
    UINavigationController *chatNC = mainTBC.selectedViewController;
    
    for (UIViewController *viewController in chatNC.viewControllers) {
        if ([viewController isKindOfClass:ChatViewController.class]) {
            ChatViewController *currentChatViewController = (ChatViewController *)viewController;
            [currentChatViewController closeChatRoom];
        }
    }
    
    [chatNC pushViewController:chatViewController animated:YES];
    
    NSMutableArray *viewControllers = chatNC.viewControllers.mutableCopy;
    NSInteger limit = chatNC.viewControllers.count - 2;
    for (NSInteger i = 1; i <= limit; i++) {
        [viewControllers removeObjectAtIndex:1];
    }
    chatNC.viewControllers = viewControllers;
}

+ (void)handleChatPeerOptionsLink {
    NSString *base64UserHandle = [MEGALinkManager.linkURL.absoluteString componentsSeparatedByString:@"#"].lastObject;
    
    if (!base64UserHandle) {
        return;
    }
    
    if (![UIApplication.mnz_visibleViewController isKindOfClass:MessagesViewController.class]) {
        return;
    }
    
    ChatViewController *chatViewController = (ChatViewController *)UIApplication.mnz_visibleViewController;
    [chatViewController showOptionsForPeerWithHandle:[MEGASdk handleForBase64UserHandle:base64UserHandle] senderView:nil];
}

+ (NSMutableSet<NSString *> *)joiningOrLeavingChatBase64Handles {
    if (!joiningOrLeavingChatBase64Handles) {
        joiningOrLeavingChatBase64Handles = NSMutableSet.new;
    }
    return joiningOrLeavingChatBase64Handles;
}

@end
