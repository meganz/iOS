
#import "MOChatDraft+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOChatDraft (CoreDataProperties)

+ (NSFetchRequest<MOChatDraft *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *chatId;
@property (nullable, nonatomic, copy) NSString *text;

@end

NS_ASSUME_NONNULL_END
