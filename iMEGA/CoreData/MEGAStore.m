#import "MEGAStore.h"

@interface MEGAStore ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)initMEGAStore;

@end

@implementation MEGAStore

static MEGAStore *_megaStore = nil;

#pragma mark - Singleton Lifecycle

+ (MEGAStore *)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _megaStore = [[self alloc] init];
    });
    return _megaStore;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self initMEGAStore];
    }
    
    return self;
}

- (void)initMEGAStore {
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSURL *storeURL = [[self applicationSupportDirectory] URLByAppendingPathComponent:@"MEGACD.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES };
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        MEGALogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if (_persistentStoreCoordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    }
}

- (NSURL *)applicationSupportDirectory {
    return [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        MEGALogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - MOOfflineNode entity

- (void)insertOfflineNode:(MEGANode *)node api:(MEGASdk *)api path:(NSString *)path {
    if (!node.base64Handle || !path) return;
    
    MOOfflineNode *offlineNode = [NSEntityDescription insertNewObjectForEntityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];

    [offlineNode setBase64Handle:node.base64Handle];
    [offlineNode setParentBase64Handle:[[api parentNodeForNode:[api nodeForHandle:node.handle]] base64Handle]];
    [offlineNode setLocalPath:path];
    [offlineNode setFingerprint:[api fingerprintForNode:node]];

    MEGALogDebug(@"Save context: base64 handle: %@ - local path: %@", node.base64Handle, path);
    
    [self saveContext];
}

- (MOOfflineNode *)fetchOfflineNodeWithPath:(NSString *)path {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localPath == %@", path];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];

    return [array firstObject];
}

- (MOOfflineNode *)fetchOfflineNodeWithBase64Handle:(NSString *)base64Handle {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"base64Handle == %@", base64Handle];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return [array firstObject];
}

- (MOOfflineNode *)fetchOfflineNodeWithFingerprint:(NSString *)fingerprint {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fingerprint == %@", fingerprint];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return [array firstObject];
}

- (void)removeOfflineNode:(MOOfflineNode *)offlineNode {
    [self.managedObjectContext deleteObject:offlineNode];
    [self saveContext];
}

- (void)removeAllOfflineNodes {
    NSFetchRequest *allOfflineNodes = [[NSFetchRequest alloc] init];
    [allOfflineNodes setEntity:[NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:self.managedObjectContext]];
    [allOfflineNodes setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *offlineNodes = [self.managedObjectContext executeFetchRequest:allOfflineNodes error:&error];

    for (NSManagedObject *offNode in offlineNodes) {
        [self.managedObjectContext deleteObject:offNode];
    }
    
    [self saveContext];
}

#pragma mark - MOUser entity

- (void)insertUser:(MEGAUser *)user firstname:(NSString *)firstname lastname:(NSString *)lastname {
    NSString *base64userHandle = [MEGASdk base64HandleForUserHandle:user.handle];
    
    if (!base64userHandle) return;
    
    MOUser *moUser          = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    moUser.base64userHandle = base64userHandle;
    moUser.firstname        = firstname;
    moUser.lastname         = lastname;
    
    MEGALogDebug(@"Save context: base64 user handle: %@", base64userHandle);
    
    [self saveContext];
}

- (void)updateUser:(MEGAUser *)user firstname:(NSString *)firstname {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithMEGAUser:user];
    
    if (moUser) {
        moUser.firstname = firstname;
        [self saveContext];
    }
}

- (void)updateUser:(MEGAUser *)user lastname:(NSString *)lastname {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithMEGAUser:user];
    
    if (moUser) {
        moUser.lastname = lastname;
        [self saveContext];
    }

}

- (MOUser *)fetchUserWithMEGAUser:(MEGAUser *)user {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"base64userHandle == %@", [MEGASdk base64HandleForUserHandle:user.handle]];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return [array firstObject];
}

- (void)removeAllUsers {
    NSFetchRequest *allUsers = [[NSFetchRequest alloc] init];
    [allUsers setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext]];
    [allUsers setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *users = [self.managedObjectContext executeFetchRequest:allUsers error:&error];
    
    for (NSManagedObject *user in users) {
        [self.managedObjectContext deleteObject:user];
    }
    
    [self saveContext];
}

@end
