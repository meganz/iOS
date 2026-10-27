#import "MEGAStore.h"
#import "NSString+MNZCategory.h"
#import "CoreDataErrorHandler.h"
@import Firebase;

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#elif MNZ_WIDGET_EXTENSION
#import "MEGAWidgetExtension-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface MEGAStore ()

@property (strong, nonatomic) MEGACoreDataStack *stack;
@property (nonatomic) BOOL shouldAbortAfterReport;
@property (nonatomic, getter=isAbortingAfterReport) BOOL abortingAfterReport;

@end

static NSString * const MEGAStoreGroupSupportErrorDomain = @"mega.ios.groupSupport";
static const NSInteger MEGAStoreGroupSupportCreationFailedErrorCode = 1;

@implementation MEGAStore

#pragma mark - Singleton Lifecycle

+ (MEGAStore *)shareInstance {
    static MEGAStore *_megaStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _megaStore = [[self alloc] init];
    });
    // Aborting here rather than in storeURL: while the main run loop spins so the report gets written, anything calling
    // shareInstance again gets the instance back instead of re-entering dispatch_once, which would crash
    if (_megaStore.shouldAbortAfterReport && !_megaStore.isAbortingAfterReport) {
        _megaStore.abortingAfterReport = YES;
        [_megaStore abortAfterReportIsWritten];
    }
    return _megaStore;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _stack = [[MEGACoreDataStack alloc] initWithModelName:@"MEGACD" storeURL:[self storeURL]];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveLogoutNotification) name:MEGALogoutNotification object:nil];
        
    }
    return self;
}

- (void)didReceiveLogoutNotification {
    [self.stack deleteStore];
}

- (NSManagedObjectContext *)managedObjectContext {
    return self.stack.viewContext;
}

- (NSManagedObjectContext *)newBackgroundObjectContext {
    return self.stack.newBackgroundContext;
}


/// Returns nil when the disk is too full to create the GroupSupport directory: the app then shows the disk full
/// blocking screen and runs without the store, as it does when SQLite is full
- (nullable NSURL *)storeURL {
    NSString *dbName = @"MEGACD.sqlite";
    NSError *error;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *groupSupportURL = [[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionGroupSupportFolder];
    if (![fileManager fileExistsAtPath:groupSupportURL.path]) {
        if (![fileManager createDirectoryAtURL:groupSupportURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Error creating GroupSupport directory in the shared sandbox: %@", error);
            // Crashlytics needs a configured Firebase app, which the Share extension never sets up
            BOOL canReport = [FIRApp defaultApp] != nil;
            if (canReport) {
                [self reportGroupSupportDirectoryCreationError:error groupSupportURL:groupSupportURL];
            }
            if ([CoreDataErrorHandler isFileSystemFullError:error]) {
                // The SQLite store can't be created without GroupSupport, the same as when SQLite itself runs out of space
                [NSNotificationCenter.defaultCenter postNotificationName:MEGASQLiteDiskFullNotification object:nil];
                return nil;
            }
            if (!canReport) {
                abort();
            }
            // storeURL only runs from init, inside the dispatch_once in +shareInstance, so +shareInstance can abort
            // once that's done, after the report is written
            self.shouldAbortAfterReport = YES;
            return nil;
        }
    }
    
    NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *oldStoreURL = [applicationSupportDirectoryURL URLByAppendingPathComponent:dbName];
    NSURL *newStoreURL = [groupSupportURL URLByAppendingPathComponent:dbName];

    if ([fileManager fileExistsAtPath:oldStoreURL.path]) {
        if (![fileManager moveItemAtURL:oldStoreURL toURL:newStoreURL error:&error]) {
            MEGALogError(@"Error moving MEGACD.sqlite to the GroupSupport directory in the shared sandbox: %@", error);
        }
    }
    
    return newStoreURL;
}

- (void)reportGroupSupportDirectoryCreationError:(NSError *)error groupSupportURL:(NSURL *)groupSupportURL {
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    NSNumber *availableCapacity = [[NSURL fileURLWithPath:NSHomeDirectory()] resourceValuesForKeys:@[NSURLVolumeAvailableCapacityKey] error:nil][NSURLVolumeAvailableCapacityKey];
    NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"error_domain"] = error.domain;
    userInfo[@"error_code"] = @(error.code);
    userInfo[@"underlying_error_code"] = @(underlyingError.code);
    userInfo[@"available_capacity"] = availableCapacity ?: @(-1);
    // Tells an app group container that is missing or can't be reached from one where only GroupSupport is missing:
    // listing fails with ENOENT for a missing container and EPERM when the sandbox doesn't let the app in
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *containerListError;
    [fileManager contentsOfDirectoryAtURL:groupSupportURL.URLByDeletingLastPathComponent includingPropertiesForKeys:nil options:0 error:&containerListError];
    userInfo[@"container_list_error"] = [self codeOfError:containerListError];
    NSError *groupSupportError;
    [fileManager attributesOfItemAtPath:groupSupportURL.path error:&groupSupportError];
    userInfo[@"group_support_error"] = [self codeOfError:groupSupportError];
    // Our own domain and a single code put every failure in one Crashlytics issue instead of under whatever system error came up;
    // the original error goes along as the underlying error, with its own domain, code and user info
    NSError *reportedError = [NSError errorWithDomain:MEGAStoreGroupSupportErrorDomain
                                                 code:MEGAStoreGroupSupportCreationFailedErrorCode
                                             userInfo:error != nil ? @{NSUnderlyingErrorKey: error} : nil];
    [[FIRCrashlytics crashlytics] recordError:reportedError userInfo:userInfo];
}

/// recordError: writes the report from the main queue once Crashlytics has started, so the main thread keeps running
/// its run loop for a moment instead of blocking, which would stop the report from ever being written
- (void)abortAfterReportIsWritten __attribute__((noreturn)) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:2];
    if (NSThread.isMainThread) {
        while (deadline.timeIntervalSinceNow > 0) {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:deadline];
        }
    } else {
        [NSThread sleepUntilDate:deadline];
    }
    abort();
}

