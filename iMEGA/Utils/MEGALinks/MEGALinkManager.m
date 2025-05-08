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

#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "MasterKeyViewController.h"
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
#import "UnavailableLinkView.h"
#import "MEGA-Swift.h"

@import ChatRepo;
@import MEGAL10nObjc;
@import MEGAUIKit;

static NSURL *linkURL;
static NSURL *secondaryLinkURL;
static URLType urlType;

static NSString *emailOfNewSignUpLink;

static NSMutableArray *nodesFromLinkMutableArray;
static LinkOption selectedOption;
static NSString *linkSavedString;
static SendToChatWrapper *sendToChatWrapper;
static NSString *nodeToPresentBase64Handle;

static NSMutableSet<NSString *> *joiningOrLeavingChatBase64Handles;

@implementation MEGALinkManager

#pragma mark - Utils to manage MEGA links

+ (NSURL * _Nullable)linkURL {
    return linkURL;
}

+ (void)setLinkURL:(NSURL * _Nullable)link {
    linkURL = link;
}

+ (NSURL * _Nullable)secondaryLinkURL {
    return secondaryLinkURL;
}

+ (void)setSecondaryLinkURL:(NSURL * _Nullable)secondaryLink {
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

+ ( NSString * _Nullable)emailOfNewSignUpLink {
    return emailOfNewSignUpLink;
}

+ (void)setEmailOfNewSignUpLink:(NSString * _Nullable)email {
    emailOfNewSignUpLink = email;
}

+ (SendToChatWrapper *)sendToChatWrapper {
    return sendToChatWrapper;
}

+ (void)setSendToChatWrapper:(SendToChatWrapper *)wrapper {
    sendToChatWrapper = wrapper;
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

+ (NSString *)linkSavedString {
    return linkSavedString;
}

+ (void)setLinkSavedString:(NSString *)link {
    linkSavedString = link;
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
            [MEGALinkManager downloadFileLinkAfterLogin];
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
            [self downloadFolderLinkAfterLogin];
            break;
        }
            
        case LinkOptionJoinChatLink: {
            ChatRequestDelegate *openChatPreviewDelegate = [[ChatRequestDelegate alloc] initWithRawSuccessCodes:@[@(MEGAChatErrorTypeOk), @(MEGAErrorTypeApiEExist)] completion:^(MEGAChatRequest *request, MEGAChatError *error) {
                if (error) {
                    if (error.type == MEGAChatErrorTypeNoEnt) {
                        [SVProgressHUD dismiss];
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Chat Link Unavailable", @"Shown when an invalid/inexisting/not-available-anymore chat link is opened.") message:LocalizedString(@"This chat link is no longer available", @"Shown when an inexisting/unavailable/removed link is tried to be opened.") preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
                    } else {
                        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
                    }
                    return;
                }
                
                uint64_t chatId = request.chatHandle;
                NSString *chatTitle = request.text;
                NSURL *chatLink = request.link;
                ChatRequestDelegate *autojoinOrRejoinPublicChatDelegate = [[ChatRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                    if (!error.type) {
                        [MEGALinkManager.joiningOrLeavingChatBase64Handles removeObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                        
                        DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
                        
                        [handler shouldAskForNotificationsPermissionsWithHandler:^(BOOL shouldAsk) {
                            [self continueWithChatId:chatId
                                           chatTitle:chatTitle
                                            chatLink:chatLink
                shouldAskForNotificationsPermissions:shouldAsk
                                   permissionHandler:handler];
                        }];
                    }
                }];
                MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:request.chatHandle];
                if (!chatRoom.isPreview && !chatRoom.isActive) {
                    [MEGAChatSdk.shared autorejoinPublicChat:request.chatHandle publicHandle:request.userHandle delegate:autojoinOrRejoinPublicChatDelegate];
                    [MEGALinkManager.joiningOrLeavingChatBase64Handles addObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                } else {
                    if (chatRoom.ownPrivilege == MEGAChatRoomPrivilegeUnknown) {
                        [MEGAChatSdk.shared autojoinPublicChat:request.chatHandle delegate:autojoinOrRejoinPublicChatDelegate];
                    } else {
                        [self createChatAndShow:chatId publicChatLink:request.link];
                    }
                }
            }];
            [MEGAChatSdk.shared openChatPreview:MEGALinkManager.secondaryLinkURL delegate:openChatPreviewDelegate];
            [MEGALinkManager resetLinkAndURLType];
            MEGALinkManager.secondaryLinkURL = nil;
            
            break;
        }
            
        case LinkOptionSendNodeLinkToChat:
            [self sendNodeLinkToChatAfterLogin];
            break;
            
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
    MEGANode *node = [MEGASdk.shared nodeForHandle:handle];
    if (node) {
        if (UIApplication.mainTabBarRootViewController) {
            [node navigateToParentAndPresent];
        }
    } else {
        if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
            UIAlertController *theContentIsNotAvailableAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"theContentIsNotAvailableForThisAccount", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [theContentIsNotAvailableAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleCancel handler:nil]];
            
            [UIApplication.mnz_presentingViewController presentViewController:theContentIsNotAvailableAlertController animated:YES completion:nil];
        }
    }
    
    nodeToPresentBase64Handle = nil;
}

