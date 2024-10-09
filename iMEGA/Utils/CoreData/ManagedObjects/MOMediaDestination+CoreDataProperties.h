#import "MOMediaDestination+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOMediaDestination (CoreDataProperties)

+ (NSFetchRequest<MOMediaDestination *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSNumber *destination;
@property (nullable, nonatomic, copy) NSString *fingerprint;
@property (nullable, nonatomic, copy) NSNumber *timescale;
@property (nullable, nonatomic, retain) MORecentlyWatchedVideo *recentlyWatchedVideo;

@end

NS_ASSUME_NONNULL_END
