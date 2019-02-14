
#import "MOAssetUploadFileNameRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadFileNameRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadFileNameRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localUniqueFileName;
@property (nullable, nonatomic, copy) NSString *fileExtension;
@property (nullable, nonatomic, retain) MOAssetUploadRecord *uploadRecord;


@end

NS_ASSUME_NONNULL_END
