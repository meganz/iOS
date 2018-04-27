//
//  MOMediaDestination+CoreDataProperties.m
//  
//
//  Created by Carlos Martín Acera on 26/4/18.
//
//

#import "MOMediaDestination+CoreDataProperties.h"

@implementation MOMediaDestination (CoreDataProperties)

+ (NSFetchRequest<MOMediaDestination *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MediaDestination"];
}

@dynamic fingerprint;
@dynamic destination;
@dynamic timescale;

@end
