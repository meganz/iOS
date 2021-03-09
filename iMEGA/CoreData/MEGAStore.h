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

@interface MEGAStore : NSObject

#pragma mark - store stack

@property (readonly) MEGACoreDataStack *stack;

#pragma mark - Singleton Lifecycle

+ (MEGAStore *)shareInstance;

#pragma mark - MOOfflineNode entity

- (void)insertOfflineNode:(MEGANode *)node api:(MEGASdk *)api path:(NSString *)path;
- (MOOfflineNode *)fetchOfflineNodeWithPath:(NSString *)path;
- (MOOfflineNode *)offlineNodeWithNode:(MEGANode *)node;
- (MOOfflineNode *)offlineNodeWithHandle:(NSString *)base64Handle;
- (void)removeOfflineNode:(nonnull MOOfflineNode *)offlineNode;
- (void)removeAllOfflineNodes;
- (NSArray<MOOfflineNode *> *)fetchOfflineNodes:(NSNumber* _Nullable)fetchLimit inRootFolder:(BOOL)inRootFolder;

#pragma mark - MOUser entity

- (void)insertUserWithUserHandle:(uint64_t)userHandle firstname:(NSString *)firstname lastname:(NSString *)lastname nickname:(NSString *)nickname email:(NSString *)email;
- (void)updateUserWithUserHandle:(uint64_t)userHandle firstname:(NSString *)firstname;
- (void)updateUserWithUserHandle:(uint64_t)userHandle lastname:(NSString *)lastname;
- (void)updateUserWithUserHandle:(uint64_t)userHandle email:(NSString *)email;
// Context is optional, passing nil will use the default main queue context.
- (void)updateUserWithUserHandle:(uint64_t)userHandle nickname:(NSString *)nickname context:(NSManagedObjectContext *)context;
- (void)updateUserWithEmail:(NSString *)email firstname:(NSString *)firstname;
- (void)updateUserWithEmail:(NSString *)email lastname:(NSString *)lastname;
- (void)updateUserWithEmail:(NSString *)email nickname:(NSString *)nickname;
- (MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle;
- (MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle context:(NSManagedObjectContext *)context;
- (MOUser *)fetchUserWithEmail:(NSString *)email;

#pragma mark - MOChatDraft entity

- (void)insertOrUpdateChatDraftWithChatId:(uint64_t)chatId text:(NSString *)text;
- (MOChatDraft *)fetchChatDraftWithChatId:(uint64_t)chatId;

#pragma mark - MOMediaDestination entity

- (void)insertOrUpdateMediaDestinationWithFingerprint:(NSString *)fingerprint destination:(NSNumber *)destination timescale:(NSNumber *)timescale;
- (void)deleteMediaDestinationWithFingerprint:(NSString *)fingerprint;
- (MOMediaDestination *)fetchMediaDestinationWithFingerprint:(NSString *)fingerprint;

#pragma mark - MOUploadTransfer entity

- (void)insertUploadTransferWithLocalIdentifier:(NSString *)localIdentifier parentNodeHandle:(uint64_t)parentNodeHandle;
- (void)deleteUploadTransfer:(MOUploadTransfer *)uploadTransfer;
- (void)deleteUploadTransferWithLocalIdentifier:(NSString *)localIdentifier;
- (NSArray<MOUploadTransfer *> *)fetchUploadTransfers;
- (MOUploadTransfer *)fetchUploadTransferWithLocalIdentifier:(NSString *)localIdentifier;
- (void)removeAllUploadTransfers;

#pragma mark - MOMessage entity

- (void)insertMessage:(uint64_t)messageId chatId:(uint64_t)chatId;
- (void)deleteMessage:(MOMessage *)message;
- (void)deleteAllMessagesWithContext:(NSManagedObjectContext *)context;
- (MOMessage *)fetchMessageWithChatId:(uint64_t)chatId messageId:(uint64_t)messageId;
- (BOOL)areTherePendingMessages;

#pragma mark - Context Save

- (void)saveContext:(NSManagedObjectContext *)context;

@end
