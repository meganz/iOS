#import "MEGAStoreStack.h"
@import Firebase;
@import SQLite3;

@interface MEGAStoreStack ()

@property (strong, nonatomic) NSPersistentContainer *persistentContainer;
@property (strong, nonatomic) NSString *modelName;
@property (strong, nonatomic) NSURL *storeURL;

@end

@implementation MEGAStoreStack

- (instancetype)initWithModelName:(NSString *)name storeURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _modelName = name;
        _storeURL = URL;
    }
    return self;
}

#pragma mark - persistent container

- (NSPersistentContainer *)persistentContainer {
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
- (NSPersistentContainer *)newPersistentContainerByConfigFileProtection:(BOOL)shouldConfigFileProtection {
    __block NSPersistentContainer *container = [NSPersistentContainer persistentContainerWithName:self.modelName];
    NSPersistentStoreDescription *storeDescription;
    if (self.storeURL) {
        storeDescription = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:self.storeURL];
        [storeDescription setOption:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSPersistentStoreFileProtectionKey];
        container.persistentStoreDescriptions = @[storeDescription];
        
        if (shouldConfigFileProtection) {
            [self removeProtectionFromURL:self.storeURL];
        }
    }
    
    [container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull storeDescription, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"error when to create core data stack %@", error);
            [[FIRCrashlytics crashlytics] recordError:error];
            
            if (shouldConfigFileProtection) {
                [self addProtectionToURL:self.storeURL];
                abort();
            } else {
                if ([error.userInfo[NSSQLiteErrorDomain] integerValue] == SQLITE_AUTH) {
                    container = [self newPersistentContainerByConfigFileProtection:YES];
                } else {
                    abort();
                }
            }
        }
    }];

    return container;
}

#pragma mark - managed object contexts

- (NSManagedObjectContext *)viewContext {
    return self.persistentContainer.viewContext;
}

- (NSManagedObjectContext *)newBackgroundContext {
    return self.persistentContainer.newBackgroundContext;
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
