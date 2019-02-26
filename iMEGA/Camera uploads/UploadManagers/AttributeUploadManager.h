
#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"
#import "AssetLocalAttribute.h"
#import "AssetUploadInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface AttributeUploadManager : NSObject

+ (instancetype)shared;

- (void)waitUntilAllThumbnailUploadsAreFinished;
- (void)waitUntilAllAttributeUploadsAreFinished;

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded;

- (AssetLocalAttribute *)saveAttributeForUploadInfo:(AssetUploadInfo *)uploadInfo;
- (void)uploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node;

- (void)uploadCoordinateLocation:(nullable CLLocation *)location forNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
