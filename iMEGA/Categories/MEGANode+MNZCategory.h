
@interface MEGANode (MNZCategory)

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode;
- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink;

@end
