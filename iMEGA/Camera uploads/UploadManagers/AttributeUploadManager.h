
#import <Foundation/Foundation.h>
#import "AssetLocalAttribute.h"
#import "AssetUploadInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface AttributeUploadManager : NSObject

+ (instancetype)shared;

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded;

- (nullable AssetLocalAttribute *)saveAttributesForUploadInfo:(AssetUploadInfo *)uploadInfo error:(NSError * _Nullable *)error;
- (void)uploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node;

- (void)collateLocalAttributes;

- (void)cancelAllAttributesUpload;

@end

NS_ASSUME_NONNULL_END
