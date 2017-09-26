#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface MOUser : NSManagedObject

@property (nonatomic, copy, readonly) NSString *fullName;

@end

NS_ASSUME_NONNULL_END

#import "MOUser+CoreDataProperties.h"
