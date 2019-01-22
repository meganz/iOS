
#import "PhotoExportManager.h"
#import "CameraUploadManager+Settings.h"
#import "MEGAConstants.h"

static const NSUInteger QueueExportHEICMaxConcurrentOperationCount = 1;

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
        _operationQueue = [[NSOperationQueue alloc] init];
        [self configQueueMaxConcurrentCount];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(configQueueMaxConcurrentCount) name:MEGACameraUploadSwitchPhotoFormatNotificationName object:nil];
    }
    
    return self;
}

- (void)configQueueMaxConcurrentCount {
    if (CameraUploadManager.shouldConvertHEICPhoto) {
        _operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    } else {
        _operationQueue.maxConcurrentOperationCount = QueueExportHEICMaxConcurrentOperationCount;
    }
}


@end
