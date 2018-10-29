
#import <Foundation/Foundation.h>
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadCoordinator : NSObject

- (void)completeUploadWithInfo:(AssetUploadInfo *)info uploadToken:(NSData *)token success:(void (^)(MEGANode *node))success failure:(void (^)(MEGAError * error))failure;

@end

NS_ASSUME_NONNULL_END
