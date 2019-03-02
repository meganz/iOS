
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeFileUploadOperation : MEGAOperation

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSURL *attributeURL;

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
