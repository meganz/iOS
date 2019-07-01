
#import "MOAssetUploadFileNameRecord+CoreDataProperties.h"

@implementation MOAssetUploadFileNameRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadFileNameRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadFileNameRecord"];
}

@dynamic localUniqueFileName;
@dynamic fileExtension;
@dynamic uploadRecord;

@end
