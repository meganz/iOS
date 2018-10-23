
#import "MOAssetUploadRecord+CoreDataProperties.h"

@implementation MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadRecord"];
}

@dynamic localIdentifier;
@dynamic status;
@dynamic modificationDate;

@end
