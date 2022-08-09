
#import "MOAssetUploadRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *creationDate;
@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSNumber *mediaType;
@property (nullable, nonatomic, copy) NSNumber *mediaSubtypes;
@property (nullable, nonatomic, copy) NSNumber *additionalMediaSubtypes;
@property (nullable, nonatomic, copy) NSNumber *status;

@property (nullable, nonatomic, retain) MOAssetUploadErrorPerLaunch *errorPerLaunch;
@property (nullable, nonatomic, retain) MOAssetUploadErrorPerLogin *errorPerLogin;
@property (nullable, nonatomic, retain) MOAssetUploadFileNameRecord *fileNameRecord;

@end

NS_ASSUME_NONNULL_END
