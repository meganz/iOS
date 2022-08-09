
#import "MOMessage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOMessage (CoreDataProperties)

+ (NSFetchRequest<MOMessage *> *)fetchRequest;

@property (nonnull, nonatomic, copy) NSNumber *chatId;
@property (nonnull, nonatomic, copy) NSNumber *messageId;

@end

NS_ASSUME_NONNULL_END
