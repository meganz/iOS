#import <Foundation/Foundation.h>

#import "MEGASdkManager.h"
#import "MOOfflineNode.h"
#import "MOUser.h"

@interface MEGAStore : NSObject

#pragma mark - Singleton Lifecycle

+ (MEGAStore *)shareInstance;

#pragma mark - MOOfflineNode entity

- (void)insertOfflineNode:(MEGANode *)node api:(MEGASdk *)api path:(NSString *)path;
- (MOOfflineNode *)fetchOfflineNodeWithPath:(NSString *)path;
- (MOOfflineNode *)fetchOfflineNodeWithBase64Handle:(NSString *)base64Handle;
- (MOOfflineNode *)fetchOfflineNodeWithFingerprint:(NSString *)fingerprint;
- (void)removeOfflineNode:(MOOfflineNode *)offlineNode;
- (void)removeAllOfflineNodes;

#pragma mark - MOUser entity

- (void)insertUser:(MEGAUser *)user firstname:(NSString *)firstname lastname:(NSString *)lastname;
- (void)updateUser:(MEGAUser *)user firstname:(NSString *)firstname;
- (void)updateUser:(MEGAUser *)user lastname:(NSString *)lastname;
- (MOUser *)fetchUserWithMEGAUser:(MEGAUser *)user;
- (void)removeAllUsers;

@end
