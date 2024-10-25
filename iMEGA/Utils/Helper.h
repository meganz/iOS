#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MEGAAPIEnv) {
    MEGAAPIEnvProduction,
    MEGAAPIEnvStaging,
    MEGAAPIEnvBt1444,
    MEGAAPIEnvSandbox3
};

@interface Helper : NSObject

#pragma mark - Paths

+ (NSString *)pathForOffline;

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory;
/// Return a path in cache shared sandbox including base64 node handle as parent folder (eg xxx/Caches/directory/base64Handle/nodeName)
/// @param node MEGANode used to get the path
/// @param directory directory in the shared sandbox cache
+ (NSString *)pathWithOriginalNameForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory;

+ (NSString *)pathForSharedSandboxCacheDirectory:(NSString *)directory;
+ (NSURL *)urlForSharedSandboxCacheDirectory:(NSString *)directory;

#pragma mark - Utils for transfers

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink;
+ (NSMutableArray *)uploadingNodes;
+ (void)startPendingUploadTransferIfNeeded;

#pragma mark - Utils
/// DEPRECATED: Migrate to the usage of SortOrderPreferenceUseCase to determine the desired sort order model.
+ (void)saveSortOrder:(MEGASortOrderType)selectedSortOrderType for:(_Nullable id)object;
/// DEPRECATED: Migrate to the usage of SortOrderPreferenceUseCase to save the desired sort order model.
+ (MEGASortOrderType)sortTypeFor:(_Nullable id)object;

+ (void)changeApiURL;
+ (void)restoreAPISetting;
+ (void)cannotPlayContentDuringACallAlert;

+ (UIAlertController *)removeUserContactFromSender:(UIView *)sender withConfirmAction:(void (^)(void))confirmAction;

#pragma mark - Utils for nodes

+ (void)thumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell;
+ (void)setThumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell;

+ (NSString *)sizeAndCreationHourAndMininuteForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeAndCreationDateForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeAndModificationDateForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeAndShareLinkCreateDateForSharedLinkNode:(MEGANode *)node api:(MEGASdk *)api;

+ (NSString *)sizeForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)filesAndFoldersInFolderNode:(MEGANode *)node api:(MEGASdk *)api;

+ (void)importNode:(MEGANode *)node toShareWithCompletion:(void (^)(MEGANode *node))completion;

#pragma mark - Utils for UI

+ (void)showExportMasterKeyInView:(UIViewController *)viewController completion:(void (^ _Nullable)(void))completion;
+ (void)showMasterKeyCopiedAlert:(void (^ _Nullable)(void))completion;

#pragma mark - Manage session

+ (BOOL)hasSession_alertIfNot;

+ (void)logout;
+ (void)clearEphemeralSession;
+ (void)deletePasscode;

#pragma mark - Log

+ (void)enableOrDisableLog;

NS_ASSUME_NONNULL_END

@end