#pragma mark - Manage MEGA links

+ (NSString *)buildPublicLink:(NSString *)link withKey:(NSString *)key isFolder:(BOOL)isFolder {
    NSString *stringWithoutSymbols = [[link stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByReplacingOccurrencesOfString:@"!" withString:@""];
    NSString *publicHandle = [stringWithoutSymbols substringFromIndex:stringWithoutSymbols.length - 8];
    
    return [MEGASdk.shared buildPublicLinkForHandle:publicHandle key:key isFolder:isFolder];
}

+ (void)processLinkURL:(NSURL * _Nullable)url {
    if (!url) {
        return;
    }

    MEGALinkManager.urlType = url.mnz_type;
    switch (MEGALinkManager.urlType) {
        case URLTypeDefault:
            [MEGALinkManager openDefaultLink: url];
            break;
            
        case URLTypeOpenInLink:
            [MEGALinkManager openIn];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeFileRequestLink:
            [MEGALinkManager openBrowserBy:MEGALinkManager.linkURL.mnz_MEGAURL];
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
            NSString *link = url.mnz_MEGAURL;
            if ([url.path hasPrefix:@"/confirm"]) {
                link = [link stringByReplacingOccurrencesOfString:@"confirm" withString:@"#confirm"];
            }
            [MEGASdk.shared querySignupLink:link delegate:querySignupLinkRequestDelegate];
            break;
        }
            
        case URLTypeNewSignUpLink: {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                [MEGALinkManager resetLinkAndURLType];

                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"error", @"") message:LocalizedString(@"This link is not related to this account. Please log in with the correct account.", @"Error message shown when opening a link with an account that not corresponds to the link") preferredStyle:UIAlertControllerStyleAlert];
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDestructive handler:nil]];
                
                [UIApplication.mnz_visibleViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
            } else {
                MEGAQuerySignupLinkRequestDelegate *querySignupLinkRequestDelegate = [[MEGAQuerySignupLinkRequestDelegate alloc] initWithCompletion:nil urlType:MEGALinkManager.urlType];
                [MEGASdk.shared querySignupLink:url.mnz_MEGAURL delegate:querySignupLinkRequestDelegate];
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
                [MEGASdk.shared queryChangeEmailLink:url.mnz_MEGAURL delegate:queryRecoveryLinkRequestDelegate];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"needToBeLoggedInToCompleteYourEmailChange", @"Error message when a user attempts to change their email without an active login session.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
            }
            break;
        }
            
        case URLTypeCancelAccountLink: {
            if ([Helper hasSession_alertIfNot]) {
                MEGAQueryRecoveryLinkRequestDelegate *queryRecoveryLinkRequestDelegate = [[MEGAQueryRecoveryLinkRequestDelegate alloc] initWithRequestCompletion:nil urlType:URLTypeCancelAccountLink];
                [MEGASdk.shared queryCancelLink:url.mnz_MEGAURL delegate:queryRecoveryLinkRequestDelegate];
            }
            break;
        }
            
        case URLTypeRecoverLink: {
            MEGAQueryRecoveryLinkRequestDelegate *queryRecoveryLinkRequestDelegate = [[MEGAQueryRecoveryLinkRequestDelegate alloc] initWithRequestCompletion:nil urlType:URLTypeRecoverLink];
            [MEGASdk.shared queryResetPasswordLink:url.mnz_MEGAURL delegate:queryRecoveryLinkRequestDelegate];
            break;
        }
            
        case URLTypeContactLink:
            if ([Helper hasSession_alertIfNot]) {
                [MEGALinkManager handleContactLink];
            }
            break;
            
        case URLTypeOpenChatSectionLink: {
            if ([Helper hasSession_alertIfNot]) {
                if (UIApplication.mainTabBarRootViewController) {
                    MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                    mainTBC.selectedIndex = TabTypeChat;
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
            MEGALinkManager.nodeToPresentBase64Handle = url.fragment;
            [MEGALinkManager presentNode];
            
            break;
            
        case URLTypeAchievementsLink: {
            if ([Helper hasSession_alertIfNot]) {
                if (UIApplication.mainTabBarRootViewController) {
                    MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                    [mainTBC showAchievements];
                }
            }
            break;
        }
            
        case URLTypeScheduleChatLink:
            [MEGALinkManager openBrowserBy:MEGALinkManager.linkURL.absoluteString];
            break;
            
        case URLTypePublicChatLink: {
            [MEGALinkManager handlePublicChatLink];
            [MEGALinkManager resetLinkAndURLType];
            
            break;
        }
            
        case URLTypeChatPeerOptionsLink:
            [MEGALinkManager handleChatPeerOptionsLink];
            [MEGALinkManager resetLinkAndURLType];
            
            break;
            
        case URLTypeUploadFile:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showUploadFile];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypeScanDocument:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showScanDocument];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypeStartConversation:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showStartConversation];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypeAddContact:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showAddContact];
                [self resetLinkAndURLType];
            }
            break;

        case URLTypePresentNode:
            self.nodeToPresentBase64Handle = [url.absoluteString componentsSeparatedByString:@"/"].lastObject;
            [self presentNode];
            [MEGALinkManager resetLinkAndURLType];
            break;
            
        case URLTypeShowOffline:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showOfflineAndPresentFileWithHandle:nil];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypePresentOfflineFile:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showOfflineAndPresentFileWithHandle:url.lastPathComponent];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypeShowFavourites:
        case URLTypePresentFavouritesNode:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                (MEGALinkManager.urlType == URLTypeShowFavourites) ? [mainTBC showFavouritesNodeWithHandle:nil] : [mainTBC showFavouritesNodeWithHandle:url.lastPathComponent];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypeShowRecents:
            if ([Helper hasSession_alertIfNot] && UIApplication.mainTabBarRootViewController) {
                MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
                [mainTBC showRecents];
                [self resetLinkAndURLType];
            }
            break;
            
        case URLTypeNewTextFile:
            [[CreateTextFileAlertViewRouter.alloc initWithPresenter:UIApplication.mnz_presentingViewController] start];
            break;
            
        case URLTypeAppSettings:
            if ([UIApplication.sharedApplication canOpenURL:url]) {
                [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
            }
            break;
        case URLTypeCollection:
            [MEGALinkManager showCollectionLinkView];
            [MEGALinkManager resetLinkAndURLType];
            break;
        case URLTypeUpgrade:
        {
            [MEGALinkManager processUpgradeLink];
            break;
        }
        case URLTypeVpn:
            [MEGALinkManager openVPNApp];
            break;
        case URLTypeCameraUploadsSettings:
            if ([Helper hasSession_alertIfNot]) {
                [MEGALinkManager navigateToCameraUploadsSettings];
            }
        case URLTypePwm:
            [MEGALinkManager openPWMApp];
        case URLTypeSiteTransfer:
            [MEGALinkManager openDefaultLink: url];
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
    viewController.navigationItem.title = LocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid");
    
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
        browserVC.localpath = linkURL.absoluteString; // "file://" = 7 characters
        browserVC.browserAction = BrowserActionOpenIn;
        
        [UIApplication.mnz_visibleViewController presentViewController:browserNavigationController animated:YES completion:nil];
    }
}

