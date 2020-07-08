
#import "MOOfflineFolderLayout+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOOfflineFolderLayout (CoreDataProperties)

+ (NSFetchRequest<MOOfflineFolderLayout *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localPath;
@property (nullable, nonatomic, copy) NSNumber *value;

@end

NS_ASSUME_NONNULL_END
