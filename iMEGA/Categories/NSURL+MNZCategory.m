
#import "NSURL+MNZCategory.h"

#import "SVProgressHUD.h"

#import "CustomModalAlertViewController.h"
#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "MEGAContactLinkQueryRequestDelegate.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+GKContact.h"

@implementation NSURL (MNZCategory)

- (URLType)mnz_type {
    URLType type = URLTypeDefault;
    
    if ([self.absoluteString rangeOfString:@"file:///"].location != NSNotFound) {
        return URLTypeOpenInLink;
    }
    
    NSString *afterSlashesString = [self mnz_afterSlashesString];
    
    if (afterSlashesString.length < 2) {
        return URLTypeDefault;
    }
    
    if (afterSlashesString.length >= 2 && [[afterSlashesString substringToIndex:2] isEqualToString:@"#!"]) {
        return URLTypeFileLink;
    }
    
    if (afterSlashesString.length >= 3 && [[afterSlashesString substringToIndex:3] isEqualToString:@"#F!"]) {
        return URLTypeFolderLink;
    }
    
    if (afterSlashesString.length >= 3 && [[afterSlashesString substringToIndex:3] isEqualToString:@"#P!"]) {
        return URLTypeEncryptedLink;
    }
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#confirm"]) {
        return URLTypeConfirmationLink;
    }
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"confirm"]) {
        return URLTypeConfirmationLink;
    }
    
    if (afterSlashesString.length >= 10 && [[afterSlashesString substringToIndex:10] isEqualToString:@"#newsignup"]) {
        return URLTypeNewSignUpLink;
    }
    
    if ((afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#backup"]) || (afterSlashesString.length >= 6 && [[afterSlashesString substringToIndex:6] isEqualToString:@"backup"])) {
        return URLTypeBackupLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#fm/ipc"]) {
        return URLTypeIncomingPendingContactsLink;
    }
    
    if (afterSlashesString.length >= 6 && [[afterSlashesString substringToIndex:6] isEqualToString:@"fm/ipc"]) {
        return URLTypeIncomingPendingContactsLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#verify"]) {
        return URLTypeChangeEmailLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#cancel"]) {
        return URLTypeCancelAccountLink;
    }
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#recover"]) {
        return URLTypeRecoverLink;
    }
    
    if (afterSlashesString.length >= 3 && [[afterSlashesString substringToIndex:3] isEqualToString:@"#C!"]) {
        return URLTypeContactLink;
    }
    if (afterSlashesString.length >= 2 && [[afterSlashesString substringToIndex:2] isEqualToString:@"C!"]) {
        return URLTypeContactLink;
    }
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#fm/chat"]) {
        return URLTypeChatLink;
    }
    
    if (afterSlashesString.length >= 14 && [[afterSlashesString substringToIndex:14] isEqualToString:@"#loginrequired"]) {
        return URLTypeLoginRequiredLink;
    }
    
    if (afterSlashesString.length >= 1 && [afterSlashesString hasPrefix:@"#"]) {
        return URLTypeHandleLink;
    }
    
    if (afterSlashesString.length >= 12 && [[afterSlashesString substringToIndex:12] isEqualToString:@"achievements"]) {
        return URLTypeAchievementsLink;
    }
    
    return type;
}

- (NSString *)mnz_MEGAURL {
    NSString *afterSlashesString = [self mnz_afterSlashesString];
    if ([afterSlashesString hasPrefix:@"#"]) {
        return [NSString stringWithFormat:@"https://mega.nz/%@", [self mnz_afterSlashesString]];
    } else {
        return [NSString stringWithFormat:@"https://mega.nz/#%@", [self mnz_afterSlashesString]];
    }
}

