
#import "MOFolderLayout+CoreDataProperties.h"

@implementation MOFolderLayout (CoreDataProperties)

+ (NSFetchRequest<MOFolderLayout *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MOFolderLayout"];
}

@dynamic handle;
@dynamic value;

@end
