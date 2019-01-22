
#import "PhotoExportOperation.h"
#import "NSData+CameraUpload.h"

@interface PhotoExportOperation ()

@property (strong, nonatomic) NSData *photoData;
@property (strong, nonatomic) NSURL *outputURL;
@property (strong, nonatomic) NSString *outputImageTypeUTI;
@property (nonatomic) BOOL shouldStripGPSInfo;
@property (copy, nonatomic) void (^completionHandler)(BOOL succeeded);

@end

@implementation PhotoExportOperation

- (instancetype)initWithPhotoData:(NSData *)data outputURL:(NSURL *)URL outputImageTypeUTI:(NSString *)UTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completionHandler:(void (^)(BOOL succeeded))handler {
    self = [super init];
    if (self) {
        _photoData = data;
        _outputURL = URL;
        _outputImageTypeUTI = UTI;
        _shouldStripGPSInfo = shouldStripGPSInfo;
        _completionHandler = handler;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    [self beginBackgroundTaskWithExpirationHandler:^{
        if (self.completionHandler) {
            self.completionHandler(NO);
        }
        
        [self finishOperation];
    }];
    
    BOOL succeeded = [self.photoData mnz_exportToURL:self.outputURL imageType:self.outputImageTypeUTI shouldStripGPSInfo:self.shouldStripGPSInfo];
    self.completionHandler(succeeded);
    [self finishOperation];
}

@end
