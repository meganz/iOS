#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGAIndexer.h"
#import "MEGAChatMessage.h"
#import "MEGASdk.h"

#define kIsEraseAllLocalDataEnabled @"IsEraseAllLocalDataEnabled"

#define kLastUploadPhotoDate @"LastUploadPhotoDate"
#define kLastUploadVideoDate @"LastUploadVideoDate"
#define kCameraUploadsNodeHandle @"CameraUploadsNodeHandle"

typedef NS_OPTIONS(NSUInteger, NodesAre) {
    NodesAreFiles    = 1 << 0,
    NodesAreFolders  = 1 << 1,
    NodesAreExported = 1 << 2,
    NodesAreOutShares = 1 << 3
};

@interface Helper : NSObject

#pragma mark - Languages

+ (NSArray *)languagesSupportedIDs;
+ (BOOL)isLanguageSupported:(NSString *)languageID;
+ (NSString *)languageID:(NSUInteger)index;

#pragma mark - Images

+ (NSDictionary *)fileTypesDictionary;

+ (UIImage *)genericImage;
+ (UIImage *)folderImage;
+ (UIImage *)folderCameraUploadsImage;
+ (UIImage *)incomingFolderImage;
+ (UIImage *)outgoingFolderImage;
+ (UIImage *)defaultPhotoImage;

+ (UIImage *)downloadedArrowImage;
+ (UIImage *)downloadingTransferImage;
+ (UIImage *)uploadingTransferImage;
+ (UIImage *)downloadQueuedTransferImage;
+ (UIImage *)uploadQueuedTransferImage;

+ (UIImage *)permissionsButtonImageForShareType:(MEGAShareType)shareType;

#pragma mark - Paths

+ (NSString *)pathForOffline;
+ (NSString *)relativePathForOffline;

+ (NSString *)pathRelativeToOfflineDirectory:(NSString *)totalPath;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path directory:(NSString *)directory;

+ (NSString *)pathForNode:(MEGANode *)node searchPath:(NSSearchPathDirectory)path;

+ (NSString *)pathForNode:(MEGANode *)node inSharedSandboxCacheDirectory:(NSString *)directory;

+ (NSString *)pathForSharedSandboxCacheDirectory:(NSString *)directory;

#pragma mark - Utils for links when you are not logged

+ (MEGANode *)linkNode;
+ (void)setLinkNode:(MEGANode *)node;
+ (NSMutableArray *)nodesFromLinkMutableArray;

+ (NSInteger)selectedOptionOnLink;
+ (void)setSelectedOptionOnLink:(NSInteger)option;

#pragma mark - Utils downloaded and downloading nodes

+ (NSMutableDictionary *)downloadingNodes;

+ (BOOL)isFreeSpaceEnoughToDownloadNode:(MEGANode *)node isFolderLink:(BOOL)isFolderLink;
+ (void)downloadNode:(MEGANode *)node folderPath:(NSString *)folderPath isFolderLink:(BOOL)isFolderLink shouldOverwrite:(BOOL)overwrite;

#pragma mark - Utils

+ (unsigned long long)sizeOfFolderAtPath:(NSString *)path;
+ (uint64_t)freeDiskSpace;

#pragma mark - Utils for nodes

+ (void)thumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell;
+ (void)setThumbnailForNode:(MEGANode *)node api:(MEGASdk *)api cell:(id)cell reindexNode:(BOOL)reindex;

+ (NSString *)sizeAndDateForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)sizeForNode:(MEGANode *)node api:(MEGASdk *)api;
+ (NSString *)dateWithISO8601FormatOfRawTime:(time_t)rawtime;
+ (NSString *)filesAndFoldersInFolderNode:(MEGANode *)node api:(MEGASdk *)api;

+ (UIActivityViewController *)activityViewControllerForChatMessages:(NSArray<MEGAChatMessage *> *)messages sender:(id)sender;
+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray sender:(id)sender;

+ (void)setIndexer:(MEGAIndexer* )megaIndexer;

#pragma mark - Utils for transfers

+ (NSString *)sequentialNameForNodeNamed:(NSString *)name parentNode:(MEGANode *)parentNode;
+ (void)startPendingUploadTransferIfNeeded;

#pragma mark - Utils for empty states

+ (UIEdgeInsets)capInsetsForEmptyStateButton;
+ (UIEdgeInsets)rectInsetsForEmptyStateButton;

+ (CGFloat)verticalOffsetForEmptyStateWithNavigationBarSize:(CGSize)navigationBarSize searchBarActive:(BOOL)isSearchBarActive;
+ (CGFloat)spaceHeightForEmptyState;

+ (NSDictionary *)titleAttributesForEmptyState;
+ (NSDictionary *)buttonTextAttributesForEmptyState;

#pragma mark - Utils for UI

+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
+ (UILabel *)customNavigationBarLabelWithTitle:(NSString *)title subtitle:(NSString *)subtitle color:(UIColor *)color;

+ (UISearchController *)customSearchControllerWithSearchResultsUpdaterDelegate:(id<UISearchResultsUpdating>)searchResultsUpdaterDelegate searchBarDelegate:(id<UISearchBarDelegate>)searchBarDelegate;

+ (void)presentSafariViewControllerWithURL:(NSURL *)url;

+ (void)configureRedNavigationAppearance;
+ (void)configureWhiteNavigationAppearance;
    
+ (void)showExportMasterKeyInView:(UIViewController *)viewController completion:(void (^ __nullable)(void))completion;
+ (void)showMasterKeyCopiedAlert;

#pragma mark - Logout

+ (void)logout;
+ (void)logoutFromConfirmAccount;
+ (void)logoutAfterPasswordReminder;
+ (void)clearSession;
+ (void)deletePasscode;

#pragma mark - Log

+ (void)enableOrDisableLog;

@end
