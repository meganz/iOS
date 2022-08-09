
#import "MOAssetUploadErrorPerLogin+CoreDataProperties.h"

@implementation MOAssetUploadErrorPerLogin (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadErrorPerLogin *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadErrorPerLogin"];
}

@dynamic uploadRecord;

@end