+ (void)showEncryptedLinkAlert:(NSString *)encryptedLinkURLString {
    MEGAPasswordLinkRequestDelegate *delegate = [[MEGAPasswordLinkRequestDelegate alloc] initForDecryptionWithCompletion:^(MEGARequest *request) {
        MEGALinkManager.linkURL = [NSURL URLWithString:request.text];
        [MEGALinkManager processLinkURL:[NSURL URLWithString:request.text]];
    } onError:^(MEGARequest *request) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"To access this link, you will need its password.", @"This dialog message is used on the Password Decrypt dialog. The link is a password protected link so the user needs to enter the password to decrypt the link.") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [MEGALinkManager showEncryptedLinkAlert:request.link];
        }]];
        
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"To access this link, you will need its password.", @"This dialog message is used on the Password Decrypt dialog. The link is a password protected link so the user needs to enter the password to decrypt the link.") message:LocalizedString(@"If you do not have the password, contact the creator of the link.", @"This dialog message is used on the Password Decrypt dialog as an instruction for the user.") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LocalizedString(@"Enter the password", @"This placeholder text is used on the Password Decrypt dialog as an instruction for the user.");
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
        textField.secureTextEntry = YES;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdk.shared decryptPasswordProtectedLink:encryptedLinkURLString password:alertController.textFields.firstObject.text delegate:delegate];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [MEGALinkManager resetLinkAndURLType];
        MEGALinkManager.secondaryLinkURL = nil;
    }]];
    
    [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)alertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if ([alertController isKindOfClass:UIAlertController.class]) {
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
            if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
                NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
                if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
                    NSError *nserror;
                    if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&nserror]) {
                        MEGALogError(@"Create directory at path failed with error: %@", nserror);
                    }
                }
                
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[node].mutableCopy api:MEGASdk.sharedFolderLink displayMode:DisplayModeFileLink isFromSharedItem:NO presentingNode:node];
                photoBrowserVC.publicLink = fileLinkURLString;
                photoBrowserVC.encryptedLink = MEGALinkManager.secondaryLinkURL.absoluteString;
                photoBrowserVC.needsReload = YES;

                [self presentViewControllerWithAds:photoBrowserVC
                                        publicLink:fileLinkURLString
                                      isFolderLink:false
                             adsSlotViewController:photoBrowserVC
                                 presentationStyle:UIModalPresentationAutomatic];
            } else if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:node.name] && node.mnz_isPlayable) {
                [self initFullScreenPlayerWithNode:node fileLink:fileLinkURLString filePaths:nil isFolderLink:NO isFromSharedItem:NO presenter:UIApplication.mnz_visibleViewController];
            } else {
                [MEGALinkManager presentFileLinkViewForLink:fileLinkURLString request:request error:error];
            }
        }
        
        [SVProgressHUD dismiss];
    }];
    delegate.savePublicHandle = YES;
    
    [SVProgressHUD show];
    [MEGASdk.shared publicNodeForMegaFileLink:fileLinkURLString delegate:delegate];
}

