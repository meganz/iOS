
NS_ASSUME_NONNULL_BEGIN

@interface MEGASdk (MNZCategory)

#pragma mark - properties

@property (nonatomic, setter=mnz_setAccountDetails:) MEGAAccountDetails *mnz_accountDetails;
@property (nonatomic, readonly) BOOL mnz_isProAccount;

#pragma mark - methods

- (void)handleAccountBlockedEvent:(MEGAEvent *)event;

#pragma mark - Chat

/**
 * @brief This method checks if the folder 'My chat files' exists as target folder. If not, it creates it and set it.
 *
 * In the case that this folder already exists and has not been set as the chat target folder, it is localized to the user language. Also if 'My chat files' has been deleted from MEGA, it creates and set the folder again.
 *
 * @param completion MEGANode 'My chat files' target node.
 *
 * @see [MEGASdk getMyChatFilesFolderWithHandle:], [MEGASdk setMyChatFilesFolderWithHandle;], [MEGASdk createFolderWithName:parent:], [MEGASdk renameNode:newName:]
 */
- (void)getMyChatFilesFolderWithCompletion:(void(^)(MEGANode *myChatFilesNode))completion;

@end

NS_ASSUME_NONNULL_END
