
#import "MOAssetUploadFileNameRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadFileNameRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadFileNameRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSString *localUniqueFileName;

@end

NS_ASSUME_NONNULL_END
