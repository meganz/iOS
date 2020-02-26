
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEGAStoreStack : NSObject

@property (readonly) NSManagedObjectContext *viewContext;

- (instancetype)initWithModelName:(NSString *)name storeURL:(nullable NSURL *)URL;

- (NSManagedObjectContext *)newBackgroundContext;

- (BOOL)deleteStoreWithError:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
