
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchOperation : MEGAOperation

- (instancetype)initWithParentNode:(MEGANode *)node text:(NSString *)text completion:(void (^)(NSArray <MEGANode *> *_Nullable nodesFound))completion;

@end

NS_ASSUME_NONNULL_END
