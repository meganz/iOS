#import <Foundation/Foundation.h>

#import "MOOfflineNode.h"
#import "MOUser.h"
#import "MOChatDraft+CoreDataProperties.h"
#import "MOMediaDestination+CoreDataProperties.h"
#import "MOUploadTransfer+CoreDataProperties.h"
#import "MOFolderLayout+CoreDataProperties.h"
#import "MOMessage+CoreDataProperties.h"
#import "MOOfflineFolderLayout+CoreDataProperties.h"
#import "MEGACoreDataStack.h"
#import "MEGASdk.h"

@class TransferRecordDTO;

NS_ASSUME_NONNULL_BEGIN

@interface MEGAStore : NSObject

#pragma mark - store stack

@property (readonly) MEGACoreDataStack *stack;

#pragma mark - Singleton Lifecycle

+ (MEGAStore *)shareInstance;

#pragma mark - MOOfflineNode entity

- (void)insertOfflineNode:(MEGANode *)node api:(MEGASdk *)api path:(NSString *)path;
- (nullable MOOfflineNode *)fetchOfflineNodeWithPath:(NSString *)path;
- (nullable MOOfflineNode *)offlineNodeWithNode:(MEGANode *)node;
- (nullable MOOfflineNode *)offlineNodeWithNode:(MEGANode *)node context:(NSManagedObjectContext *)context;
- (nullable MOOfflineNode *)offlineNodeWithHandle:(NSString *)base64Handle;
- (void)removeOfflineNode:(MOOfflineNode *)offlineNode;
- (void)removeAllOfflineNodes;
- (nullable NSArray<MOOfflineNode *> *)fetchOfflineNodes:(nullable NSNumber *)fetchLimit inRootFolder:(BOOL)inRootFolder;

#pragma mark - MOUser entity

- (void)insertUserWithUserHandle:(uint64_t)userHandle firstname:(nullable NSString *)firstname lastname:(nullable NSString *)lastname nickname:(nullable NSString *)nickname email:(nullable NSString *)email;
- (void)updateUserWithUserHandle:(uint64_t)userHandle firstname:(NSString *)firstname;
- (void)updateUserWithUserHandle:(uint64_t)userHandle lastname:(NSString *)lastname;
- (void)updateUserWithUserHandle:(uint64_t)userHandle email:(NSString *)email;
- (void)updateUserWithUserHandle:(uint64_t)userHandle nickname:(NSString *)nickname;
- (void)updateUserWithEmail:(NSString *)email firstname:(NSString *)firstname;
- (void)updateUserWithEmail:(NSString *)email lastname:(NSString *)lastname;
- (void)updateUserWithEmail:(NSString *)email nickname:(NSString *)nickname;
- (nullable MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle;
- (nullable MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle context:(NSManagedObjectContext *)context;
- (nullable MOUser *)fetchUserWithEmail:(NSString *)email;

#pragma mark - MOChatDraft entity

- (void)insertOrUpdateChatDraftWithChatId:(uint64_t)chatId text:(NSString *)text;
- (nullable MOChatDraft *)fetchChatDraftWithChatId:(uint64_t)chatId;

#pragma mark - MOMediaDestination entity

- (void)insertOrUpdateMediaDestinationWithFingerprint:(NSString *)fingerprint destination:(NSNumber *)destination timescale:(nullable NSNumber *)timescale;
- (void)deleteMediaDestinationWithFingerprint:(NSString *)fingerprint;
- (nullable MOMediaDestination *)fetchMediaDestinationWithFingerprint:(NSString *)fingerprint;

#pragma mark - MOUploadTransfer entity

- (void)insertUploadTransferWithLocalIdentifier:(NSString *)localIdentifier parentNodeHandle:(uint64_t)parentNodeHandle;
- (void)deleteUploadTransfer:(MOUploadTransfer *)uploadTransfer;
- (void)deleteUploadTransferWithLocalIdentifier:(NSString *)localIdentifier;
- (nullable NSArray<TransferRecordDTO *> *)fetchUploadTransfers;
- (void)removeAllUploadTransfers;

#pragma mark - MOMessage entity

- (void)insertMessage:(uint64_t)messageId chatId:(uint64_t)chatId;
- (void)deleteMessage:(MOMessage *)message;
- (void)deleteAllMessagesWithContext:(NSManagedObjectContext *)context;
- (nullable MOMessage *)fetchMessageWithChatId:(uint64_t)chatId messageId:(uint64_t)messageId;
- (BOOL)areTherePendingMessages;

#pragma mark - Context Save

- (void)saveContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
