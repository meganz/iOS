
#import "PhotoExportManager.h"
#import "CameraUploadManager+Settings.h"
#import "MEGAConstants.h"
#import "PhotoExportOperation.h"
@import CoreServices;
@import AVFoundation;

static const NSUInteger HEICMaxConcurrentOperationCount = 1;

@interface PhotoExportManager ()

@property (strong, nonatomic) NSOperationQueue *HEICExportOerationQueue;
@property (strong, nonatomic) NSOperationQueue *generalExportOperationQueue;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation PhotoExportManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("nz.mega.cameraUpload.photoExportSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSOperationQueue *)HEICExportOerationQueue {
    dispatch_sync(self.serialQueue, ^{
        if (self->_HEICExportOerationQueue == nil) {
            self->_HEICExportOerationQueue = [[NSOperationQueue alloc] init];
            self->_HEICExportOerationQueue.maxConcurrentOperationCount = HEICMaxConcurrentOperationCount;
        }
    });
    
    return _HEICExportOerationQueue;
}

- (NSOperationQueue *)generalExportOperationQueue {
    dispatch_sync(self.serialQueue, ^{
        if (self->_generalExportOperationQueue == nil) {
            self->_generalExportOperationQueue = [[NSOperationQueue alloc] init];
        }
    });
    
    return _generalExportOperationQueue;
}

- (void)exportPhotoData:(NSData *)data dataTypeUTI:(NSString *)dataUTI outputURL:(NSURL *)outputURL outputTypeUTI:(NSString *)outputUTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL))completion {
    PhotoExportOperation *exportOperation = [[PhotoExportOperation alloc] initWithPhotoData:data outputURL:outputURL outputImageTypeUTI:outputUTI shouldStripGPSInfo:shouldStripGPSInfo completion:completion];
    NSOperationQueue *queue = [self exportQueueForDataUTI:dataUTI outputTypeUTI:outputUTI];
    [queue addOperation:exportOperation];
}

- (NSOperationQueue *)exportQueueForDataUTI:(NSString *)dataUTI outputTypeUTI:(NSString *)outputUTI {
    if (@available(iOS 11.0, *)) {
        if (UTTypeConformsTo((__bridge CFStringRef)dataUTI, (__bridge CFStringRef)AVFileTypeHEIC)) {
            if (outputUTI.length == 0 || [dataUTI isEqualToString:outputUTI]) {
                return self.HEICExportOerationQueue;
            } else {
                return self.generalExportOperationQueue;
            }
        } else {
            return self.generalExportOperationQueue;
        }
    } else {
        return self.generalExportOperationQueue;
    }
}

@end
