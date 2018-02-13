
#import "MOChatDraft+CoreDataProperties.h"

@implementation MOChatDraft (CoreDataProperties)

+ (NSFetchRequest<MOChatDraft *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ChatDraft"];
}

@dynamic chatId;
@dynamic text;

@end