/// "0" when the call succeeded, otherwise its domain and code with the underlying POSIX one, e.g. "NSCocoaErrorDomain 257 (POSIX 1)"
- (NSString *)codeOfError:(nullable NSError *)error {
    if (error == nil) {
        return @"0";
    }
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    if ([underlyingError.domain isEqualToString:NSPOSIXErrorDomain]) {
        return [NSString stringWithFormat:@"%@ %ld (POSIX %ld)", error.domain, (long)error.code, (long)underlyingError.code];
    }
    return [NSString stringWithFormat:@"%@ %ld", error.domain, (long)error.code];
}

- (void)saveContext:(NSManagedObjectContext *)context {
    [context performBlockAndWait:^{
        NSError *error = nil;
        if (context.hasChanges && ![context save:&error]) {
            MEGALogError(@"Unresolved error %@, %@", error, error.userInfo);
            [self handleSaveContextError:error];
        }
        
        if (context.parentContext != nil) {
            [self saveContext:context.parentContext];
        }
    }];
}

- (void)handleSaveContextError:(NSError *)error {
    if ([CoreDataErrorHandler isSQLiteFullError:error]) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGASQLiteDiskFullNotification object:nil];
    } else {
        [CoreDataErrorHandler exitAppWithError:error];
    }
}

#pragma mark - MOOfflineNode entity

- (void)insertOfflineNode:(MEGANode *)node api:(MEGASdk *)api path:(NSString *)path {
    if (!node.base64Handle || !path) return;
    if (self.managedObjectContext == nil) return;
    
    MOOfflineNode *offlineNode = [NSEntityDescription insertNewObjectForEntityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];

    [offlineNode setBase64Handle:node.base64Handle];
    [offlineNode setParentBase64Handle:[[api parentNodeForNode:[api nodeForHandle:node.handle]] base64Handle]];
    [offlineNode setLocalPath:path];
    [offlineNode setFingerprint:node.fingerprint];
    [offlineNode setDownloadedDate:[NSDate date]];

    MEGALogDebug(@"Save context: insert offline node: %@", offlineNode);
    
    [self saveContext:self.managedObjectContext];
}

- (MOOfflineNode *)fetchOfflineNodeWithPath:(NSString *)path {
    return [[self fetchOfflineNodesWithPath:path] firstObject];
}

