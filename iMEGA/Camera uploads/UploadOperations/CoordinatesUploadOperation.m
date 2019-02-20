
#import "CoordinatesUploadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"
@import CoreLocation;

@interface CoordinatesUploadOperation ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) CLLocation *location;

@end

@implementation CoordinatesUploadOperation

- (instancetype)initWithLocation:(CLLocation *)location node:(MEGANode *)node {
    self = [super init];
    if (self) {
        _node = node;
        _location = location;
    }
    return self;
}

- (void)start {
    [super start];

    [self beginBackgroundTaskWithExpirationHandler:^{
        [self finishOperation];
    }];
    
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setUnshareableNodeCoordinates:self.node latitude:@(self.location.coordinate.latitude) longitude:@(self.location.coordinate.longitude) delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload coordinate failed for node: %@, error: %@", weakSelf.node.name, error.nativeError);
        } else {
            MEGALogDebug(@"[Camera Upload] Upload coordinate succeeded for node %@", weakSelf.node.name);
        }
        
        [weakSelf finishOperation];
    }]];
}

@end
