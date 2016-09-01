#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

#import "MEGASdkManager.h"

@interface MEGAAssetOperation : NSOperation

- (instancetype)initWithPHAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode automatically:(BOOL)automatically;
- (instancetype)initWithALAsset:(ALAsset *)asset cameraUploadNode:(MEGANode *)cameraUploadNode;

@end
