
@interface MEGANodeList (MNZCategory)

- (NSArray *)mnz_numberOfFilesAndFolders;

- (BOOL)mnz_existsFolderWithName:(NSString *)name;
- (BOOL)mnz_existsFileWithName:(NSString *)name;

- (NSArray *)mnz_nodesArrayFromNodeList;
- (NSMutableArray *)mnz_mediaNodesMutableArrayFromNodeList;

- (BOOL)mnz_containsNodeWithParentFolderName:(NSString *)name;
- (BOOL)mnz_containsNodeWithRestoreFolderName:(NSString *)name;

@end
