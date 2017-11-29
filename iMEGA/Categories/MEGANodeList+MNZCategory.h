
@interface MEGANodeList (MNZCategory)

- (NSArray *)mnz_numberOfFilesAndFolders;

- (BOOL)mnz_existsFolderWithName:(NSString *)name;

- (NSArray *)mnz_nodesArrayFromNodeList;

@end
