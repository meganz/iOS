
#import "MOAssetUploadRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSString *status;
@property (nullable, nonatomic, copy) NSDate *modificationDate;

@end

NS_ASSUME_NONNULL_END
