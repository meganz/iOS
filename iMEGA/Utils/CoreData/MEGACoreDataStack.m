#import "MEGACoreDataStack.h"
#import "CoreDataErrorHandler.h"
@import Firebase;
@import SQLite3;

@interface MEGACoreDataStack ()

@property (strong, nonatomic, nullable) NSPersistentContainer *persistentContainer;
@property (strong, nonatomic) NSString *modelName;
@property (strong, nonatomic) NSURL *storeURL;

@end

@implementation MEGACoreDataStack

- (instancetype)initWithModelName:(NSString *)name storeURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _modelName = name;
        _storeURL = URL;
    }
    return self;
}

#pragma mark - persistent container

- (nullable NSPersistentContainer *)persistentContainer {
    if (_persistentContainer == nil) {
        _persistentContainer = [self newPersistentContainerByConfigFileProtection:NO];
    }
    
    return _persistentContainer;
}

/**
 we use this method to create a new persistent container.
 
 Please note: the persistent container will lock main thread internally during initialization due to the setting of NSPersistentStoreCoordinator in NSManagedObjectContext, so please avoid locking main thread when to call this method. Otherwise, a grid lock will be created.
 
 @return a new NSPersistentContainer object
 */
- (nullable NSPersistentContainer *)newPersistentContainerByConfigFileProtection:(BOOL)shouldConfigFileProtection {
    __block NSPersistentContainer *container = [NSPersistentContainer persistentContainerWithName:self.modelName];
    NSPersistentStoreDescription *storeDescription;
    if (self.storeURL) {
        storeDescription = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:self.storeURL];
        [storeDescription setOption:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSPersistentStoreFileProtectionKey];
        
        // CoreData lightweight migration
        [storeDescription setOption:@(YES) forKey:NSMigratePersistentStoresAutomaticallyOption];
        [storeDescription setOption:@(YES) forKey:NSInferMappingModelAutomaticallyOption];
        
        container.persistentStoreDescriptions = @[storeDescription];
        
        if (shouldConfigFileProtection) {
            [self removeProtectionFromURL:self.storeURL];
        }
    }
    
    [container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull storeDescription, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"error when to create core data stack %@", error);
            if (shouldConfigFileProtection) {
                [self addProtectionToURL:self.storeURL];
                [CoreDataErrorHandler exitAppWithError:error];
            } else {
                if ([error.userInfo[NSSQLiteErrorDomain] integerValue] == SQLITE_AUTH) {
                    container = [self newPersistentContainerByConfigFileProtection:YES];
                } else if ([CoreDataErrorHandler isSQLiteFullError:error]) {
                    container = nil;
                    [NSNotificationCenter.defaultCenter postNotificationName:MEGASQLiteDiskFullNotification object:nil];
                } else {
                    [CoreDataErrorHandler exitAppWithError:error];
                }
            }
        }
    }];

    return container;
}

#pragma mark - managed object contexts

- (NSManagedObjectContext *)viewContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    context.mergePolicy = NSOverwriteMergePolicy;
    return context;
}

- (NSManagedObjectContext *)newBackgroundContext {
    NSManagedObjectContext *context = self.persistentContainer.newBackgroundContext;
    context.mergePolicy = NSOverwriteMergePolicy;
    return context;
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext * _Nonnull))block {
    [self.persistentContainer performBackgroundTask:block];
}

#pragma mark - delete store

- (void)deleteStore {
    NSError *error;
    if (![self.persistentContainer.persistentStoreCoordinator destroyPersistentStoreAtURL:self.storeURL withType:NSSQLiteStoreType options:nil error:&error]) {
        MEGALogError(@"[Camera Upload] error when deleting camera upload store %@", error);
    }
    _persistentContainer = nil;
}

#pragma mark - store file protection

- (void)removeProtectionFromURL:(NSURL *)url {
    NSError *error;
    [url setResourceValue:NSURLFileProtectionNone forKey:NSURLFileProtectionKey error:&error];
    if (error) {
        MEGALogError(@"error when to remove file protection %@", error);
        [[FIRCrashlytics crashlytics] recordError:error];
    }
}

- (void)addProtectionToURL:(NSURL *)url {
    NSError *error;
    [url setResourceValue:NSURLFileProtectionCompleteUntilFirstUserAuthentication forKey:NSURLFileProtectionKey error:&error];
    if (error) {
        MEGALogError(@"error when to add file protection %@", error);
        [[FIRCrashlytics crashlytics] recordError:error];
    }
}

@end
