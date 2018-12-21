
#import "MEGAExpirableOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeUploadOperation : MEGAExpirableOperation

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSURL *attributeURL;

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node expiresAfterTimeInterval:(NSTimeInterval)timeInterval;

- (void)moveAttributeToDirectoryURL:(NSURL *)directoryURL newFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
