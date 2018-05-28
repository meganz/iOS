
#import "NSURL+MNZCategory.h"

#import "FileLinkViewController.h"
#import "FolderLinkViewController.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

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
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#backup"]) {
        return URLTypeBackupLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#fm/ipc"]) {
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
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#fm/chat"]) {
        return URLTypeChatLink;
    }
    
    if (afterSlashesString.length >= 14 && [[afterSlashesString substringToIndex:14] isEqualToString:@"#loginrequired"]) {
        return URLTypeLoginRequiredLink;
    }
    
    if (afterSlashesString.length >= 1 && [afterSlashesString hasPrefix:@"#"]) {
        return URLTypeHandleLink;
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
            
        default:
            break;
    }
}

- (void)showFileLinkView {
    NSString *fileLinkURLString = [self mnz_MEGAURL];
    MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        if (!request.flag) {
            MEGANode *node = request.publicNode;
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                MEGAPhotoBrowserViewController *photoBrowserVC = [node mnz_photoBrowserWithNodes:@[node] folderLink:NO displayMode:DisplayModeFileLink enableMoveToRubbishBin:NO];
                photoBrowserVC.publicLink = fileLinkURLString;
                [UIApplication.mnz_visibleViewController presentViewController:photoBrowserVC animated:YES completion:nil];
                
                return;
            }
        }
        MEGANavigationController *fileLinkNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FileLinkNavigationControllerID"];
        FileLinkViewController *fileLinkVC = fileLinkNavigationController.viewControllers.firstObject;
        fileLinkVC.fileLinkString = fileLinkURLString;
        
        [UIApplication.mnz_visibleViewController presentViewController:fileLinkNavigationController animated:YES completion:nil];
    }];
    
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:fileLinkURLString delegate:delegate];
}

- (void)showFolderLinkView {
    NSString *folderLinkURLString = [self mnz_MEGAURL];
    MEGANavigationController *folderNavigationController = [[UIStoryboard storyboardWithName:@"Links" bundle:nil] instantiateViewControllerWithIdentifier:@"FolderLinkNavigationControllerID"];
    
    FolderLinkViewController *folderlinkVC = folderNavigationController.viewControllers.firstObject;
    
    [folderlinkVC setIsFolderRootNode:YES];
    [folderlinkVC setFolderLinkString:folderLinkURLString];
    
    [UIApplication.mnz_visibleViewController presentViewController:folderNavigationController animated:YES completion:nil];
}

@end