- (NSArray<MOOfflineNode *> *)fetchOfflineNodesWithPath:(NSString *)path {
    if (self.managedObjectContext == nil) return @[];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localPath == %@", path];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray<MOOfflineNode *> *array = [self.managedObjectContext executeFetchRequest:request error:&error];

    return array ?: @[];
}


- (MOOfflineNode *)offlineNodeWithNode:(MEGANode *)node {
    if ([NSThread isMainThread]) {
        return [self offlineNodeWithNode:node context:self.managedObjectContext];
    } else {
        return [self offlineNodeWithNode:node context:[self newBackgroundObjectContext]];
    }
}

- (MOOfflineNode *)offlineNodeWithNode:(MEGANode *)node context:(NSManagedObjectContext *)context {
    NSParameterAssert(context != nil);
    if (!context) { return nil; }
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    NSPredicate *predicate;
    NSString *fingerprint = node.fingerprint;
    if(fingerprint) {
        predicate = [NSPredicate predicateWithFormat:@"fingerprint == %@", fingerprint];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"base64Handle == %@", node.base64Handle];
    }
    
    [request setPredicate:predicate];
    
    __block NSArray<MOOfflineNode *> *array;
    
    [context performBlockAndWait:^{
        array = [context executeFetchRequest:request error:nil];
    }];
    
    return [array firstObject];    
}

- (MOOfflineNode *)offlineNodeWithHandle:(NSString *)base64Handle {
    if (self.managedObjectContext == nil) return nil;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    [request setPredicate: [NSPredicate predicateWithFormat:@"base64Handle == %@", base64Handle]];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return [array firstObject];
}

- (void)removeOfflineNode:(MOOfflineNode *)offlineNode {
    [self.managedObjectContext deleteObject:offlineNode];
    MEGALogDebug(@"Save context - remove offline node: %@", offlineNode);
    [self saveContext:self.managedObjectContext];
}

- (void)removeAllOfflineNodes {
    if (self.managedObjectContext == nil) return;
    
    NSFetchRequest *allOfflineNodes = [[NSFetchRequest alloc] init];
    [allOfflineNodes setEntity:[NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext]];
    [allOfflineNodes setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *offlineNodes = [self.managedObjectContext executeFetchRequest:allOfflineNodes error:&error];

    for (NSManagedObject *offNode in offlineNodes) {
        MEGALogDebug(@"Save context - remove offline node: %@", offNode);
        [self.managedObjectContext deleteObject:offNode];
    }
    
    [self saveContext:self.managedObjectContext];
}

- (NSArray<MOOfflineNode *> *)fetchOfflineNodes:(NSNumber* _Nullable)fetchLimit inRootFolder:(BOOL)inRootFolder {
    if (self.managedObjectContext == nil) return @[];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"downloadedDate" ascending:NO]];
    if (fetchLimit != nil) {
        request.fetchLimit = fetchLimit.intValue;
    }
    
    if (inRootFolder) {
        [request setPredicate: [NSPredicate predicateWithFormat:@"NOT (localPath CONTAINS %@)", @"/"]];
    }

    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];

    return array;
}

#pragma mark - MOUser entity

- (void)insertUserWithUserHandle:(uint64_t)userHandle
                       firstname:(NSString *)firstname
                        lastname:(NSString *)lastname
                        nickname:(NSString *)nickname
                           email:(NSString *)email {
    NSString *base64userHandle = [MEGASdk base64HandleForUserHandle:userHandle];
    
    if (!base64userHandle) return;
    if (self.managedObjectContext == nil) return;
    
    MOUser *moUser          = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    moUser.base64userHandle = base64userHandle;
    moUser.firstname        = firstname;
    moUser.lastname         = lastname;
    moUser.email            = email;
    moUser.nickname         = nickname;
    
    MEGALogDebug(@"Save context - insert user: %@", moUser.description);
    
    [self saveContext:self.managedObjectContext];
}

- (void)updateUserWithUserHandle:(uint64_t)userHandle firstname:(NSString *)firstname {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
    
    if (moUser) {
        moUser.firstname = firstname;
        [self saveContext:self.managedObjectContext];
    }
}

