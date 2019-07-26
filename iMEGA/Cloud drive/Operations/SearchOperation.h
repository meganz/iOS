
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchOperation : MEGAOperation

- (instancetype)initWithParentNode:(MEGANode *)node text:(NSString *)text completion:(void (^)(NSArray * _Nullable searchArray))completion;

@end

NS_ASSUME_NONNULL_END
