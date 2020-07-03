
#import "MEGAStoreStack.h"

@interface MEGAStoreStack ()

@property (strong, nonatomic) NSPersistentContainer *persistentContainer;
@property (strong, nonatomic) NSURL *storeURL;

@end

@implementation MEGAStoreStack

- (instancetype)initWithModelName:(NSString *)name storeURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _storeURL = URL;
        _persistentContainer = [self createPersistentContainerByModelName:name storeURL:URL];
    }
    return self;
}

#pragma mark - persistent container

/**
 we use this method to create a new persistent container.
 
 Please note: the persistent container will lock main thread internally during initialization due to the setting of NSPersistentStoreCoordinator in NSManagedObjectContext, so please avoid locking main thread when to call this method. Otherwise, a grid lock will be created.
 
 @return a new NSPersistentContainer object
 */
- (NSPersistentContainer *)createPersistentContainerByModelName:(NSString *)modelName storeURL:(nullable NSURL *)storeURL {
    NSPersistentContainer *container = [NSPersistentContainer persistentContainerWithName:modelName];
    if (storeURL) {
        NSPersistentStoreDescription *storeDescription = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:storeURL];
        container.persistentStoreDescriptions = @[storeDescription];
    }
    
    [container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull storeDescription, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"error when to create core data stack %@", error);
            abort();
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

@end
