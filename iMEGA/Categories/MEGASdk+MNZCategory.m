
#import "MEGASdk+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "MEGANavigationController.h"
#import "MEGA-Swift.h"
#import <objc/runtime.h>

#import "MEGACreateFolderRequestDelegate.h"
#import "MEGAGenericRequestDelegate.h"

static const void *mnz_accountDetailsKey = &mnz_accountDetailsKey;

@implementation MEGASdk (MNZCategory)

#pragma mark - properties

- (MEGAAccountDetails *)mnz_accountDetails {
    return objc_getAssociatedObject(self, mnz_accountDetailsKey);
}

- (void)mnz_setAccountDetails:(MEGAAccountDetails *)newAccountDetails {
    objc_setAssociatedObject(self, &mnz_accountDetailsKey, newAccountDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mnz_isProAccount {
    return [self.mnz_accountDetails type] > MEGAAccountTypeFree;
}

#pragma mark - methods

- (void)handleAccountBlockedEvent:(MEGAEvent *)event {
    AccountSuspensionType suspensionType = (AccountSuspensionType)event.number;
    SMSState state = [self smsAllowedState];
    if (suspensionType == AccountSuspensionTypeSMSVerification && state != SMSStateNotAllowed) {
        if ([UIApplication.mnz_presentingViewController isKindOfClass:[SMSNavigationViewController class]]) {
            return;
        }
        
        UIViewController *verificationController = [[UIStoryboard storyboardWithName:@"SMSVerification" bundle:nil] instantiateInitialViewController];
        UINavigationController *navigationController = [[SMSNavigationViewController alloc] initWithRootViewController:verificationController];
        
        [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:AMLocalizedString(@"accountBlocked", @"Error message when trying to login and the account is blocked") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self logout];
        }]];
        
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - Chat

- (void)getMyChatFilesFolderWithCompletion:(void(^)(MEGANode *myChatFilesNode))completion {
    MEGAGenericRequestDelegate *delegate = [MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (error.type) {
            MEGANode *myChatFilesNode = [self nodeForPath:@"/My chat files"];
            if (myChatFilesNode) {
                [self setMyChatFilesFolderWithHandle:myChatFilesNode.handle];
                NSString *myChatFilesLocalizedString = AMLocalizedString(@"My chat files", @"Destination folder name of chat files");
                if (![myChatFilesLocalizedString isEqualToString:@"My chat files"]) {
                    [self renameNode:myChatFilesNode newName:myChatFilesLocalizedString];
                }
                
                if (completion) {
                    completion(myChatFilesNode);
                }
            } else {
                [self localizedFolderName:AMLocalizedString(@"My chat files", @"Destination folder name of chat files") completion:^(MEGANode *newNodeInRootPath) {
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
                [self localizedFolderName:AMLocalizedString(@"My chat files", @"Destination folder name of chat files") completion:^(MEGANode *newNodeInRootPath) {
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
