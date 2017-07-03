
@interface MEGANode (MNZCategory)

@property (nonatomic, readonly, getter=mnz_isImage) BOOL mnz_image;
@property (nonatomic, readonly, getter=mnz_isAudiovisualContent) BOOL mnz_audiovisualContent;

- (void)mnz_openImageInNavigationController:(UINavigationController *)navigationController withNodes:(NSArray *)nodesArray folderLink:(BOOL)isFolderLink displayMode:(NSUInteger)displayMode;
- (void)mnz_openNodeInNavigationController:(UINavigationController *)navigationController folderLink:(BOOL)isFolderLink;

@end
