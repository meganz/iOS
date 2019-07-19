
#import "MOAssetUploadErrorRecord+CoreDataProperties.h"

@implementation MOAssetUploadErrorRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadErrorRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadErrorRecord"];
}

@dynamic localIdentifier;
@dynamic errorCount;

@end
