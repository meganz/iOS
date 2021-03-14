
#import "UIActivityViewController+MNZCategory.h"

#import <Contacts/CNContactVCardSerialization.h>
#import <Contacts/CNMutableContact.h>

#import "MEGAActivityItemProvider.h"
#import "MEGAChatMessage.h"
#import "MEGAStore.h"

#import "MEGANodeList+MNZCategory.h"

#import "GetLinkActivity.h"
#import "Helper.h"
#import "RemoveLinkActivity.h"
#import "RemoveSharingActivity.h"
#import "OpenInActivity.h"
#import "ShareFolderActivity.h"
#import "SendToChatActivity.h"
#import "UIApplication+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

@import Firebase;

typedef NS_OPTIONS(NSUInteger, NodesAre) {
    NodesAreFiles    = 1 << 0,
    NodesAreFolders  = 1 << 1,
    NodesAreExported = 1 << 2,
    NodesAreOutShares = 1 << 3
};

@implementation UIActivityViewController (MNZCategory)

+ (UIActivityViewController *_Nullable)activityViewControllerForChatMessages:(NSArray<MEGAChatMessage *> *)messages sender:(id _Nullable)sender {
    NSUInteger stringCount = 0, fileCount = 0;

    NSMutableArray *activityItemsMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *excludedActivityTypesMutableArray = [[NSMutableArray alloc] initWithArray:@[UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList]];
    
    NSMutableArray<MEGANode *> *nodes = [[NSMutableArray<MEGANode *> alloc] init];
    NSString *stringContent = @"";
    
    for (MEGAChatMessage *message in messages) {
        switch (message.type) {
            case MEGAChatMessageTypeNormal:
            case MEGAChatMessageTypeContainsMeta:
                if (messages.count == 1) {
                    stringContent = message.content;
                } else {
                    NSString *userName = [MEGASdkManager.sharedMEGAChatSdk userFullnameFromCacheByUserHandle:message.userHandle];
                    NSString *content = [NSString stringWithFormat:@"[%@] #%@:%@\n",[message.timestamp stringWithFormat:@"dd/MM/yyyy HH:mm"], userName,message.content];
                    stringContent = [stringContent stringByAppendingString:content];
                }
                stringCount++;
                
                break;
                
            case MEGAChatMessageTypeContact: {
                for (NSUInteger i = 0; i < message.usersCount; i++) {
                    CNMutableContact *cnMutableContact = [[CNMutableContact alloc] init];
                    
                    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:[message userHandleAtIndex:i]];
                    
                    if (moUser.firstName) {
                        cnMutableContact.givenName = moUser.firstname;
                    }
                    
                    if (moUser.lastname) {
                        cnMutableContact.familyName = moUser.lastname;
                    }
                    
                    if (!moUser.firstName && !moUser.lastname) {
                        cnMutableContact.givenName = [message userNameAtIndex:i];
                    }
                    
                    cnMutableContact.emailAddresses = @[[CNLabeledValue labeledValueWithLabel:CNLabelHome value:[message userEmailAtIndex:i]]];
                    
                    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:[MEGASdk base64HandleForUserHandle:[message userHandleAtIndex:i]]];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
                        UIImage *avatarImage = [UIImage imageWithContentsOfFile:avatarFilePath];
                        cnMutableContact.imageData = UIImageJPEGRepresentation(avatarImage, 1.0f);
                    }
                    NSData *vCardData = [CNContactVCardSerialization dataWithContacts:@[cnMutableContact] error:nil];
                    NSString* vcString = [[NSString alloc] initWithData:vCardData encoding:NSUTF8StringEncoding];
                    NSString* base64Image = [cnMutableContact.imageData base64EncodedStringWithOptions:0];
                    if (base64Image) {
                        NSString* vcardImageString = [[@"PHOTO;TYPE=JPEG;ENCODING=BASE64:" stringByAppendingString:base64Image] stringByAppendingString:@"\n"];
                        vcString = [vcString stringByReplacingOccurrencesOfString:@"END:VCARD" withString:[vcardImageString stringByAppendingString:@"END:VCARD"]];
                    }
                    vCardData = [vcString dataUsingEncoding:NSUTF8StringEncoding];
                    
                    NSString *fullName = [message userNameAtIndex:i];
                    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[fullName stringByAppendingString:@".vcf"]];
                    if ([vCardData writeToFile:tempPath atomically:YES]) {
                        [activityItemsMutableArray addObject:[NSURL fileURLWithPath:tempPath]];
                        fileCount++;
                    }
                }
                
                break;
            }
                
            case MEGAChatMessageTypeAttachment:
            case MEGAChatMessageTypeVoiceClip: {
                MEGANode *node = [message.nodeList mnz_nodesArrayFromNodeList].firstObject;
                MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node];
                if (offlineNodeExist) {
                    NSURL *offlineURL = [NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath]];
                    [activityItemsMutableArray addObject:offlineURL];
                    fileCount++;
                } else {
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    double delayInSeconds = 10.0;
                    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    
                    [Helper importNode:node toShareWithCompletion:^(MEGANode *node) {
                        [nodes addObject:node];
                        MEGAActivityItemProvider *activityItemProvider = [[MEGAActivityItemProvider alloc] initWithPlaceholderString:node.name node:node api:MEGASdkManager.sharedMEGASdk];
                        [activityItemsMutableArray addObject:activityItemProvider];
                        dispatch_semaphore_signal(semaphore);
                    }];
                    if (dispatch_semaphore_wait(semaphore, waitTime)) {
                        MEGALogError(@"Semaphore timeout importing message attachment to share");
                        return nil;
                    }
                }

                break;
            }
                
            default:
                break;
        }
    }
    
    if (stringCount > 0) {
        [activityItemsMutableArray addObject:stringContent];
        if (fileCount == 0) {
            ImportTextActivity *textActivity = [[ImportTextActivity alloc] initWithContent:stringContent];
            [activitiesMutableArray addObject:textActivity];
        }
    }
    
    if (stringCount == 0 && fileCount == 0 && nodes.count > 0) {
        GetLinkActivity *getLinkActivity = [[GetLinkActivity alloc] initWithNodes:nodes];
        [activitiesMutableArray addObject:getLinkActivity];
        
        SendToChatActivity *sendToChatActivity = [[SendToChatActivity alloc] initWithNodes:nodes];
        [activitiesMutableArray addObject:sendToChatActivity];

    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItemsMutableArray applicationActivities:activitiesMutableArray];
    [activityVC setExcludedActivityTypes:excludedActivityTypesMutableArray];
    
    [self configPopoverForActivityViewController:activityVC sender:sender];
    
    return activityVC;
}

