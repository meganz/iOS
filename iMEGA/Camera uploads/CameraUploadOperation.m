
#import "CameraUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadCoordinator.h"
#import "CameraUploadRequestDelegate.h"
@import Photos;

static NSString * const cameraUploadBackgroundTaskName = @"nz.mega.cameraUpload";
static NSString * const archiveUploadInfoBackgroundTaskName = @"nz.mega.archiveCameraAssetUploadInfo";


@interface CameraUploadOperation ()

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUploader;
@property (strong, nonatomic) MEGANode *cameraUploadNode;
@property (nonatomic) UIBackgroundTaskIdentifier uploadTaskIdentifier;
@property (strong, nonatomic) CameraUploadCoordinator *uploadCoordinator;
@property (strong, nonatomic) MEGASdk *attributesDataSDK;

@end

@implementation CameraUploadOperation

#pragma mark - initializers

- (instancetype)initWithAsset:(PHAsset *)asset cameraUploadNode:(MEGANode *)node {
    self = [super init];
    if (self) {
        _asset = asset;
        _cameraUploadNode = node;
    }
    
    return self;
}

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier cameraUploadNode:(MEGANode *)node {
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
    return [self initWithAsset:asset cameraUploadNode:node];
}

- (void)dealloc {
    MEGALogDebug(@"operation gets deallocated");
}

#pragma mark - properties

- (AssetUploadInfo *)uploadInfo {
    if (_uploadInfo == nil) {
        _uploadInfo = [[AssetUploadInfo alloc] init];
        _uploadInfo.parentHandle = self.cameraUploadNode.handle;
        _uploadInfo.localIdentifier = self.asset.localIdentifier;
    }
    
    return _uploadInfo;
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
    
    if (self.asset == nil) {
        [[CameraUploadRecordManager shared] deleteRecordsByLocalIdentifiers:@[self.asset.localIdentifier] error:nil];
        [self finishOperation];
        MEGALogDebug(@"[Camera Upload] Upload operation finishes with empty asset");
        return;
    }

    [self beginBackgroundTask];
    
    MEGALogDebug(@"[Camera Upload] Upload operation starts for asset: %@", self.asset.localIdentifier);
    [[CameraUploadRecordManager shared] updateStatus:UploadStatusProcessing forLocalIdentifier:self.asset.localIdentifier error:nil];
    
    [self requestImageData];
}

