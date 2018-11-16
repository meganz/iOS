
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeUploadOperation : MEGAOperation

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

- (instancetype)initWithNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo;

- (void)expireOperation;

- (void)finishOperationWithError:(nullable NSError *)error;

- (NSError *)errorWithMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
