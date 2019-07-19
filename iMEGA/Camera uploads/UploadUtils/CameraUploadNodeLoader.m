
#import "CameraUploadNodeLoader.h"

@interface CameraUploadNodeLoader ()

@property (strong, nonatomic) NSOperationQueue *cameraUploadNodeLoadQueue;

@end

@implementation CameraUploadNodeLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        _cameraUploadNodeLoadQueue = [[NSOperationQueue alloc] init];
        _cameraUploadNodeLoadQueue.maxConcurrentOperationCount = 1;
        _cameraUploadNodeLoadQueue.qualityOfService = NSQualityOfServiceUtility;
        _cameraUploadNodeLoadQueue.name = @"cameraUploadNodeLoadQueue";
    }
    return self;
}

- (void)loadCameraUploadNodeWithCompletion:(CameraUploadNodeLoadCompletionHandler)completion {
    [self.cameraUploadNodeLoadQueue addOperation:[[CameraUploadNodeLoadOperation alloc] initWithLoadCompletion:completion]];
}

@end
