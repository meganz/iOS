
#import "ImageExportManager.h"
#import "CameraUploadManager+Settings.h"
#import "MEGAConstants.h"
#import "ImageExportOperation.h"
@import CoreServices;
@import AVFoundation;

static const NSUInteger HEICMaxConcurrentOperationCount = 1;

@interface ImageExportManager ()

@property (strong, nonatomic) NSOperationQueue *HEICExportOerationQueue;
@property (strong, nonatomic) NSOperationQueue *generalExportOperationQueue;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation ImageExportManager

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
    if (_HEICExportOerationQueue) {
        return _HEICExportOerationQueue;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_HEICExportOerationQueue == nil) {
            self->_HEICExportOerationQueue = [[NSOperationQueue alloc] init];
            self->_HEICExportOerationQueue.qualityOfService = NSQualityOfServiceUtility;
            self->_HEICExportOerationQueue.maxConcurrentOperationCount = HEICMaxConcurrentOperationCount;
            self->_HEICExportOerationQueue.name = @"HEICExportOerationQueue";
        }
    });
    
    return _HEICExportOerationQueue;
}

- (NSOperationQueue *)generalExportOperationQueue {
    if (_generalExportOperationQueue) {
        return _generalExportOperationQueue;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_generalExportOperationQueue == nil) {
            self->_generalExportOperationQueue = [[NSOperationQueue alloc] init];
            self->_generalExportOperationQueue.qualityOfService = NSQualityOfServiceUtility;
            self->_generalExportOperationQueue.name = @"generalExportOperationQueue";
        }
    });
    
    return _generalExportOperationQueue;
}

- (void)exportImageAtURL:(NSURL *)imageURL dataTypeUTI:(NSString *)dataUTI toURL:(NSURL *)outputURL outputTypeUTI:(NSString *)outputUTI shouldStripGPSInfo:(BOOL)shouldStripGPSInfo completion:(void (^)(BOOL))completion {
    ImageExportOperation *exportOperation = [[ImageExportOperation alloc] initWithImageURL:imageURL outputURL:outputURL outputImageTypeUTI:outputUTI shouldStripGPSInfo:shouldStripGPSInfo completion:completion];
    NSOperationQueue *queue = [self exportQueueForDataUTI:dataUTI outputTypeUTI:outputUTI];
    [queue addOperation:exportOperation];
}

- (NSOperationQueue *)exportQueueForDataUTI:(NSString *)dataUTI outputTypeUTI:(NSString *)outputUTI {
    NSOperationQueue *queue = self.generalExportOperationQueue;
    if (@available(iOS 11.0, *)) {
        if (UTTypeConformsTo((__bridge CFStringRef)dataUTI, (__bridge CFStringRef)AVFileTypeHEIC)) {
            if (outputUTI.length == 0 || [dataUTI isEqualToString:outputUTI]) {
                queue = self.HEICExportOerationQueue;
            }
        }
    }
    
    return queue;
}

@end
