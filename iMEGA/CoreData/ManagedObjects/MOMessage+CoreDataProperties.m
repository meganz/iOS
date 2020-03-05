
#import "MOMessage+CoreDataProperties.h"

@implementation MOMessage (CoreDataProperties)

+ (NSFetchRequest<MOMessage *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MOMessage"];
}

@dynamic chatId;
@dynamic messageId;

@end
