
#import "TransferSessionTaskDelegate.h"
#import "TransferSessionManager.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadCoordinator.h"
#import "CameraUploadRecordManager.h"
#import "NSString+MNZCategory.h"

@interface TransferSessionTaskDelegate ()

@property (strong, nonatomic) NSMutableData *mutableData;
@property (copy, nonatomic) UploadCompletionHandler completion;
@property (strong, nonatomic) CameraUploadCoordinator *uploadCoordinator;

@end

@implementation TransferSessionTaskDelegate

- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion {
    self = [super init];
    if (self) {
        _mutableData = [NSMutableData data];
        _completion = completion;
    }
    
    return self;
}

- (CameraUploadCoordinator *)uploadCoordinator {
    if (_uploadCoordinator == nil) {
        _uploadCoordinator = [[CameraUploadCoordinator alloc] init];
    }
    
    return _uploadCoordinator;
}

#pragma mark - task level delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    MEGALogDebug(@"Camera Upload - Session %@ task %@ did complete with error: %@", session.configuration.identifier, task.originalRequest, error);
    
    NSData *transferToken = [self.mutableData copy];
    
    if (self.completion) {
        self.completion(transferToken, error);
    } else {
        if (error) {
            [self finishTask:task withStatus:uploadStatusFailed];
            return;
        }
        
        [self handleBackgroundCompletedTask:task withToken:transferToken];
    }
}

#pragma mark - data level delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MEGALogDebug(@"Camera Upload - Session %@ task %@ did receive data with size: %lu", session.configuration.identifier, dataTask.originalRequest, data.length);
    [self.mutableData appendData:data];
}

#pragma mark - handle task completion

- (NSURL *)archivedUploadInfoURLForTask:(NSURLSessionTask *)task {
    NSString *localIdentifier = task.taskDescription;
    if (localIdentifier.length == 0) {
        return nil;
    }
    
    return [[self uploadDirectoryURLForAssetLocalIdentifier:localIdentifier] URLByAppendingPathComponent:localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:NO];
}

- (NSURL *)uploadDirectoryURLForAssetLocalIdentifier:(NSString *)identifier {
    return [NSFileManager.defaultManager.cameraUploadURL URLByAppendingPathComponent:identifier.stringByRemovingInvalidFileCharacters isDirectory:YES];
}

- (void)handleBackgroundCompletedTask:(NSURLSessionTask *)task withToken:(NSData *)token {
    NSURL *archivedURL = [self archivedUploadInfoURLForTask:task];
    BOOL isDirectory;
    if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
        AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:archivedURL.path];
        if (uploadInfo) {
            MEGALogDebug(@"Camera Upload - Resumed upload info from serialized data for asset: %@", uploadInfo)
            __block UIBackgroundTaskIdentifier backgroundUploadCompletionTask = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"completeUploadTaskBackgroundTask" expirationHandler:^{
                [UIApplication.sharedApplication endBackgroundTask:backgroundUploadCompletionTask];
                backgroundUploadCompletionTask = UIBackgroundTaskInvalid;
            }];
            
            [self.uploadCoordinator completeUploadWithInfo:uploadInfo uploadToken:token success:^(MEGANode * _Nonnull node) {
                [self finishTask:task withStatus:uploadStatusDone];
                [UIApplication.sharedApplication endBackgroundTask:backgroundUploadCompletionTask];
                backgroundUploadCompletionTask = UIBackgroundTaskInvalid;
            } failure:^(MEGAError * _Nonnull error) {
                MEGALogError(@"Camera Upload - Error when to put node for asset: %@", task.taskDescription);
                [self finishTask:task withStatus:uploadStatusFailed];
                [UIApplication.sharedApplication endBackgroundTask:backgroundUploadCompletionTask];
                backgroundUploadCompletionTask = UIBackgroundTaskInvalid;
            }];
        } else {
            MEGALogError(@"Camera Upload - Error when to unarchive upload info for asset: %@", task.taskDescription);
            [self finishTask:task withStatus:uploadStatusFailed];
        }
    } else {
        MEGALogError(@"Camera Upload - Session task completes without any handler: %@", task.taskDescription);
        [self finishTask:task withStatus:uploadStatusFailed];
    }
}

- (void)finishTask:(NSURLSessionTask *)task withStatus:(NSString *)status {
    NSString *localIdentifier = task.taskDescription;
    if (localIdentifier.length == 0) {
        return;
    }
    
    [CameraUploadRecordManager.shared updateStatus:status forLocalIdentifier:localIdentifier error:nil];
    NSURL *uploadDirectory = [self uploadDirectoryURLForAssetLocalIdentifier:localIdentifier];
    [NSFileManager.defaultManager removeItemAtURL:uploadDirectory error:nil];
    MEGALogDebug(@"Camera Upload - Session task %@ finished with status: %@", task.taskDescription, status);
}

@end
