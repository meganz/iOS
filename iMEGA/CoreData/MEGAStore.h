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
- (MOOfflineNode *)offlineNodeWithNode:(MEGANode *)node api:(MEGASdk *)api;
- (void)removeOfflineNode:(MOOfflineNode *)offlineNode;
- (void)removeAllOfflineNodes;

#pragma mark - MOUser entity

- (void)insertUserWithUserHandle:(uint64_t)userHandle firstname:(NSString *)firstname lastname:(NSString *)lastname email:(NSString *)email;
- (void)updateUserWithUserHandle:(uint64_t)userHandle firstname:(NSString *)firstname;
- (void)updateUserWithUserHandle:(uint64_t)userHandle lastname:(NSString *)lastname;
- (void)updateUserWithUserHandle:(uint64_t)userHandle email:(NSString *)email;
- (MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle;
- (void)removeAllUsers;

@end
