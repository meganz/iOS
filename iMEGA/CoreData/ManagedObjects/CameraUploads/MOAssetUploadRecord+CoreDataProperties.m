
#import "MOAssetUploadRecord+CoreDataProperties.h"

@implementation MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadRecord"];
}

@dynamic creationDate;
@dynamic localIdentifier;
@dynamic mediaType;
@dynamic status;
@dynamic errorPerLaunch;
@dynamic errorPerLogin;
@dynamic fileNameRecord;
@dynamic additionalMediaSubtype;

@end
