
#import "MOMediaDestination+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOMediaDestination (CoreDataProperties)

+ (NSFetchRequest<MOMediaDestination *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *fingerprint;
@property (nullable, nonatomic, copy) NSNumber *destination;
@property (nullable, nonatomic, copy) NSNumber *timescale;

@end

NS_ASSUME_NONNULL_END