+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray sender:(id _Nullable)sender {
    NSMutableArray *activityItemsMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *activitiesMutableArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *excludedActivityTypesMutableArray = [[NSMutableArray alloc] initWithArray:@[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList]];
    
    GetLinkActivity *getLinkActivity = [[GetLinkActivity alloc] initWithNodes:nodesArray];
    [activitiesMutableArray addObject:getLinkActivity];
    
    NodesAre nodesAre = [UIActivityViewController checkPropertiesForSharingNodes:nodesArray];
    
    BOOL allNodesExistInOffline = NO;
    NSMutableArray *filesURLMutableArray;
    if (NodesAreFolders == (nodesAre & NodesAreFolders)) {
        ShareFolderActivity *shareFolderActivity = [[ShareFolderActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:shareFolderActivity];
    } else if (NodesAreFiles == (nodesAre & NodesAreFiles)) {
        filesURLMutableArray = [[NSMutableArray alloc] initWithArray:[UIActivityViewController checkIfAllOfTheseNodesExistInOffline:nodesArray]];
        if ([filesURLMutableArray count]) {
            allNodesExistInOffline = YES;
        }
        
        SendToChatActivity *sendToChatActivity = [[SendToChatActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:sendToChatActivity];
    }
    
    if (allNodesExistInOffline) {
        for (NSURL *fileURL in filesURLMutableArray) {
            [activityItemsMutableArray addObject:fileURL];
        }
        
        [excludedActivityTypesMutableArray removeObjectsInArray:@[UIActivityTypePrint, UIActivityTypeAirDrop]];
        
        if (nodesArray.count < 5) {
            [excludedActivityTypesMutableArray removeObject:UIActivityTypeSaveToCameraRoll];
        }
        
        if (nodesArray.count == 1) {
            OpenInActivity *openInActivity;
            if ([sender isKindOfClass:[UIBarButtonItem class]]) {
                openInActivity = [[OpenInActivity alloc] initOnBarButtonItem:sender];
            } else {
                openInActivity = [[OpenInActivity alloc] initOnView:sender];
            }
            
            [activitiesMutableArray addObject:openInActivity];
        }
    } else {
        for (MEGANode *node in nodesArray) {
            MEGAActivityItemProvider *activityItemProvider = [[MEGAActivityItemProvider alloc] initWithPlaceholderString:node.name node:node api:MEGASdkManager.sharedMEGASdk];
            [activityItemsMutableArray addObject:activityItemProvider];
        }
        
        if (nodesArray.count == 1) {
            [excludedActivityTypesMutableArray removeObject:UIActivityTypeAirDrop];
        }
    }
    
    if (NodesAreExported == (nodesAre & NodesAreExported)) {
        RemoveLinkActivity *removeLinkActivity = [[RemoveLinkActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:removeLinkActivity];
    }
    
    if (NodesAreOutShares == (nodesAre & NodesAreOutShares)) {
        RemoveSharingActivity *removeSharingActivity = [[RemoveSharingActivity alloc] initWithNodes:nodesArray];
        [activitiesMutableArray addObject:removeSharingActivity];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItemsMutableArray applicationActivities:activitiesMutableArray];
    [activityVC setExcludedActivityTypes:excludedActivityTypesMutableArray];
    
    [self configPopoverForActivityViewController:activityVC sender:sender];
    
    return activityVC;
}

+ (void)configPopoverForActivityViewController:(UIActivityViewController *)activityVC sender:(id _Nullable)sender {
    if (activityVC.popoverPresentationController == nil) {
        return;
    }

    if ([sender isKindOfClass:UIBarButtonItem.class]) {
        activityVC.popoverPresentationController.barButtonItem = sender;
    } else if ([sender isKindOfClass:UIView.class]) {
        [self configPopoverForActivityViewController:activityVC senderView:sender];
    } else {
        NSError *error = [NSError errorWithDomain:@"activity.nz.mega" code:0 userInfo:@{@"callStack": [NSThread callStackSymbols]}];
        [[FIRCrashlytics crashlytics] recordError:error];
        
        [self configPopoverForActivityViewController:activityVC senderView:UIApplication.sharedApplication.keyWindow];
    }
}

+ (void)configPopoverForActivityViewController:(UIActivityViewController *)activityVC senderView:(UIView *)view {
    activityVC.popoverPresentationController.sourceView = view;
    activityVC.popoverPresentationController.sourceRect = CGRectMake(0, 0, view.frame.size.width/2, view.frame.size.height/2);
}

+ (NodesAre)checkPropertiesForSharingNodes:(NSArray *)nodesArray {
    NSInteger numberOfFolders = 0;
    NSInteger numberOfFiles = 0;
    NSInteger numberOfNodesExported = 0;
    NSInteger numberOfNodesOutShares = 0;
    for (MEGANode *node in nodesArray) {
        if ([node type] == MEGANodeTypeFolder) {
            numberOfFolders += 1;
        } else if ([node type] == MEGANodeTypeFile) {
            numberOfFiles += 1;
        }
        
        if ([node isExported]) {
            numberOfNodesExported += 1;
        }
        
        if (node.isOutShare) {
            numberOfNodesOutShares += 1;
        }
    }
    
    NodesAre nodesAre = 0;
    if (numberOfFolders  == nodesArray.count) {
        nodesAre = NodesAreFolders;
    } else if (numberOfFiles  == nodesArray.count) {
        nodesAre = NodesAreFiles;
    }
    
    if (numberOfNodesExported == nodesArray.count) {
        nodesAre = nodesAre | NodesAreExported;
    }
    
    if (numberOfNodesOutShares == nodesArray.count) {
        nodesAre = nodesAre | NodesAreOutShares;
    }
    
    return nodesAre;
}

+ (NSArray *)checkIfAllOfTheseNodesExistInOffline:(NSArray *)nodesArray {
    NSMutableArray *filesURLMutableArray = [[NSMutableArray alloc] init];
    for (MEGANode *node in nodesArray) {
        MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node];
        if (offlineNodeExist) {
            [filesURLMutableArray addObject:[NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingPathComponent:[offlineNodeExist localPath]]]];
        } else {
            [filesURLMutableArray removeAllObjects];
            break;
        }
    }
    
    return [filesURLMutableArray copy];
}

@end
