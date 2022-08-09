
#import "MOFolderLayout+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOFolderLayout (CoreDataProperties)

+ (NSFetchRequest<MOFolderLayout *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *handle;
@property (nullable, nonatomic, copy) NSNumber *value;

@end

NS_ASSUME_NONNULL_END
