#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGAIndexer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MEGAAPIEnv) {
    MEGAAPIEnvProduction,
    MEGAAPIEnvStaging,
    MEGAAPIEnvStaging444,
    MEGAAPIEnvSandbox3
};

@interface Helper : NSObject

#pragma mark - Images

+ (NSDictionary *)fileTypesDictionary;

#pragma mark - Paths

+ (NSString *)pathForOffline;
+ (NSString *)relativePathForOffline;

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory;
/// Return a path in cache shared sandbox including base64 node handle as parent folder (eg xxx/Caches/directory/base64Handle/nodeName)
/// @param node MEGANode used to get the path
/// @param directory directory in the shared sandbox cache
+ (NSString *)pathWithOrignalNameForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory;

+ (NSString *)pathForSharedSandboxCacheDirectory:(NSString *)directory;
+ (NSURL *)urlForSharedSandboxCacheDirectory:(NSString *)directory;

#pragma mark - Utils for transfers

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink;
+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink;
+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink isTopPriority:(BOOL)isTopPriority;
+ (void)downloadNodeTopPriority:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink;

+ (NSMutableArray *)uploadingNodes;
+ (void)startPendingUploadTransferIfNeeded;

#pragma mark - Utils

+ (void)saveSortOrder:(MEGASortOrderType)selectedSortOrderType for:(_Nullable id)object;
+ (MEGASortOrderType)sortTypeFor:(_Nullable id)object;
+ (MEGASortOrderType)defaultSortType;

+ (NSString *)memoryStyleStringFromByteCount:(long long)byteCount;

+ (void)changeApiURL;
+ (void)restoreAPISetting;
+ (void)cannotPlayContentDuringACallAlert;

+ (UIAlertController *)removeUserContactFromSender:(UIView *)sender withConfirmAction:(void (^)(void))confirmAction;

#pragma mark - Utils for nodes

+ (void)thumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell;
+ (void)setThumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell reindexNode:(BOOL)reindex;

+ (NSString *)sizeAndCreationHourAndMininuteForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeAndCreationDateForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeAndModicationDateForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeAndShareLinkCreateDateForSharedLinkNode:(MEGANode *)node api:(MEGASdk *)api;

+ (NSString *)sizeForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)filesAndFoldersInFolderNode:(MEGANode *)node api:(MEGASdk *)api;

+ (void)importNode:(MEGANode *)node toShareWithCompletion:(void (^)(MEGANode *node))completion;

+ (void)setIndexer:(MEGAIndexer* )megaIndexer;

#pragma mark - Utils for UI

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle color:(UIColor *)color;

+ (UISearchController *)customSearchControllerWithSearchResultsUpdaterDelegate:(id<UISearchResultsUpdating>)searchResultsUpdaterDelegate searchBarDelegate:(id<UISearchBarDelegate>)searchBarDelegate;

+ (void)showExportMasterKeyInView:(UIViewController *)viewController completion:(void (^ _Nullable)(void))completion;
+ (void)showMasterKeyCopiedAlert;

#pragma mark - Manage session

+ (BOOL)hasSession_alertIfNot;

+ (void)logout;
+ (void)logoutFromConfirmAccount;
+ (void)clearEphemeralSession;
+ (void)clearSession;
+ (void)deletePasscode;

#pragma mark - Log

+ (void)enableOrDisableLog;

NS_ASSUME_NONNULL_END

@end
