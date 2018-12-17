
#import "MOUploadTransfer+CoreDataProperties.h"

@implementation MOUploadTransfer (CoreDataProperties)

+ (NSFetchRequest<MOUploadTransfer *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MOUploadTransfer"];
}

@dynamic localIdentifier;
@dynamic parentNodeHandle;

@end
