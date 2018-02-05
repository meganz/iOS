
#import "MEGAPhotoBrowserViewController.h"

@interface MEGANode (MNZCategory)

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode;
- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin;
- (MEGAPhotoBrowserViewController *)mnz_photoBrowserWithNodes:(NSArray<MEGANode *> *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode enableMoveToRubbishBin:(BOOL)enableMoveToRubbishBin hideControls:(BOOL)hideControls;
- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink;
- (UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink;
- (void)mnz_generateThumbnailForVideoAtPath:(NSURL *)path;

@end
