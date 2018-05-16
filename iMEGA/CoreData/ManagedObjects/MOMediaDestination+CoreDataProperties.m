
#import "MOMediaDestination+CoreDataProperties.h"

@implementation MOMediaDestination (CoreDataProperties)

+ (NSFetchRequest<MOMediaDestination *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MediaDestination"];
}

@dynamic fingerprint;
@dynamic destination;
@dynamic timescale;

@end
