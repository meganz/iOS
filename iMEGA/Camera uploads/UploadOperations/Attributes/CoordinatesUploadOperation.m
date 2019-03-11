
#import "CoordinatesUploadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
@import CoreLocation;

@implementation CoordinatesUploadOperation

- (void)start {
    [super start];
    
    CLLocation *location = [NSKeyedUnarchiver unarchiveObjectWithFile:self.attributeURL.path];
    if (location == nil) {
        MEGALogError(@"[Camera Upload] can not unarchive location for node %@ %@", self.node.name, self.attributeURL);
        [self finishOperation];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setUnshareableNodeCoordinates:self.node latitude:@(location.coordinate.latitude) longitude:@(location.coordinate.longitude) delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload coordinate failed for node: %@ at %@, error: %@", weakSelf.node.name, weakSelf.attributeURL, error.nativeError);
            if (error.type == MEGAErrorTypeApiEExist) {
                [NSFileManager.defaultManager removeItemIfExistsAtURL:weakSelf.attributeURL];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] Upload coordinate succeeded for node %@ at %@", weakSelf.node.name, weakSelf.attributeURL);
            [NSFileManager.defaultManager removeItemIfExistsAtURL:weakSelf.attributeURL];
        }
        
        [weakSelf finishOperation];
    }]];
}

@end
