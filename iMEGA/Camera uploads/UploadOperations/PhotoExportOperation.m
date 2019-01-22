
#import "PhotoExportOperation.h"
#import "NSData+CameraUpload.h"

@interface PhotoExportOperation ()

@property (strong, nonatomic) NSData *photoData;
@property (strong, nonatomic) NSURL *outputURL;
@property (strong, nonatomic) NSString *outputImageTypeUTI;
@property (nonatomic) BOOL shouldStripGPSInfo;
@property (copy, nonatomic) void (^completion)(BOOL succeeded);

@end

@implementation PhotoExportOperation

- (instancetype)initWithPhotoData:(NSData *)data outputURL:(NSURL *)URL outputImageTypeUTI:(NSString *)UTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL succeeded))completion {
    self = [super init];
    if (self) {
        _photoData = data;
        _outputURL = URL;
        _outputImageTypeUTI = UTI;
        _shouldStripGPSInfo = shouldStripGPSInfo;
        _completion = completion;
    }
    
    return self;
}

- (void)start {
    if (self.isCancelled) {
        if (self.completion) {
            self.completion(NO);
        }
        [self finishOperation];
        return;
    }
    
    [self startExecuting];
    
    [self beginBackgroundTaskWithExpirationHandler:^{
        if (self.completion) {
            self.completion(NO);
        }
        
        [self finishOperation];
    }];
    
    BOOL succeeded = [self.photoData mnz_exportToURL:self.outputURL imageType:self.outputImageTypeUTI shouldStripGPSInfo:self.shouldStripGPSInfo];
    self.completion(succeeded);
    [self finishOperation];
}

@end
