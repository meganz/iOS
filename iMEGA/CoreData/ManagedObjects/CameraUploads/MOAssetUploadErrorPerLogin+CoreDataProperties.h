
#import "MOAssetUploadErrorPerLogin+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadErrorPerLogin (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadErrorPerLogin *> *)fetchRequest;

@property (nullable, nonatomic, retain) MOAssetUploadRecord *uploadRecord;

@end

NS_ASSUME_NONNULL_END
