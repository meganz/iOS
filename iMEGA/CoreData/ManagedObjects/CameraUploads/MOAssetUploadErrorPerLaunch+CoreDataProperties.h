
#import "MOAssetUploadErrorPerLaunch+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadErrorPerLaunch (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadErrorPerLaunch *> *)fetchRequest;

@property (nullable, nonatomic, retain) MOAssetUploadRecord *uploadRecord;

@end

NS_ASSUME_NONNULL_END
