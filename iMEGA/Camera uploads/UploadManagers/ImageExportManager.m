#import "ImageExportManager.h"
#import "ImageExportOperation.h"
@import CoreServices;
@import AVFoundation;

static const NSUInteger HEICMaxConcurrentOperationCount = 1;

@interface ImageExportManager ()

@property (strong, nonatomic) NSOperationQueue *HEICExportOperationQueue;
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

- (NSOperationQueue *)HEICExportOperationQueue {
    if (_HEICExportOperationQueue) {
        return _HEICExportOperationQueue;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_HEICExportOperationQueue == nil) {
            self->_HEICExportOperationQueue = [[NSOperationQueue alloc] init];
            self->_HEICExportOperationQueue.qualityOfService = NSQualityOfServiceUtility;
            self->_HEICExportOperationQueue.maxConcurrentOperationCount = HEICMaxConcurrentOperationCount;
            self->_HEICExportOperationQueue.name = @"HEICExportOerationQueue";
        }
    });
    
    return _HEICExportOperationQueue;
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
    if (UTTypeConformsTo((__bridge CFStringRef)dataUTI, (__bridge CFStringRef)AVFileTypeHEIC)) {
        if (outputUTI.length == 0 || [dataUTI isEqualToString:outputUTI]) {
            queue = self.HEICExportOperationQueue;
        }
    }
    
    return queue;
}

@end