- (void)updateUserWithUserHandle:(uint64_t)userHandle lastname:(NSString *)lastname {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
    
    if (moUser) {
        moUser.lastname = lastname;
        [self saveContext:self.managedObjectContext];
    }
}

- (void)updateUserWithUserHandle:(uint64_t)userHandle email:(NSString *)email {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
    
    if (moUser) {
        moUser.email = email;
        [self saveContext:self.managedObjectContext];
    }
}

- (void)updateUserWithUserHandle:(uint64_t)userHandle nickname:(NSString *)nickname {
    NSManagedObjectContext *context = [self.stack newBackgroundContext];
    [context performBlockAndWait:^{
        MOUser *moUser = [self fetchUserWithUserHandle:userHandle context:context];
        if (moUser) {
            moUser.nickname = nickname;
            [self saveContext:context];
        }
    }];
}

- (void)updateUserWithEmail:(NSString *)email firstname:(NSString *)firstname {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithEmail:email];
    
    if (moUser) {
        moUser.firstname = firstname;
        [self saveContext:self.managedObjectContext];
    }
}

- (void)updateUserWithEmail:(NSString *)email lastname:(NSString *)lastname {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithEmail:email];

    if (moUser) {
        moUser.lastname = lastname;
        [self saveContext:self.managedObjectContext];
    }
}

- (void)updateUserWithEmail:(NSString *)email nickname:(NSString *)nickname {
    MOUser *moUser = [MEGAStore.shareInstance fetchUserWithEmail:email];

    if (moUser) {
        moUser.nickname = nickname;
        [self saveContext:self.managedObjectContext];
    }
}

