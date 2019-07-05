
#import "MOAssetUploadErrorRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadErrorRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadErrorRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSNumber *errorCount;

@end

NS_ASSUME_NONNULL_END
