#import "MEGAOperation.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeUploadOperation : MEGAOperation

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSURL *attributeURL;

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