- (MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle {
    return [self fetchUserWithUserHandle:userHandle context:self.managedObjectContext];
}

- (MOUser *)fetchUserWithUserHandle:(uint64_t)userHandle context:(NSManagedObjectContext *)context {
    if (context == nil) return nil;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    
    NSFetchRequest *request = [NSFetchRequest.alloc init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"base64userHandle == %@", [MEGASdk base64HandleForUserHandle:userHandle]];
    [request setPredicate:predicate];
    
    __block NSArray<MOUser *> *array;
    [context performBlockAndWait:^{
        array = [context executeFetchRequest:request error:nil];
    }];
    
    return [array firstObject];
}

- (MOUser *)fetchUserWithEmail:(NSString *)email {
    if (self.managedObjectContext == nil) return nil;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email == %@", email];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return [array firstObject];
}

#pragma mark - MOChatDraft entity

- (void)insertOrUpdateChatDraftWithChatId:(uint64_t)chatId text:(NSString *)text {
    if (self.managedObjectContext == nil) return;
    
    MOChatDraft *moChatDraft = [self fetchChatDraftWithChatId:chatId];
    if (!text.mnz_isEmpty) {
        if (moChatDraft) {
            moChatDraft.text = text;
            
            MEGALogDebug(@"Save context - update chat draft with chatId %@", moChatDraft.chatId);
        } else {
            MOChatDraft *moChatDraft = [NSEntityDescription insertNewObjectForEntityForName:@"ChatDraft" inManagedObjectContext:self.managedObjectContext];
            moChatDraft.chatId = [NSNumber numberWithUnsignedLongLong:chatId];
            moChatDraft.text = text;
            
            MEGALogDebug(@"Save context - insert chat draft with chatId %@", moChatDraft.chatId);
        }
    } else if (moChatDraft) {
        [self.managedObjectContext deleteObject:moChatDraft];
        
        MEGALogDebug(@"Save context - remove chat draft with chatId %@", moChatDraft.chatId);
    }

    [self saveContext:self.managedObjectContext];
}

- (MOChatDraft *)fetchChatDraftWithChatId:(uint64_t)chatId {
    NSFetchRequest *request = [MOChatDraft fetchRequest];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %@", [NSNumber numberWithUnsignedLongLong:chatId]];
    request.predicate = predicate;
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return array.firstObject;
}

#pragma mark - MOMediaDestination entity

- (void)insertOrUpdateMediaDestinationWithFingerprint:(NSString *)fingerprint destination:(NSNumber *)destination timescale:(nullable NSNumber *)timescale {
    if (self.managedObjectContext == nil) return;
    
    MOMediaDestination *moMediaDestination = [self fetchMediaDestinationWithFingerprint:fingerprint];
    
    if (moMediaDestination) {
        moMediaDestination.destination = destination;
        moMediaDestination.timescale = timescale;
        
        MEGALogDebug(@"Save context - update media destination with fingerprint %@ and destination %@", moMediaDestination.fingerprint, moMediaDestination.destination);
    } else {
        MOMediaDestination *moMediaDestination = [NSEntityDescription insertNewObjectForEntityForName:@"MediaDestination" inManagedObjectContext:self.managedObjectContext];
        moMediaDestination.fingerprint = fingerprint;
        moMediaDestination.destination = destination;
        moMediaDestination.timescale = timescale;

        MEGALogDebug(@"Save context - insert media destination with fingerprint %@ and destination %@", moMediaDestination.fingerprint, moMediaDestination.destination);
    }
    
    [self saveContext:self.managedObjectContext];
}

- (void)deleteMediaDestinationWithFingerprint:(NSString *)fingerprint {
    MOMediaDestination *moMediaDestination = [self fetchMediaDestinationWithFingerprint:fingerprint];

    if (moMediaDestination) {
        [self.managedObjectContext deleteObject:moMediaDestination];
        
        MEGALogDebug(@"Save context - remove media destination with fingerprint %@", moMediaDestination.fingerprint);
    }
    
    [self saveContext:self.managedObjectContext];
}

- (nullable MOMediaDestination *)fetchMediaDestinationWithFingerprint:(NSString *)fingerprint {
    NSFetchRequest *request = [MOMediaDestination fetchRequest];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fingerprint == %@", fingerprint];
    request.predicate = predicate;
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return array.firstObject;
}

#pragma mark - MOMessage entity

- (void)insertMessage:(uint64_t)messageId chatId:(uint64_t)chatId {
    NSManagedObjectContext *context = [NSThread isMainThread] ? self.managedObjectContext : self.stack.newBackgroundContext;
    if (context == nil) return;
    
    MOMessage *mMessage = [NSEntityDescription insertNewObjectForEntityForName:@"MOMessage"
                                                        inManagedObjectContext:context];
    mMessage.chatId = [NSNumber numberWithUnsignedLongLong:chatId];
    mMessage.messageId = [NSNumber numberWithUnsignedLongLong:messageId];

    MEGALogDebug(@"Save context - insert MOMessage with chat %@ and message %@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:messageId]);

    [self saveContext:context];
}

- (void)deleteMessage:(MOMessage *)message {
    NSManagedObjectContext *context = [NSThread isMainThread] ? self.managedObjectContext : self.stack.newBackgroundContext;

    [context deleteObject:message];
    
    MEGALogDebug(@"Save context - remove MOMessage with chat %@ and message %@", [MEGASdk base64HandleForUserHandle:message.chatId.unsignedLongLongValue],[MEGASdk base64HandleForUserHandle:message.messageId.unsignedLongLongValue]);
    
    [self saveContext:context];
}

- (void)deleteAllMessagesWithContext:(NSManagedObjectContext *)context {
    NSArray<MOMessage *> *messages = [self fetchMessagesWithContext:context];
    if (messages.count) {
        for (MOMessage *message in messages) {
            [context deleteObject:message];
        }
        
        [self saveContext:context];
    }
}

- (NSArray<MOMessage *> *)fetchMessagesWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [MOMessage fetchRequest];
    
    __block NSArray<MOMessage *> *messages;
    [context performBlockAndWait:^{
        messages = [context executeFetchRequest:request error:nil];
    }];
    
    return messages;
}

- (MOMessage *)fetchMessageWithChatId:(uint64_t)chatId messageId:(uint64_t)messageId {
    NSFetchRequest *request = [MOMessage fetchRequest];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %llu AND messageId == %llu", chatId, messageId];
    request.predicate = predicate;
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return array.firstObject;
    
}

- (BOOL)areTherePendingMessages {
    NSFetchRequest *request = [MOMessage fetchRequest];
    
    NSError *error;
    
    return [self.managedObjectContext executeFetchRequest:request error:&error].count > 0;
}

@end
