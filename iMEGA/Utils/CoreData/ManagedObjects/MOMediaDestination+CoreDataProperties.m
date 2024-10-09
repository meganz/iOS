#import "MOMediaDestination+CoreDataProperties.h"

@implementation MOMediaDestination (CoreDataProperties)

+ (NSFetchRequest<MOMediaDestination *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MediaDestination"];
}

@dynamic destination;
@dynamic fingerprint;
@dynamic timescale;
@dynamic recentlyWatchedVideo;

@end