+ (void)presentFileLinkViewForLink:(NSString *)link request:(MEGARequest *)request error:(MEGAError *)error {
    MEGANavigationController *fileLinkNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkNavigationControllerID"];
    FileLinkViewController *fileLinkVC = fileLinkNavigationController.viewControllers.firstObject;
    fileLinkVC.publicLinkString = link;
    fileLinkVC.linkEncryptedString = MEGALinkManager.secondaryLinkURL.absoluteString;
    fileLinkVC.request = request;
    fileLinkVC.error = error;
    
    [self presentViewControllerWithAds:fileLinkNavigationController
                            publicLink:link
                          isFolderLink:false
                 adsSlotViewController:fileLinkVC
                     presentationStyle:UIModalPresentationAutomatic];
}

+ (void)showFolderLinkView {
    MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
    FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
    
    NSString *link = MEGALinkManager.linkURL.mnz_MEGAURL;
    folderlinkVC.isFolderRootNode = YES;
    folderlinkVC.publicLinkString = link;
    folderlinkVC.linkEncryptedString = MEGALinkManager.secondaryLinkURL.absoluteString;
    
    folderlinkVC.player = [AudioPlayerManager.shared currentPlayer];
    
    [self presentViewControllerWithAds:folderNavigationController
                            publicLink:link
                          isFolderLink:true
                 adsSlotViewController:folderlinkVC
                     presentationStyle:UIModalPresentationFullScreen];
}

