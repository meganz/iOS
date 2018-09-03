
#import "MOUploadTransfer+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOUploadTransfer (CoreDataProperties)

+ (NSFetchRequest<MOUploadTransfer *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSNumber *parentNodeHandle;

@end

NS_ASSUME_NONNULL_END
