
@interface MEGANodeList (MNZCategory)

- (NSArray *)mnz_numberOfFilesAndFolders;

- (BOOL)mnz_existsFolderWithName:(NSString *)name;
- (BOOL)mnz_existsFileWithName:(NSString *)name;

- (NSArray<MEGANode*> *)mnz_nodesArrayFromNodeList;
- (NSMutableArray *)mnz_mediaNodesMutableArrayFromNodeList;
- (NSMutableArray<MEGANode*> *)mnz_mediaAuthorizeNodesMutableArrayFromNodeListWithSdk:(MEGASdk *)sdk;

#pragma mark - onNodesUpdate filtering

- (BOOL)mnz_shouldProcessOnNodesUpdateInSharedForNodes:(NSArray<MEGANode *> *)nodesArray itemSelected:(NSInteger)itemSelected;

@end
