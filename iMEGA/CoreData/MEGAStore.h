#import <Foundation/Foundation.h>

#import "MOOfflineNode.h"
#import "MEGASdkManager.h"

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

@end
