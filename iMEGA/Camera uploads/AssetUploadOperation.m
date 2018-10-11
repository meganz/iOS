
#import "AssetUploadOperation.h"
#import "PHAsset+MNZCategory.h"
@import Photos;

@interface AssetUploadOperation ()

@property (strong, nonatomic) PHAsset *asset;

@end

@implementation AssetUploadOperation

- (instancetype)initWithAsset:(PHAsset *)asset {
    self = [super init];
    if (self) {
        _asset = asset;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }
        
        [self processImageData:imageData];
    }];
}

- (void)processImageData:(NSData *)imageData {
    UIImage *image = [UIImage imageWithData:imageData];
    NSData *JPEGData = UIImageJPEGRepresentation(image, 1.0);
    NSURL *fileURL = [self.asset urlForCameraUploadWithExtension:@"jpg"];
    [JPEGData writeToURL:fileURL atomically:YES];
}

@end
