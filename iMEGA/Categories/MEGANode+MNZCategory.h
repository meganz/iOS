
#import "MEGAPhotoBrowserViewController.h"

#import "DisplayMode.h"

@interface MEGANode (MNZCategory) <UITextFieldDelegate>

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode;
- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin;
- (MEGAPhotoBrowserViewController *)mnz_photoBrowserWithNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(DisplayMode)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin;
- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink;
- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink;
- (void)mnz_generateThumbnailForVideoAtPath:(NSURL *)path;

#pragma mark - Actions

- (BOOL)mnz_downloadNodeOverwriting:(BOOL)overwrite;
- (void)mnz_renameNodeInViewController:(UIViewController *)viewController;
- (void)mnz_renameNodeInViewController:(UIViewController *)viewController completion:(void(^)(MEGARequest *request))completion;
- (void)mnz_moveToTheRubbishBinInViewController:(UIViewController *)viewController;
- (void)mnz_removeInViewController:(UIViewController *)viewController;
- (void)mnz_leaveSharingInViewController:(UIViewController *)viewController;
- (void)mnz_removeSharing;
- (void)mnz_copyToGalleryFromTemporaryPath:(NSString *)path;

#pragma mark - File links

- (void)mnz_fileLinkDownloadFromViewController:(UIViewController *)viewController isFolderLink:(BOOL)isFolderLink;
- (void)mnz_fileLinkImportFromViewController:(UIViewController *)viewController isFolderLink:(BOOL)isFolderLink;

#pragma mark - Utils

- (NSMutableArray *)mnz_parentTreeArray;
- (NSString *)mnz_fileType;

#pragma mark - Versions

- (NSInteger)mnz_numberOfVersions;
- (NSArray *)mnz_versions;
- (long long)mnz_versionsSize;

@end
