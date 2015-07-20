/**
 * @file MEGAStore.m
 * @brief MEGAStore manages the data model
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "MEGAStore.h"

@interface MEGAStore ()

- (void)initMEGAStore;

@end

@implementation MEGAStore {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

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
    //Init all core data model
    [self managedObjectContext];
}

#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MEGACD" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationLibraryDirectory] URLByAppendingPathComponent:@"MEGACD.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return persistentStoreCoordinator;
}

- (NSURL *)applicationLibraryDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *moc = managedObjectContext;
    if (moc != nil) {
        if ([moc hasChanges] && ![moc save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - MOOfflineNode entity

- (MOOfflineNode *)insertOfflineNode {
    MOOfflineNode *offlineNode;
    
    offlineNode = [NSEntityDescription insertNewObjectForEntityForName:@"OfflineNode" inManagedObjectContext:managedObjectContext];
    return offlineNode;
}

- (MOOfflineNode *)fetchOfflineNodeWithPath:(NSString *)path {
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"OfflineNode" inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"localPath == %@", path];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];

    return [array firstObject];
}

- (MOOfflineNode *)fetchOfflineNodeWithBase64Handle:(NSString *)base64Handle {
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"OfflineNode" inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"base64Handle == %@", base64Handle];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
    
    return [array firstObject];
}

- (void)removeOfflineNode:(MOOfflineNode *)offlineNode {
    [managedObjectContext deleteObject:offlineNode];
    [self saveContext];
}

- (void)removeAllOfflineNodes {
    NSFetchRequest *allOfflineNodes = [[NSFetchRequest alloc] init];
    [allOfflineNodes setEntity:[NSEntityDescription entityForName:@"OfflineNode" inManagedObjectContext:managedObjectContext]];
    [allOfflineNodes setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *offlineNodes = [managedObjectContext executeFetchRequest:allOfflineNodes error:&error];

    for (NSManagedObject *offNode in offlineNodes) {
        [managedObjectContext deleteObject:offNode];
    }
    NSError *saveError = nil;
    [managedObjectContext save:&saveError];
}

@end