+ (void)showContactRequestsView {
    if ([Helper hasSession_alertIfNot]) {
        ContactRequestsViewController *contactsRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:contactsRequestsVC];
        [UIApplication.mnz_visibleViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

+ (void)handleContactLink {
    NSString *path = [MEGALinkManager.linkURL absoluteString];
    NSRange rangeOfPrefix = [path rangeOfString:@"C!"];
    if (rangeOfPrefix.location == NSNotFound) {
        return;
    }
    NSString *contactLinkHandle = [path substringFromIndex:(rangeOfPrefix.location + rangeOfPrefix.length)];
    uint64_t handle = [MEGASdk handleForBase64Handle:contactLinkHandle];

    MEGAContactLinkQueryRequestDelegate *delegate = [[MEGAContactLinkQueryRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", request.name, request.text];
        [MEGALinkManager presentInviteModalForEmail:request.email fullName:fullName contactLinkHandle:request.nodeHandle image:request.file];
    } onError:^(MEGAError *error) {
        [SVProgressHUD showErrorWithStatus:LocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid")];
    }];

    [MEGASdk.shared contactLinkQueryWithHandle:handle delegate:delegate];
}

+ (void)presentInviteModalForEmail:(NSString *)email fullName:(NSString *)fullName contactLinkHandle:(uint64_t)contactLinkHandle image:(NSString *)imageOnBase64URLEncoding {
    CustomModalAlertViewController *inviteOrDismissModal = [[CustomModalAlertViewController alloc] init];
    
    if (imageOnBase64URLEncoding.mnz_isEmpty) {
        inviteOrDismissModal.image = [UIImage imageForName:fullName.mnz_initialForAvatar size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor mnz_fromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:UIColor.whiteTextColor font:[UIFont systemFontOfSize:64.0f]];
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
        [MEGASdk.shared inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd handle:contactLinkHandle delegate:delegate];
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    void (^dismissCompletion)(void) = ^{
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    MEGAUser *user = [MEGASdk.shared contactForEmail:email];
    if (user && user.visibility == MEGAUserVisibilityVisible) {
        inviteOrDismissModal.detail = [LocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.") stringByReplacingOccurrencesOfString:@"%s" withString:email];
        inviteOrDismissModal.firstButtonTitle = LocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        inviteOrDismissModal.firstCompletion = dismissCompletion;
    } else {
        BOOL isInOutgoingContactRequest = NO;
        MEGAContactRequestList *outgoingContactRequestList = [MEGASdk.shared outgoingContactRequests];
        for (NSInteger i = 0; i < outgoingContactRequestList.size; i++) {
            MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
            if ([email isEqualToString:contactRequest.targetEmail]) {
                isInOutgoingContactRequest = YES;
                break;
            }
        }
        if (isInOutgoingContactRequest) {
            inviteOrDismissModal.image = [UIImage imageNamed:@"contactInviteSent"];
            inviteOrDismissModal.viewTitle = LocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
            NSString *detailText = LocalizedString(@"dialog.inviteContact.outgoingContactRequest", @"Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user");
            detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:email];
            inviteOrDismissModal.detail = detailText;
            inviteOrDismissModal.boldInDetail = email;
            inviteOrDismissModal.firstButtonTitle = LocalizedString(@"close", @"");
            inviteOrDismissModal.firstCompletion = dismissCompletion;
        } else {
            inviteOrDismissModal.detail = email;
            inviteOrDismissModal.firstButtonTitle = LocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
            inviteOrDismissModal.dismissButtonTitle = LocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
            inviteOrDismissModal.firstCompletion = firstCompletion;
            inviteOrDismissModal.dismissCompletion = dismissCompletion;
        }
    }
    
    [UIApplication.mnz_presentingViewController presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

+ (void)handlePublicChatLink {
    NSURL *chatLinkUrl = MEGALinkManager.linkURL;
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear]; // Disable background user interaction.
    
    ChatRequestDelegate *delegate = [[ChatRequestDelegate alloc] initWithRawSuccessCodes:@[@(MEGAChatErrorTypeOk), @(MEGAErrorTypeApiEExist)] completion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
        if (error) {
            if (error.type == MEGAChatErrorTypeNoEnt) {
                [SVProgressHUD dismiss];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Chat Link Unavailable", @"Shown when an invalid/inexisting/not-available-anymore chat link is opened.") message:LocalizedString(@"This chat link is no longer available", @"Shown when an inexisting/unavailable/removed link is tried to be opened.") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
            } else {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
            }
            return;
        }
        
        if (request.paramType == 1) { // Meeting link
            if (request.flag) {
                [self openMeetingWithRequest:request chatLinkURL:chatLinkUrl];
            } else {
                MEGALogDebug(@"Unable to open the meeting link %@", chatLinkUrl);
                [SVProgressHUD dismiss];
            }
        } else { // Chat link
            MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:request.chatHandle];
            if (!chatRoom.isPreview && !chatRoom.isActive) {
                ChatRequestDelegate *autorejoinPublicChatDelegate = [[ChatRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                    if (error.type) {
                        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
                        return;
                    }
                    [MEGALinkManager.joiningOrLeavingChatBase64Handles removeObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                    [MEGALinkManager createChatAndShow:request.chatHandle publicChatLink:chatLinkUrl];
                }];
                [MEGAChatSdk.shared autorejoinPublicChat:request.chatHandle publicHandle:request.userHandle delegate:autorejoinPublicChatDelegate];
                [MEGALinkManager.joiningOrLeavingChatBase64Handles addObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
            } else {
                [MEGALinkManager createChatAndShow:request.chatHandle publicChatLink:chatLinkUrl];
            }
            
            [SVProgressHUD dismiss];
        }
    }];
    
    MEGAChatInit chatInit = [MEGAChatSdk.shared initState];
    if (chatInit == MEGAChatInitNotDone) {
        chatInit = [MEGAChatSdk.shared initAnonymous];
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere anonymous failed");
            [MEGAChatSdk.shared logout];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Error (%td) initializing the chat", chatInit]];
            return;
        }
    }
    
    [MEGAChatSdk.shared checkChatLink:chatLinkUrl delegate:[[ChatRequestDelegate alloc] initWithRawSuccessCodes:@[@(MEGAChatErrorTypeOk), @(MEGAErrorTypeApiEExist)] completion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
        if (error) {
            if (error.type == MEGAChatErrorTypeNoEnt) {
                [SVProgressHUD dismiss];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Chat Link Unavailable", @"Shown when an invalid/inexisting/not-available-anymore chat link is opened.") message:LocalizedString(@"This chat link is no longer available", @"Shown when an inexisting/unavailable/removed link is tried to be opened.") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
            } else if (error.type == MEGAChatErrorTypeArgs)  {
                [SVProgressHUD dismiss];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"meetings.joinMeeting.header", @"") message:LocalizedString(@"meetings.joinMeeting.description", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
            } else {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
            }
            return;
        }
        
        if (request.paramType == 1 && request.flag) {
            [self openMeetingWithRequest:request chatLinkURL:chatLinkUrl];
        } else {
            [MEGAChatSdk.shared openChatPreview:chatLinkUrl delegate:delegate];
        }
    }]];
}

+ (void)openMeetingWithRequest:(MEGAChatRequest * _Nonnull)request chatLinkURL:(NSURL * _Nonnull)chatLinkUrl {
    if ([self shouldOpenWaitingRoomWithRequest:request chatSdk:MEGAChatSdk.shared]) {
        [SVProgressHUD dismiss];
        [self openWaitingRoomFor:request.chatHandle chatLink:chatLinkUrl.absoluteString requestUserHandle:request.userHandle];
    } else if ([self hasActiveMeetingFor:request]) {
        // Meeting started
        [SVProgressHUD dismiss];
        if ([self isHostInWaitingRoomWithRequest:request chatSdk:MEGAChatSdk.shared]) {
            [self joinCallWithRequest:request];
        } else {
            [self createMeetingAndShow:request.chatHandle userHandle:request.userHandle publicChatLink:chatLinkUrl];
        }
    } else {
        // Meeting ended or not yet began
        [SVProgressHUD dismiss];
        MEGAChatRoom *chatRoom = [[MEGAChatSdk shared] chatRoomForChatId:request.chatHandle];
        if (!chatRoom.isPreview && !chatRoom.isActive) {
            ChatRequestDelegate *autorejoinPublicChatDelegate = [[ChatRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                if (error.type) {
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
                    return;
                }
                [MEGALinkManager.joiningOrLeavingChatBase64Handles removeObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
                [MEGALinkManager createChatAndShow:request.chatHandle publicChatLink:chatLinkUrl];
            }];
            [MEGAChatSdk.shared autorejoinPublicChat:request.chatHandle publicHandle:request.userHandle delegate:autorejoinPublicChatDelegate];
            [MEGALinkManager.joiningOrLeavingChatBase64Handles addObject:[MEGASdk base64HandleForUserHandle:request.chatHandle]];
        } else {
            [MEGALinkManager createChatAndShow:request.chatHandle publicChatLink:chatLinkUrl];
        }
    }
}

+ (void)createMeetingAndShow:(uint64_t)chatId userHandle:(uint64_t)userHandle publicChatLink:(NSURL *)publicChatLink {
    
    UIViewController *rootViewController = UIApplication.mnz_keyWindow.rootViewController;
    MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatId];
    if (chatRoom == nil) {
        return;
    } else if (MEGAChatSdk.shared.mnz_existsActiveCall) {
        [MeetingAlreadyExistsAlert showWithPresenter:rootViewController];
        return;
    }
    
    // If the application was deleted when the user is logged and then reinstalled.
    // The sdk says the user is logged in but the session is cleared.
    NSString *sessionV3 = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    BOOL isLoggedIn = MEGASdk.shared.isLoggedIn && sessionV3 != nil && !sessionV3.mnz_isEmpty;
    MeetingConfigurationType type = isLoggedIn ? MeetingConfigurationTypeJoin : MeetingConfigurationTypeGuestJoin;
    
    if (UIApplication.mainTabBarRootViewController) {
        MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
        mainTBC.selectedIndex = TabTypeChat;
        MeetingCreatingViewRouter *router = [[MeetingCreatingViewRouter alloc] initWithViewControllerToPresent:mainTBC
                                                                                                          type:type
                                                                                                          link:publicChatLink.absoluteString
                                                                                                    userhandle:userHandle];
        if (mainTBC.presentedViewController) {
            [mainTBC dismissViewControllerAnimated:NO completion:^{
                [router start];
            }];
        } else {
            [router start];
        }
    } else {
        MeetingCreatingViewRouter *router = [[MeetingCreatingViewRouter alloc] initWithViewControllerToPresent:UIApplication.mnz_visibleViewController
                                                                                                          type:type
                                                                                                          link:publicChatLink.absoluteString
                                                                                                    userhandle:userHandle];
        [router start];
  }
}

+ (void)createChatAndShow:(uint64_t)chatId publicChatLink:(NSURL *)publicChatLink {
    
    if ([UIApplication.mnz_visibleViewController isKindOfClass:ChatViewController.class]) {
        ChatViewController *currentChatViewController = (ChatViewController *)UIApplication.mnz_visibleViewController;
        if (currentChatViewController.chatId == chatId) {
            [SVProgressHUD dismiss];
            return;
        }
    }
    
    MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatId];
    if (chatRoom == nil) {
        return;
    }
    
    if (UIApplication.mainTabBarRootViewController) {
        MainTabBarController *mainTBC = (MainTabBarController *)UIApplication.mainTabBarRootViewController;
        mainTBC.selectedIndex = TabTypeChat;
        
        if (mainTBC.presentedViewController) {
            [mainTBC dismissViewControllerAnimated:YES completion:^{
                [MEGALinkManager pushChat:chatRoom publicChatLink:publicChatLink tabBar:mainTBC];
            }];
        } else {
            [MEGALinkManager pushChat:chatRoom publicChatLink:publicChatLink tabBar:mainTBC];
        }
    } else {
        // there's no UINavigationController present when user is logged out
        // we do a present in that case
        [[ChatContentRouter.alloc initWithChatRoom:chatRoom
                                         presenter:UIApplication.mnz_visibleViewController
                                        publicLink:publicChatLink.absoluteString
                    showShareLinkViewAfterOpenChat:NO
                           chatContentRoutingStyle:ChatContentRoutingStylePresent
         ] start];
    }
}

+ (void)pushChat:(MEGAChatRoom *)chatRoom publicChatLink:(NSURL *)publicChatLink tabBar:(MainTabBarController *)mainTBC {
    UINavigationController *chatNC = mainTBC.selectedViewController;
    
    for (UIViewController *viewController in chatNC.viewControllers) {
        if ([viewController isKindOfClass:ChatViewController.class]) {
            ChatViewController *currentChatViewController = (ChatViewController *)viewController;
            [currentChatViewController closeChatRoom];
        }
    }
    
    [chatNC popToRootViewControllerAnimated:NO];
    [[ChatContentRouter.alloc initWithChatRoom:chatRoom
                                     presenter:chatNC
                                    publicLink:publicChatLink.absoluteString
                showShareLinkViewAfterOpenChat:NO
                       chatContentRoutingStyle:ChatContentRoutingStylePush
     ] start];
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