- (NSString *)mnz_afterSlashesString {
    NSString *afterSlashesString;
    
    if ([self.scheme isEqualToString:@"mega"]) {
        // mega://<afterSlashesString>
        afterSlashesString = [self.absoluteString substringFromIndex:7];
    } else {
        // http(s)://(www.)mega(.co).nz/<afterSlashesString>
        NSArray<NSString *> *components = [self.absoluteString componentsSeparatedByString:@"/"];
        afterSlashesString = @"";
        if (components.count < 3 || (![components[2] hasSuffix:@"mega.nz"] && ![components[2] isEqualToString:@"mega.co.nz"])) {
            return afterSlashesString;
        }
        for (NSUInteger i = 3; i < components.count; i++) {
            afterSlashesString = [NSString stringWithFormat:@"%@%@/", afterSlashesString, [components objectAtIndex:i]];
        }
        if (afterSlashesString.length > 0) {
            afterSlashesString = [afterSlashesString substringToIndex:(afterSlashesString.length - 1)];
        }
    }
    
    return afterSlashesString;
}

#pragma mark - Link processing

- (void)mnz_showLinkView {
    switch ([self mnz_type]) {
        case URLTypeFileLink:
            [self showFileLinkView];
            break;
            
        case URLTypeFolderLink:
            [self showFolderLinkView];
            break;
            
        case URLTypeContactLink:
            [self handleContactLink];
            break;
            
        default:
            break;
    }
}

- (void)showFileLinkView {
    NSString *fileLinkURLString = [self mnz_MEGAURL];
    MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (error.type) {
            [self presentFileLinkViewForLink:fileLinkURLString request:request error:error];
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
                
                MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[node].mutableCopy api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeFileLink presentingNode:node preferredIndex:0];
                photoBrowserVC.publicLink = fileLinkURLString;
                
                [UIApplication.mnz_presentingViewController presentViewController:photoBrowserVC animated:YES completion:nil];
            } else {
                [self presentFileLinkViewForLink:fileLinkURLString request:request error:error];
            }
        }
        
        [SVProgressHUD dismiss];
    }];
    delegate.savePublicHandle = YES;
    
    [SVProgressHUD show];
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:fileLinkURLString delegate:delegate];
}


- (void)presentFileLinkViewForLink:(NSString *)link request:(MEGARequest *)request error:(MEGAError *)error {
    MEGANavigationController *fileLinkNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkNavigationControllerID"];
    FileLinkViewController *fileLinkVC = fileLinkNavigationController.viewControllers.firstObject;
    fileLinkVC.fileLinkString = link;
    fileLinkVC.request = request;
    fileLinkVC.error = error;
    
    [UIApplication.mnz_presentingViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
}

- (void)showFolderLinkView {
    NSString *folderLinkURLString = [self mnz_MEGAURL];
    MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
    
    FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
    
    [folderlinkVC setIsFolderRootNode:YES];
    [folderlinkVC setFolderLinkString:folderLinkURLString];
    
    [UIApplication.mnz_presentingViewController presentViewController:folderNavigationController animated:YES completion:nil];
}

- (void)handleContactLink {
    NSString *afterSlashesString = [self mnz_afterSlashesString];
    NSRange rangeOfPrefix = [afterSlashesString rangeOfString:@"C!"];
    NSString *contactLinkHandle = [afterSlashesString substringFromIndex:(rangeOfPrefix.location + rangeOfPrefix.length)];
    uint64_t handle = [MEGASdk handleForBase64Handle:contactLinkHandle];
    
    MEGAContactLinkQueryRequestDelegate *delegate = [[MEGAContactLinkQueryRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", request.name, request.text];
        [self presentInviteModalForEmail:request.email fullName:fullName contactLinkHandle:request.nodeHandle image:request.file];
    } onError:^(MEGAError *error) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid")];
    }];
    
    [[MEGASdkManager sharedMEGASdk] contactLinkQueryWithHandle:handle delegate:delegate];
}

- (void)presentInviteModalForEmail:(NSString *)email fullName:(NSString *)fullName contactLinkHandle:(uint64_t)contactLinkHandle image:(NSString *)imageOnBase64URLEncoding {
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
    
    __weak UIViewController *weakVisibleVC = UIApplication.mnz_presentingViewController;
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
    
    [UIApplication.mnz_presentingViewController presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

@end
