
#import "CameraUploadNodeLoadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"

static NSString * const CameraUploadsNodeHandleKey = @"CameraUploadsNodeHandle";

@interface CameraUploadNodeLoadOperation ()

@property (copy, nonatomic) CameraUploadNodeLoadCompletionHandler completion;

@end

@implementation CameraUploadNodeLoadOperation

- (instancetype)initWithLoadCompletion:(CameraUploadNodeLoadCompletionHandler)completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

- (void)start {
    if (self.cancelled) {
        if (self.completion) {
            self.completion(nil, nil);
        }
        
        [self finishOperation];
        return;
    }
    
    [self startExecuting];
    
    MEGANode *node = [self restoreExistingCameraUploadNode];
    if (node) {
        MEGALogDebug(@"[Camera Upload] existing camera upload node is restored");
        if (self.completion) {
            self.completion(node, nil);
        }
        
        [self finishOperation];
    } else {
        CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] error when to create camera upload node %@", error.nativeError);
                if (self.completion) {
                    self.completion(nil, error.nativeError);
                }
            } else {
                MEGALogDebug(@"[Camera Upload] camera upload node is created");
                MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
                [self saveCameraUploadNode:node];
                if (self.completion) {
                    self.completion(node, nil);
                }
            }
            
            [self finishOperation];
        }];
        
        [MEGASdkManager.sharedMEGASdk createFolderWithName:MEGACameraUploadsNodeName parent:MEGASdkManager.sharedMEGASdk.rootNode
                                                  delegate:delegate];
    }
}

#pragma mark - restore existing camera upload node

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

- (MEGANode *)searchCameraUploadNodeInRoot {
    MEGANodeList *nodeList = [MEGASdkManager.sharedMEGASdk childrenForParent:MEGASdkManager.sharedMEGASdk.rootNode];
    NSInteger nodeListSize = [[nodeList size] integerValue];
    
    for (NSInteger i = 0; i < nodeListSize; i++) {
        MEGANode *node = [nodeList nodeAtIndex:i];
        if ([MEGACameraUploadsNodeName isEqualToString:node.name] && node.isFolder) {
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

@end
