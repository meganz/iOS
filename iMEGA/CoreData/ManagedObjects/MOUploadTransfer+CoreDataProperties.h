
#import "MOUploadTransfer+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOUploadTransfer (CoreDataProperties)

+ (NSFetchRequest<MOUploadTransfer *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;

@end

NS_ASSUME_NONNULL_END
