
#import "MEGAStoreStack.h"

@interface MEGAStoreStack ()

@property (strong, nonatomic) NSManagedObjectContext *viewContext;
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

#pragma mark - persistent container for iOS 10 and above

- (NSPersistentContainer *)persistentContainer {
    if (_persistentContainer) {
        return _persistentContainer;
    }
    
    if (NSThread.isMainThread) {
        _persistentContainer = [self newPersistentContainer];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self->_persistentContainer == nil) {
                self->_persistentContainer = [self newPersistentContainer];
            }
        });
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

#pragma mark - store coordinator for iOS 9

- (NSPersistentStoreCoordinator *)storeCoordinator {
    if (_storeCoordinator) {
        return _storeCoordinator;
    }
    
    if (NSThread.isMainThread) {
        _storeCoordinator = [self newStoreCoordinatorForiOSBelow10];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self->_storeCoordinator == nil) {
                self->_storeCoordinator = [self newStoreCoordinatorForiOSBelow10];
            }
        });
    }
    
    return _storeCoordinator;
}

- (NSPersistentStoreCoordinator *)newStoreCoordinatorForiOSBelow10 {
    NSURL *modelURL = [NSBundle.mainBundle URLForResource:self.modelName withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSError *error = nil;
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES};
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:options error:&error]) {
        MEGALogError(@"error when to create core data stack %@", error);
        abort();
    }
    
    return coordinator;
}

#pragma mark - managed object contexts

- (NSManagedObjectContext *)viewContext {
    if (@available(iOS 10.0, *)) {
        return self.persistentContainer.viewContext;
    } else {
        if (_viewContext == nil) {
            _viewContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _viewContext.persistentStoreCoordinator = self.storeCoordinator;
        }
        
        return _viewContext;
    }
}

- (NSManagedObjectContext *)newBackgroundContext {
    if (@available(iOS 10.0, *)) {
        return self.persistentContainer.newBackgroundContext;
    } else {
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [context performBlockAndWait:^{
            context.persistentStoreCoordinator = self.storeCoordinator;
        }];
        return context;
    }
}

#pragma mark - delete store

- (void)deleteStoreWithError:(NSError *__autoreleasing  _Nullable *)error {
    NSPersistentStoreCoordinator *coordinator;
    if (@available(iOS 10.0, *)) {
        coordinator = self.persistentContainer.persistentStoreCoordinator;
    } else {
        coordinator = self.storeCoordinator;
    }
    
    [self.viewContext reset];
    
    [coordinator destroyPersistentStoreAtURL:[self storeURL] withType:NSSQLiteStoreType options:nil error:error];
    if (@available(iOS 10.0, *)) {
        _persistentContainer = nil;
    } else {
        _viewContext = nil;
        _storeCoordinator = nil;
    }
}

@end
