
#import "MOAssetUploadErrorPerLaunch+CoreDataProperties.h"

@implementation MOAssetUploadErrorPerLaunch (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadErrorPerLaunch *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadErrorPerLaunch"];
}

@dynamic uploadRecord;

@end
