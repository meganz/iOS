
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"
#import "AssetLocalAttribute.h"
#import "AssetUploadInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface AttributeUploadManager : NSObject

+ (instancetype)shared;

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded;

- (AssetLocalAttribute *)saveAttributesForUploadInfo:(AssetUploadInfo *)uploadInfo error:(NSError * _Nullable *)error;
- (void)uploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node;

- (void)collateLocalAttributes;

@end

NS_ASSUME_NONNULL_END
