
#import "MEGAStoreStack.h"

@interface MEGAStoreStack ()

@property (strong, nonatomic) NSPersistentStoreCoordinator *storeCoordinator;
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
        _persistentContainer = [self newPersistentContainer];
    }
    
    return _persistentContainer;
}

/**
 we use this method to create a new persistent container.
 
 Please note: the persistent container will lock main thread internally during initialization due to the setting of NSPersistentStoreCoordinator in NSManagedObjectContext, so please avoid locking main thread when to call this method. Otherwise, a grid lock will be created.
 
 @return a new NSPersistentContainer object
 */
- (NSPersistentContainer *)newPersistentContainer {
    NSPersistentContainer *container = [NSPersistentContainer persistentContainerWithName:self.modelName];
    if (self.storeURL) {
        NSPersistentStoreDescription *storeDescription = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:self.storeURL];
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

- (void)deleteStoreWithError:(NSError *__autoreleasing  _Nullable *)error {
    [_persistentContainer.persistentStoreCoordinator destroyPersistentStoreAtURL:[self storeURL] withType:NSSQLiteStoreType options:nil error:error];
    _persistentContainer = nil;
}

@end
