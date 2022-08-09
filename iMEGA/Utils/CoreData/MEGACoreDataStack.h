
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEGACoreDataStack : NSObject

/**
 The managed object context associated with the main queue.
 
 @warning don't hold a reference to the returned context object, unless you can manage the lifecycle of the context object by youself. Otherwise your reference would become invalid upon logout, which would lead to crash.
 */
@property (readonly, nullable) NSManagedObjectContext *viewContext;

- (instancetype)initWithModelName:(NSString *)name storeURL:(nullable NSURL *)URL;

/**
 Creates a private managed object context with the `concurrencyType` set to `NSPrivateQueueConcurrencyType`
 
 @warning don't hold a reference to the returned context object, unless you can manage the lifecycle of the context object by youself. Otherwise your reference would become invalid upon logout, which would lead to crash.
 */
- (nullable NSManagedObjectContext *)newBackgroundContext;

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext *))block;

- (void)deleteStore;

@end

NS_ASSUME_NONNULL_END
