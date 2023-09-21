#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchOperation : MEGAOperation

- (instancetype)initWithParentNode:(MEGANode *)node
                              text:(NSString *)text
                       cancelToken:(MEGACancelToken *)cancelToken
                               sdk:(MEGASdk *)sdk
                        completion:(void (^)(NSArray <MEGANode *> *_Nullable nodesFound, BOOL isCancelled))completion;

- (instancetype)initWithParentNode:(MEGANode *)parentNode
                              text:(nullable NSString *)text
                       cancelToken:(MEGACancelToken *)cancelToken
                     sortOrderType:(MEGASortOrderType)sortOrderType
                    nodeFormatType:(MEGANodeFormatType)nodeFormatType
                               sdk:(MEGASdk *)sdk
                        completion:(void (^)(NSArray <MEGANode *> *_Nullable nodesFound, BOOL isCancelled))completion;

@end

NS_ASSUME_NONNULL_END