- (void)beginBackgroundTask {
    self.uploadTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:cameraUploadBackgroundTaskName expirationHandler:^{
        MOAssetUploadRecord *record = [CameraUploadRecordManager.shared fetchAssetUploadRecordByLocalIdentifier:self.asset.localIdentifier error:nil];
        MEGALogDebug(@"[Camera Upload] upload operation background task expired with asset: %@", self.asset.localIdentifier);
        if ([record.status isEqualToString:UploadStatusUploading]) {
            [self finishOperation];
            MEGALogDebug(@"[Camera Upload] upload operation finishes while asset: %@ is uploading", self.asset.localIdentifier);
        } else {
            [self cancel];
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:NO];
        }
        
        [UIApplication.sharedApplication endBackgroundTask:self.uploadTaskIdentifier];
        self.uploadTaskIdentifier = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - data processing

- (void)requestImageData {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (self.isCancelled) {
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
            return;
        }
        
        if (imageData) {
            [self processImageData:imageData];
        } else {
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processImageData:(NSData *)imageData {
    self.uploadInfo.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.asset.creationDate];
    MEGANode *existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.originalFingerprint parent:self.cameraUploadNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }
    
    NSData *JPEGData = UIImageJPEGRepresentation([UIImage imageWithData:imageData], 1.0);
    self.uploadInfo.fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:JPEGData modificationTime:self.asset.creationDate];
    existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.fingerprint parent:self.cameraUploadNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }

    NSURL *assetDirectoryURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:self.asset.localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:YES];
    if(![[NSFileManager defaultManager] createDirectoryAtURL:assetDirectoryURL withIntermediateDirectories:YES attributes:nil error:nil]) {
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    self.uploadInfo.directoryURL = assetDirectoryURL;
    self.uploadInfo.fileName = [[NSString mnz_fileNameWithDate:self.asset.creationDate] stringByAppendingPathExtension:@"jpg"];
    if ([JPEGData writeToURL:self.uploadInfo.fileURL atomically:YES]) {
        self.uploadInfo.fileSize = [JPEGData length];
        [self processUploadFile];
    } else {
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)processUploadFile {
    self.uploadInfo.mediaUpload = [[MEGASdkManager sharedMEGASdk] backgroundMediaUpload];
    NSString *urlSuffix;
    if ([self.uploadInfo.mediaUpload encryptFileAtPath:self.uploadInfo.fileURL.path startPosition:0 length:self.uploadInfo.fileSize outputFilePath:self.uploadInfo.encryptedURL.path urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"[Camera Upload] Upload file encrypted with url suffix: %@", urlSuffix);
        
        [self.attributesDataSDK createThumbnail:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.thumbnailURL.path];
        [self.attributesDataSDK createPreview:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.previewURL.path];
        self.attributesDataSDK = nil;
        
        self.uploadInfo.uploadURLStringSuffix = urlSuffix;
        [[MEGASdkManager sharedMEGASdk] requestBackgroundUploadURLWithFileSize:self.uploadInfo.fileSize mediaUpload:self.uploadInfo.mediaUpload delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload requests upload url failed with error type: %ld", error.type);
                [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
            } else {
                self.uploadInfo.uploadURLString = [self.uploadInfo.mediaUpload uploadURLString];
                if (self.uploadInfo.uploadURL) {
                    [self uploadFileToServer];
                } else {
                    [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
                }
            }
        }]];
    } else {
        MEGALogError(@"[Camera Upload] File encryption failed for asset: %@", self.asset.localIdentifier);
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)processExistingNode:(MEGANode *)node {
    MEGALogDebug(@"[Camera Upload] Process existing node: %llu", node.handle);
    
    if (node.parentHandle != self.cameraUploadNode.handle) {
        [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.cameraUploadNode];
    }
    
    [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
}

#pragma mark - upload task

- (void)uploadFileToServer {
    MEGALogDebug(@"[Camera Upload] Uploading file to server for asset: %@ to server: %@", self.asset.localIdentifier, self.uploadInfo.uploadURL);
    
    NSURLSessionUploadTask *uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:self.uploadInfo.uploadURL fromFile:self.uploadInfo.encryptedURL completion:^(NSData * _Nullable token, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] Error when to upload asset %@ %@", self.asset.localIdentifier, error);
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        } else {
            [self.uploadCoordinator completeUploadWithInfo:self.uploadInfo uploadToken:token success:^(MEGANode * _Nonnull node) {
                [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
            } failure:^(MEGAError * _Nonnull error) {
                [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
            }];
        }
    }];
    
    uploadTask.taskDescription = self.asset.localIdentifier;
    [uploadTask resume];
    
    [CameraUploadRecordManager.shared updateStatus:UploadStatusUploading forLocalIdentifier:self.asset.localIdentifier error:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveUploadInfoDataForBackgroundTransfer) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - archive upload info

- (void)archiveUploadInfoDataForBackgroundTransfer {
    MEGALogDebug(@"[Camera Upload] start archiving upload info for asset: %@", self.asset.localIdentifier);
    
    NSURL *archivedURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:self.asset.localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:NO];
    BOOL isDirectory;
    if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
        return;
    }
    
    __block UIBackgroundTaskIdentifier backgroundArchiveTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:archiveUploadInfoBackgroundTaskName expirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:backgroundArchiveTaskId];
        backgroundArchiveTaskId = UIBackgroundTaskInvalid;
    }];
    
    [NSKeyedArchiver archiveRootObject:self.uploadInfo toFile:archivedURL.path];
    [UIApplication.sharedApplication endBackgroundTask:backgroundArchiveTaskId];
    backgroundArchiveTaskId = UIBackgroundTaskInvalid;
    MEGALogDebug(@"[Camera Upload] finish archiving upload info for asset: %@", self.asset.localIdentifier);
}

#pragma mark - finish operation

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset {
    MEGALogDebug(@"[Camera Upload] Upload operation finishes for asset: %@, with status: %@", self.asset.localIdentifier, status);
    
    [[NSFileManager defaultManager] removeItemAtURL:self.uploadInfo.directoryURL error:nil];
    
    [[CameraUploadRecordManager shared] updateStatus:status forLocalIdentifier:self.asset.localIdentifier error:nil];
    
    [self finishOperation];
    
    if (self.uploadTaskIdentifier != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.uploadTaskIdentifier];
        self.uploadTaskIdentifier = UIBackgroundTaskInvalid;
    }
    
    if (uploadNextAsset) {
        [[CameraUploadManager shared] uploadNextPhoto];
    }
}

@end
