
#import "MOAssetUploadRecord+CoreDataProperties.h"

@implementation MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadRecord"];
}

@dynamic creationDate;
@dynamic localIdentifier;
@dynamic mediaType;
@dynamic mediaSubtypes;
@dynamic additionalMediaSubtypes;
@dynamic status;
@dynamic errorPerLaunch;
@dynamic errorPerLogin;
@dynamic fileNameRecord;

@end
