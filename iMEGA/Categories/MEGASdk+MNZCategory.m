
#import "MEGASdk+MNZCategory.h"
#import <objc/runtime.h>

#import "MEGACreateFolderRequestDelegate.h"
#import "MEGAGenericRequestDelegate.h"

static const void *mnz_accountDetailsKey = &mnz_accountDetailsKey;
static const void *mnz_completedTransfersKey = &mnz_completedTransfersKey;

@implementation MEGASdk (MNZCategory)

#pragma mark - properties

- (MEGAAccountDetails *)mnz_accountDetails {
    return objc_getAssociatedObject(self, mnz_accountDetailsKey);
}

- (void)mnz_setAccountDetails:(MEGAAccountDetails *)newAccountDetails {
    objc_setAssociatedObject(self, &mnz_accountDetailsKey, newAccountDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)completedTransfers {
    NSMutableArray *completedTransfers = objc_getAssociatedObject(self, mnz_completedTransfersKey);
    if (!completedTransfers) {
        completedTransfers = NSMutableArray.new;
        objc_setAssociatedObject(self, &mnz_completedTransfersKey, completedTransfers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return completedTransfers;
}

- (BOOL)mnz_isProAccount {
    return [self.mnz_accountDetails type] > MEGAAccountTypeFree;
}

- (BOOL)mnz_isGuestAccount {
    return [objc_getAssociatedObject(self, @selector(mnz_isGuestAccount:)) boolValue];
}

- (void)mnz_isGuestAccount:(BOOL)isGuestAccount {
    objc_setAssociatedObject(self, @selector(mnz_isGuestAccount:), @(isGuestAccount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mnz_shouldRequestAccountDetails {
    return [objc_getAssociatedObject(self, @selector(mnz_setShouldRequestAccountDetails:)) boolValue];
}

- (void)mnz_setShouldRequestAccountDetails:(BOOL)mnz_shouldRequestAccountDetails {
    objc_setAssociatedObject(self, @selector(mnz_setShouldRequestAccountDetails:), @(mnz_shouldRequestAccountDetails), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Chat

- (void)getMyChatFilesFolderWithCompletion:(void(^)(MEGANode *myChatFilesNode))completion {
    MEGAGenericRequestDelegate *delegate = [MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (error.type) {
            MEGANode *myChatFilesNode = [self nodeForPath:@"/My chat files"];
            if (myChatFilesNode) {
                [self setMyChatFilesFolderWithHandle:myChatFilesNode.handle];
                NSString *myChatFilesLocalizedString = NSLocalizedString(@"My chat files", @"Destination folder name of chat files");
                if (![myChatFilesLocalizedString isEqualToString:@"My chat files"]) {
                    [self renameNode:myChatFilesNode newName:myChatFilesLocalizedString];
                }
                
                if (completion) {
                    completion(myChatFilesNode);
                }
            } else {
                [self localizedFolderName:NSLocalizedString(@"My chat files", @"Destination folder name of chat files") completion:^(MEGANode *newNodeInRootPath) {
                    [self setMyChatFilesFolderWithHandle:newNodeInRootPath.handle];
                    if (completion) {
                        completion(newNodeInRootPath);
                    };
                }];
            }
        } else {
            MEGANode *myChatFilesNode = [self nodeForHandle:request.nodeHandle];
            if (myChatFilesNode) {
                if (completion) {
                    completion(myChatFilesNode);
                }
            } else {
                [self localizedFolderName:NSLocalizedString(@"My chat files", @"Destination folder name of chat files") completion:^(MEGANode *newNodeInRootPath) {
                    [self setMyChatFilesFolderWithHandle:newNodeInRootPath.handle];
                    if (completion) {
                        completion(newNodeInRootPath);
                    };
                }];
            }
        }
    }];
    
    [self getMyChatFilesFolderWithDelegate:delegate];
}

#pragma mark - Private

- (void)localizedFolderName:(NSString *)folderName completion:(void(^)(MEGANode *newNodeInRootPath))completion {
    MEGANode *nodeInRootPath = [self nodeForPath:[NSString stringWithFormat:@"/%@", folderName]];
    if (nodeInRootPath) {
        if (completion) {
            completion(nodeInRootPath);
        }
    } else {
        MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [MEGACreateFolderRequestDelegate.alloc initWithCompletion:^(MEGARequest *request) {
            MEGANode *newNodeInRootPath = [self nodeForHandle:request.nodeHandle];
            if (completion) {
                completion(newNodeInRootPath);
            }
        }];
        [self createFolderWithName:folderName parent:self.rootNode delegate:createFolderRequestDelegate];
    }
}

@end
