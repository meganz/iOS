
#import "MEGATaskOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeUploadOperation : MEGATaskOperation

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSURL *attributeURL;

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node expiresAfterTimeInterval:(NSTimeInterval)timeInterval;

- (void)cacheAttributeToDirectoryURL:(NSURL *)directoryURL fileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
