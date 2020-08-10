
#import "MOOfflineFolderLayout+CoreDataProperties.h"

@implementation MOOfflineFolderLayout (CoreDataProperties)

+ (NSFetchRequest<MOOfflineFolderLayout *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MOOfflineFolderLayout"];
}

@dynamic localPath;
@dynamic value;

@end
