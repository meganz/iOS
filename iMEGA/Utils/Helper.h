#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGAChatMessage.h"
#import "MEGAIndexer.h"

typedef NS_OPTIONS(NSUInteger, NodesAre) {
    NodesAreFiles    = 1 << 0,
    NodesAreFolders  = 1 << 1,
    NodesAreExported = 1 << 2,
    NodesAreOutShares = 1 << 3
};

NS_ASSUME_NONNULL_BEGIN

@interface Helper : NSObject

#pragma mark - Languages

+ (NSArray *)languagesSupportedIDs;
+ (BOOL)isLanguageSupported:(NSString *)languageID;
+ (NSString *)languageID:(NSUInteger)index;

#pragma mark - Images

+ (NSDictionary *)fileTypesDictionary;

#pragma mark - Paths

+ (NSString *)pathForOffline;
+ (NSString *)relativePathForOffline;

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory;

+ (NSString *)pathForSharedSandboxCacheDirectory:(NSString *)directory;
+ (NSURL *)urlForSharedSandboxCacheDirectory:(NSString *)directory;

#pragma mark - Utils for transfers

+ (NSMutableDictionary *)downloadingNodes;

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink;
+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink shouldOverwrite:(BOOL)overwrite;

+ (NSMutableArray *)uploadingNodes;
+ (void)startPendingUploadTransferIfNeeded;

#pragma mark - Utils

+ (NSString *)memoryStyleStringFromByteCount:(long long)byteCount;

+ (void)changeApiURL;

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
+ (UIActivityViewController *)activityViewControllerForChatMessages:(NSArray<MEGAChatMessage *> *)messages sender:(id)sender;
+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray sender:(id _Nullable)sender;

+ (void)setIndexer:(MEGAIndexer* )megaIndexer;

#pragma mark - Utils for empty states

+ (UIEdgeInsets)capInsetsForEmptyStateButton;
+ (UIEdgeInsets)rectInsetsForEmptyStateButton;

+ (CGFloat)verticalOffsetForEmptyStateWithNavigationBarSize:(CGSize)navigationBarSize searchBarActive:(BOOL)isSearchBarActive;
+ (CGFloat)spaceHeightForEmptyState;
+ (CGFloat)spaceHeightForEmptyStateWithDescription;

+ (NSDictionary *)titleAttributesForEmptyState;
+ (NSDictionary *)descriptionAttributesForEmptyState;
+ (NSDictionary *)buttonTextAttributesForEmptyState;

#pragma mark - Utils for UI

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle color:(UIColor *)color;

+ (UISearchController *)customSearchControllerWithSearchResultsUpdaterDelegate:(id<UISearchResultsUpdating>)searchResultsUpdaterDelegate searchBarDelegate:(id<UISearchBarDelegate>)searchBarDelegate;
+ (void)resetSearchControllerFrame:(UISearchController *)searchController;

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
