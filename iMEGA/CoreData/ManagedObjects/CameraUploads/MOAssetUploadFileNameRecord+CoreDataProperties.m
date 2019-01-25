
#import "MOAssetUploadFileNameRecord+CoreDataProperties.h"

@implementation MOAssetUploadFileNameRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadFileNameRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadFileNameRecord"];
}

@dynamic localIdentifier;
@dynamic localUniqueFileName;

@end
