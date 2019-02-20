
#import "CameraUploadNodeLoader.h"
#import "MEGASdkManager.h"
#import "MEGACreateFolderRequestDelegate.h"

static NSString * const CameraUploadsNodeHandleKey = @"CameraUploadsNodeHandle";
static NSString * const CameraUplodFolderName = @"Camera Uploads";

@implementation CameraUploadNodeLoader

- (MEGANode *)restoreExistingCameraUploadNode {
    MEGANode *node = [self savedCameraUploadNodeInLocal];
    if (node == nil) {
        node = [self searchCameraUploadNodeInRoot];
        [self saveCameraUploadNode:node];
    }
    
    return node;
}

- (MEGANode *)savedCameraUploadNodeInLocal {
    unsigned long long cameraUploadHandle = [[[NSUserDefaults standardUserDefaults] objectForKey:CameraUploadsNodeHandleKey] unsignedLongLongValue];
    if (cameraUploadHandle > 0) {
        MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:cameraUploadHandle];
        if (node.parentHandle == MEGASdkManager.sharedMEGASdk.rootNode.handle) {
            return node;
        }
    }
    
    return nil;
}

- (void)saveCameraUploadNode:(MEGANode *)node {
    if (node == nil) {
        return;
    }
    
    [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:node.handle] forKey:CameraUploadsNodeHandleKey];
}

- (MEGANode *)searchCameraUploadNodeInRoot {
    MEGANodeList *nodeList = [MEGASdkManager.sharedMEGASdk childrenForParent:MEGASdkManager.sharedMEGASdk.rootNode];
    NSInteger nodeListSize = [[nodeList size] integerValue];
    
    for (NSInteger i = 0; i < nodeListSize; i++) {
        MEGANode *node = [nodeList nodeAtIndex:i];
        if ([CameraUplodFolderName isEqualToString:node.name] && node.isFolder) {
            return node;
        }
    }
    
    return nil;
}

- (void)loadCameraUploadNodeWithCompletion:(void (^)(MEGANode * _Nullable cameraUploadNode))completion {
    MEGANode *node = [self restoreExistingCameraUploadNode];
    if (node) {
        completion(node);
    } else {
        MEGACreateFolderRequestDelegate *delegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
                [self saveCameraUploadNode:node];
                completion(node);
            });
        }];
        
        [MEGASdkManager.sharedMEGASdk createFolderWithName:CameraUplodFolderName parent:MEGASdkManager.sharedMEGASdk.rootNode
                                                  delegate:delegate];
    }
}

@end
