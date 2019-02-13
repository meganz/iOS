
#import "DiskSpaceDetector.h"
#import "MEGAConstants.h"
#import "CameraUploadManager.h"
#import "NSFileManager+MNZCategory.h"

static const NSUInteger PhotoRetryExtraDiskSpaceInBytes = 5 * 1024 * 1024;
static const NSUInteger VideoRetryExtraDiskSpaceInBytes = 30 * 1024 * 1024;
static const NSTimeInterval RetryTimerInterval = 60;
static const NSTimeInterval RetryTimerTolerance = 6;

@interface DiskSpaceDetector ()

@property (nonatomic) unsigned long long photoRetryDiskFreeSpace;
@property (nonatomic) unsigned long long videoRetryDiskFreeSpace;
@property (strong, nonatomic) NSTimer *photoRetryTimer;
@property (strong, nonatomic) NSTimer *videoRetryTimer;
@property (nonatomic, getter=isDiskFullForPhotos) BOOL diskIsFullForPhotos;
@property (nonatomic, getter=isDiskFullForVideos) BOOL diskIsFullForVideos;

@end

@implementation DiskSpaceDetector

#pragma mark - properties

- (void)setDiskIsFullForPhotos:(BOOL)diskIsFullForPhotos {
    if (_diskIsFullForPhotos != diskIsFullForPhotos) {
        _diskIsFullForPhotos = diskIsFullForPhotos;
        CameraUploadManager.shared.pausePhotoUpload = diskIsFullForPhotos;
        MEGALogDebug(@"[Camera Upload] disk is %@ for photos", diskIsFullForPhotos ? @"full" : @"not full");
    }
}

- (void)setDiskIsFullForVideos:(BOOL)diskIsFullForVideos {
    if (_diskIsFullForVideos != diskIsFullForVideos) {
        _diskIsFullForVideos = diskIsFullForVideos;
        CameraUploadManager.shared.pauseVideoUpload = diskIsFullForVideos;
        MEGALogDebug(@"[Camera Upload] disk is %@ for videos", diskIsFullForVideos ? @"full" : @"not full");
    }
}

#pragma mark - start and stop detections

- (void)startDetectingPhotoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadPhotoUploadLocalDiskFullNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceivePhotoUploadDiskFullNotification) name:MEGACameraUploadPhotoUploadLocalDiskFullNotificationName object:nil];
}

- (void)startDetectingVideoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadVideoUploadLocalDiskFullNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveVideoUploadDiskFullNotification) name:MEGACameraUploadVideoUploadLocalDiskFullNotificationName object:nil];
}

- (void)stopDetectingPhotoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadPhotoUploadLocalDiskFullNotificationName object:nil];
    if (self.photoRetryTimer.isValid) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [self.photoRetryTimer invalidate];
            self.photoRetryTimer = nil;
        }];
    }
}

- (void)stopDetectingVideoUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadVideoUploadLocalDiskFullNotificationName object:nil];
    if (self.videoRetryTimer.isValid) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [self.videoRetryTimer invalidate];
            self.videoRetryTimer = nil;
        }];
    }
}

#pragma mark - notifications

- (void)didReceivePhotoUploadDiskFullNotification {
    self.diskIsFullForPhotos = YES;
    self.photoRetryDiskFreeSpace = NSFileManager.defaultManager.deviceFreeSize + PhotoRetryExtraDiskSpaceInBytes;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        [self setupPhotoUploadRetryTimer];
    }];
}

- (void)didReceiveVideoUploadDiskFullNotification {
    self.diskIsFullForVideos = YES;
    self.videoRetryDiskFreeSpace = NSFileManager.defaultManager.deviceFreeSize + VideoRetryExtraDiskSpaceInBytes;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        [self setupVideoUploadRetryTimer];
    }];
}

#pragma mark - setup timers

- (void)setupPhotoUploadRetryTimer {
    if (self.photoRetryTimer.isValid) {
        [self.photoRetryTimer invalidate];
    }

    self.photoRetryTimer = [NSTimer scheduledTimerWithTimeInterval:RetryTimerInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (NSFileManager.defaultManager.deviceFreeSize > self.photoRetryDiskFreeSpace) {
            [timer invalidate];
            self.diskIsFullForPhotos = NO;
        }
    }];
    self.photoRetryTimer.tolerance = RetryTimerTolerance;
}

- (void)setupVideoUploadRetryTimer {
    if (self.videoRetryTimer.isValid) {
        [self.videoRetryTimer invalidate];
    }
    
    self.videoRetryTimer = [NSTimer scheduledTimerWithTimeInterval:RetryTimerInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (NSFileManager.defaultManager.deviceFreeSize > self.videoRetryDiskFreeSpace) {
            [timer invalidate];
            self.diskIsFullForVideos = NO;
        }
    }];
    self.videoRetryTimer.tolerance = RetryTimerTolerance;
}

@end
