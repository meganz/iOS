
#import <Foundation/Foundation.h>
#import "CameraUploadNodeLoadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MEGANode;

@interface CameraUploadNodeLoader : NSObject

/**
 load camera upload node. It follows these 3 steps to load a camera upload node:
 1, read the node saved in local
 2, if the node is not in local, we will search to see if the node is exist under root
 3, if we can not find the node from existing node tree, we will create a new camera upload node

 @param completion the call back completion handler. The completion block could be called on any thread.
 */
- (void)loadCameraUploadNodeWithCompletion:(CameraUploadNodeLoadCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
