
#import "CameraUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"
@import Photos;

@interface CameraUploadOperation ()

@end

@implementation CameraUploadOperation

#pragma mark - initializers

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo {
    self = [super init];
    if (self) {
        _uploadInfo = uploadInfo;
    }
    
    return self;
}

#pragma mark - properties

- (NSString *)cameraUploadBackgroundTaskName {
    return @"nz.mega.cameraUpload";
}

- (CameraUploadCoordinator *)uploadCoordinator {
    if (_uploadCoordinator == nil) {
        _uploadCoordinator = [[CameraUploadCoordinator alloc] init];
    }
    
    return _uploadCoordinator;
}

- (MEGASdk *)attributesDataSDK {
    if (_attributesDataSDK == nil) {
        NSString *basePath = [[[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject] path];
        _attributesDataSDK = [[MEGASdk alloc] initWithAppKey:@"EVtjzb7R"
                                                   userAgent:[NSString stringWithFormat:@"%@/%@", @"MEGAiOS", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                                    basePath:basePath];
    }
    
    return _attributesDataSDK;
}

#pragma mark - start operation

- (void)start {
    [super start];
    
    if (self.uploadInfo.asset == nil) {
        [[CameraUploadRecordManager shared] deleteRecordsByLocalIdentifiers:@[self.uploadInfo.asset.localIdentifier] error:nil];
        [self finishOperation];
        MEGALogDebug(@"[Camera Upload] %@ finishes with empty asset", self);
        return;
    }

    [self beginBackgroundTask];
    
    MEGALogDebug(@"[Camera Upload] %@ starts processing", self);
    [[CameraUploadRecordManager shared] updateStatus:UploadStatusProcessing forLocalIdentifier:self.uploadInfo.asset.localIdentifier error:nil];
}

- (void)beginBackgroundTask {
    self.uploadTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:self.cameraUploadBackgroundTaskName expirationHandler:^{
        MOAssetUploadRecord *record = [CameraUploadRecordManager.shared fetchAssetUploadRecordByLocalIdentifier:self.uploadInfo.asset.localIdentifier error:nil];
        MEGALogDebug(@"[Camera Upload] %@ background task expired", self);
        if ([record.status isEqualToString:UploadStatusUploading]) {
            [self finishOperation];
            MEGALogDebug(@"[Camera Upload] %@ finishes while uploading", self);
        } else {
            [self cancel];
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:NO];
        }
        
        [UIApplication.sharedApplication endBackgroundTask:self.uploadTaskIdentifier];
        self.uploadTaskIdentifier = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - data processing

- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node {
    if (node == nil) {
        return;
    }
    
    if (node.parentHandle != self.uploadInfo.parentNode.handle) {
        [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.uploadInfo.parentNode];
    }
}

- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint {
    MEGANode *matchingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:fingerprint];
    if (matchingNode == nil) {
        MEGANodeList *nodeList = [MEGASdkManager.sharedMEGASdk nodesForOriginalFingerprint:fingerprint];
        if (nodeList.size.integerValue > 0) {
            matchingNode = [self firstNodeInNodeList:nodeList hasParentNode:self.uploadInfo.parentNode];
            if (matchingNode == nil) {
                matchingNode = [nodeList nodeAtIndex:0];
            }
        }
    }
    
    return matchingNode;
}

- (MEGANode *)firstNodeInNodeList:(MEGANodeList *)nodeList hasParentNode:(MEGANode *)parent {
    for (NSInteger i = 0; i < nodeList.size.integerValue; i++) {
        MEGANode *node = [nodeList nodeAtIndex:i];
        if (node.parentHandle == parent.handle) {
            return node;
        }
    }
    
    return nil;
}

- (NSURL *)URLForAssetFolder {
    NSURL *assetDirectoryURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:self.uploadInfo.asset.localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:YES];
    
    [NSFileManager.defaultManager removeItemIfExistsAtURL:assetDirectoryURL];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:assetDirectoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    return assetDirectoryURL;
}

- (void)createThumbnailAndPreviewFiles {
    [self.attributesDataSDK createThumbnail:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.thumbnailURL.path];
    [self.attributesDataSDK createPreview:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.previewURL.path];
    self.attributesDataSDK = nil;
}

#pragma mark - upload task

- (void)uploadFileToServer {
    MEGALogDebug(@"[Camera Upload] %@ starts uploading file to server: %@", self, self.uploadInfo.uploadURL);
    
    NSURLSessionUploadTask *uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:self.uploadInfo.uploadURL fromFile:self.uploadInfo.encryptedURL completion:^(NSData * _Nullable token, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] %@ got error when to upload: %@", self, error);
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        } else {
            [self.uploadCoordinator completeUploadWithInfo:self.uploadInfo uploadToken:token success:^(MEGANode * _Nonnull node) {
                [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
            } failure:^(MEGAError * _Nonnull error) {
                [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
            }];
        }
    }];
    
    uploadTask.taskDescription = self.uploadInfo.asset.localIdentifier;
    [uploadTask resume];
    
    [CameraUploadRecordManager.shared updateStatus:UploadStatusUploading forLocalIdentifier:self.uploadInfo.asset.localIdentifier error:nil];
    
    [self archiveUploadInfoDataIfNeeded];
}

#pragma mark - archive upload info

- (void)archiveUploadInfoDataIfNeeded {
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveUploadInfoDataForBackgroundTransfer) name:UIApplicationDidEnterBackgroundNotification object:nil];
    } else {
        [self archiveUploadInfoDataForBackgroundTransfer];
    }
}

- (void)archiveUploadInfoDataForBackgroundTransfer {
    MEGALogDebug(@"[Camera Upload] %@ start archiving upload info", self);
    NSURL *archivedURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:self.uploadInfo.asset.localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:NO];
    [NSKeyedArchiver archiveRootObject:self.uploadInfo toFile:archivedURL.path];
}

#pragma mark - finish operation

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset {
    MEGALogDebug(@"[Camera Upload] %@ finishes with status: %@", self, status);
    
    [[NSFileManager defaultManager] removeItemAtURL:self.uploadInfo.directoryURL error:nil];
    
    [[CameraUploadRecordManager shared] updateStatus:status forLocalIdentifier:self.uploadInfo.asset.localIdentifier error:nil];
    
    [self finishOperation];
    
    if (self.uploadTaskIdentifier != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.uploadTaskIdentifier];
        self.uploadTaskIdentifier = UIBackgroundTaskInvalid;
    }
    
    if (uploadNextAsset) {
        [[CameraUploadManager shared] uploadNextForAsset:self.uploadInfo.asset];
    }
}

@end
