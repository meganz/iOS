#import "DiskSpaceDetector.h"
#import "CameraUploadManager.h"
#import "NSFileManager+MNZCategory.h"

static const NSUInteger PhotoRetryExtraDiskSpaceInBytes = 5 * 1024 * 1024;
static const NSUInteger VideoRetryExtraDiskSpaceInBytes = 30 * 1024 * 1024;
static const NSTimeInterval RetryTimerInterval = 60;
static const NSTimeInterval RetryTimerTolerance = 6;

@interface DiskSpaceDetector ()

@property (nonatomic) unsigned long long photoRetryDiskFreeSpace;
@property (nonatomic) unsigned long long videoRetryDiskFreeSpace;
@property (strong, nonatomic) dispatch_source_t photoRetryTimer;
@property (strong, nonatomic) dispatch_source_t videoRetryTimer;
@property (nonatomic, getter=isDiskFullForPhotos) BOOL diskIsFullForPhotos;
@property (nonatomic, getter=isDiskFullForVideos) BOOL diskIsFullForVideos;

@end

@implementation DiskSpaceDetector

#pragma mark - properties

- (void)setDiskIsFullForPhotos:(BOOL)diskIsFullForPhotos {
    if (_diskIsFullForPhotos != diskIsFullForPhotos) {
        _diskIsFullForPhotos = diskIsFullForPhotos;
        CameraUploadManager.shared.photoUploadPaused = diskIsFullForPhotos;
        MEGALogDebug(@"[Camera Upload] disk is %@ for photos", diskIsFullForPhotos ? @"full" : @"available");
    }
}

- (void)setDiskIsFullForVideos:(BOOL)diskIsFullForVideos {
    if (_diskIsFullForVideos != diskIsFullForVideos) {
        _diskIsFullForVideos = diskIsFullForVideos;
        CameraUploadManager.shared.videoUploadPaused = diskIsFullForVideos;
        MEGALogDebug(@"[Camera Upload] disk is %@ for videos", diskIsFullForVideos ? @"full" : @"available");
    }
}

#pragma mark - start and stop detections

- (void)startDetectingPhotoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadPhotoUploadLocalDiskFullNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceivePhotoUploadDiskFullNotification:) name:MEGACameraUploadPhotoUploadLocalDiskFullNotification object:nil];
}

- (void)startDetectingVideoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadVideoUploadLocalDiskFullNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveVideoUploadDiskFullNotification:) name:MEGACameraUploadVideoUploadLocalDiskFullNotification object:nil];
}

- (void)stopDetectingPhotoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadPhotoUploadLocalDiskFullNotification object:nil];
    if (self.photoRetryTimer) {
        dispatch_source_cancel(self.photoRetryTimer);
    }
    
    _diskIsFullForPhotos = NO;
}

- (void)stopDetectingVideoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadVideoUploadLocalDiskFullNotification object:nil];
    if (self.videoRetryTimer) {
        dispatch_source_cancel(self.videoRetryTimer);
    }
    
    _diskIsFullForVideos = NO;
}

#pragma mark - notifications

- (void)didReceivePhotoUploadDiskFullNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive photo upload disk full notification %@", notification);
    self.diskIsFullForPhotos = YES;
    self.photoRetryDiskFreeSpace = NSFileManager.defaultManager.mnz_fileSystemFreeSize + PhotoRetryExtraDiskSpaceInBytes;
    [self setupPhotoUploadRetryTimer];
}

- (void)didReceiveVideoUploadDiskFullNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive video upload disk full notification %@", notification);
    self.diskIsFullForVideos = YES;
    self.videoRetryDiskFreeSpace = NSFileManager.defaultManager.mnz_fileSystemFreeSize + VideoRetryExtraDiskSpaceInBytes;
    [self setupVideoUploadRetryTimer];
}

#pragma mark - setup timers

- (void)setupPhotoUploadRetryTimer {
    if (self.photoRetryTimer) {
        dispatch_source_cancel(self.photoRetryTimer);
    }
    
    __weak __typeof__(self) weakSelf = self;
    self.photoRetryTimer = [self newDiskSpaceRetryTimerWithHandler:^{
        [weakSelf photoRetryTimerFired];
    }];
    dispatch_resume(self.photoRetryTimer);
}

- (void)photoRetryTimerFired {
    if (NSFileManager.defaultManager.mnz_fileSystemFreeSize > self.photoRetryDiskFreeSpace) {
        if (self.photoRetryTimer) {
            dispatch_source_cancel(self.photoRetryTimer);
        }

        self.diskIsFullForPhotos = NO;
    }
}

- (void)setupVideoUploadRetryTimer {
    if (self.videoRetryTimer) {
        dispatch_source_cancel(self.videoRetryTimer);
    }
    
    __weak __typeof__(self) weakSelf = self;
    self.videoRetryTimer = [self newDiskSpaceRetryTimerWithHandler:^{
        [weakSelf videoRetryTimerFired];
    }];
    dispatch_resume(self.videoRetryTimer);
}

- (void)videoRetryTimerFired {
    if (NSFileManager.defaultManager.mnz_fileSystemFreeSize > self.videoRetryDiskFreeSpace) {
        if (self.videoRetryTimer) {
            dispatch_source_cancel(self.videoRetryTimer);
        }
        
        self.diskIsFullForVideos = NO;
    }
}

#pragma mark - utils

- (dispatch_source_t)newDiskSpaceRetryTimerWithHandler:(void (^)(void))handler {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, (int64_t)(RetryTimerInterval * NSEC_PER_SEC)), (uint64_t)(RetryTimerInterval * NSEC_PER_SEC), (uint64_t)(RetryTimerTolerance * NSEC_PER_SEC));
    dispatch_source_set_event_handler(timer, handler);
    return timer;
}

@end
