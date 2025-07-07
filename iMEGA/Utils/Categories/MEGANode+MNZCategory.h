NS_ASSUME_NONNULL_BEGIN

@interface MEGANode (MNZCategory) <UITextFieldDelegate>

- (void)navigateToParentAndPresent;
- (void)mnz_openNodeInNavigationController:(UINavigationController *_Nullable)navigationController folderLink:(BOOL)isFolderLink fileLink:(NSString *_Nullable)fileLink messageId:(nullable NSNumber * )messageId chatId:(nullable NSNumber *)chatId isFromSharedItem:(BOOL)isFromSharedItem allNodes:(NSArray *_Nullable)allNodes;
- (nullable UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink fileLink:(NSString *_Nullable)fileLink isFromSharedItem:(BOOL)isFromSharedItem inViewController:(UIViewController *_Nullable)viewController;
- (nullable UIViewController *)mnz_viewControllerForNodeInFolderLink:(BOOL)isFolderLink fileLink:(NSString *_Nullable)fileLink;

#pragma mark - Actions

- (void)mnz_editTextFileInViewController:(UIViewController *)viewController;
- (void)mnz_labelActionSheetInViewController:(UIViewController *)viewController;
- (void)mnz_renameNodeInViewController:(UIViewController *)viewController;
- (void)mnz_renameNodeInViewController:(UIViewController *)viewController completion:(void(^ _Nullable)(MEGARequest *request))completion;
- (void)mnz_askToMoveToTheRubbishBinInViewController:(UIViewController *)viewController;
- (void)mnz_moveToTheRubbishBinWithCompletion:(void (^)(void))completion;
- (void)mnz_removeInViewController:(UIViewController *)viewController completion:(void (^ _Nullable)(BOOL shouldRemove))actionCompletion;
- (void)mnz_leaveSharingInViewController:(UIViewController *)viewController completion:(void (^ _Nullable)(BOOL))completion;
- (void)mnz_removeSharingWithCompletion:(void (^ _Nullable)(BOOL))completion;
- (void)mnz_restore;
- (void)mnz_sendToChatInViewController:(UIViewController *)viewController;
- (void)mnz_moveInViewController:(UIViewController *)viewController;
- (void)mnz_copyInViewController:(UIViewController *)viewController;
- (void)mnz_showNodeVersionsInViewController:(UIViewController *)viewController;

#pragma mark - File links

- (void)mnz_fileLinkImportFromViewController:(UIViewController *)viewController isFolderLink:(BOOL)isFolderLink;

#pragma mark - Utils

- (nullable MEGANode *)mnz_firstbornInShareOrOutShareParentNode;
- (NSMutableArray *)mnz_parentTreeArray;
- (NSString *)mnz_fileType;
- (BOOL)mnz_isPlayable;
- (BOOL)mnz_isPlaying;
- (BOOL)mnz_isInRubbishBin;
- (NSString *)mnz_voiceCachePath;

#pragma mark - Shares

- (nonnull NSMutableArray <MEGAShare *> *)outShares;

#pragma mark - Versions

- (NSInteger)mnz_numberOfVersions;
- (NSArray<MEGANode *> *)mnz_versions;
- (long long)mnz_versionsSize;

@end

NS_ASSUME_NONNULL_END
