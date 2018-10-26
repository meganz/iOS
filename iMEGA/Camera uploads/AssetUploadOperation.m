
#import "AssetUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "AssetUploadRecordCoreDataManager.h"
#import "CameraUploadManager.h"
#import "AssetUploadCoordinator.h"
@import Photos;

static NSString * const cameraUploadBackgroundTaskName = @"nz.mega.cameraUpload";
static NSString * const archiveUploadInfoBackgroundTaskName = @"nz.mega.archiveCameraAssetUploadInfo";


@interface AssetUploadOperation () <MEGARequestDelegate>

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUploader;
@property (strong, nonatomic) MEGANode *cameraUploadNode;
@property (nonatomic) UIBackgroundTaskIdentifier uploadTaskIdentifier;
@property (strong, nonatomic) AssetUploadCoordinator *coordinator;

@end

@implementation AssetUploadOperation

- (instancetype)initWithAsset:(PHAsset *)asset cameraUploadNode:(MEGANode *)node {
    self = [super init];
    if (self) {
        _asset = asset;
        _cameraUploadNode = node;
        _uploadInfo = [[AssetUploadInfo alloc] init];
        _uploadInfo.parentHandle = node.handle;
        _coordinator = [[AssetUploadCoordinator alloc] init];
    }
    
    return self;
}

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier cameraUploadNode:(MEGANode *)node {
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
    return [self initWithAsset:asset cameraUploadNode:node];
}

- (void)start {
    [super start];
    
    if (self.asset == nil) {
        [[AssetUploadRecordCoreDataManager shared] deleteRecordsByLocalIdentifiers:@[self.asset.localIdentifier] error:nil];
        [self finishOperation];
        return;
    }

    [self beginBackgroundTask];
    
    MEGALogDebug(@"Camera Upload - Upload operation starts for asset: %@", self.asset);
    [[AssetUploadRecordCoreDataManager shared] updateStatus:uploadStatusProcessing forLocalIdentifier:self.asset.localIdentifier error:nil];
    
    [self requestImageData];
}

- (void)beginBackgroundTask {
    self.uploadTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:cameraUploadBackgroundTaskName expirationHandler:^{
        MOAssetUploadRecord *record = [AssetUploadRecordCoreDataManager.shared fetchAssetUploadRecordByLocalIdentifier:self.asset.localIdentifier error:nil];
        MEGALogDebug(@"Camera Upload - upload operation background task expired with asset: %@", self.asset);
        if ([record.status isEqualToString:uploadStatusProcessing]) {
            [self finishOperation];
        } else {
            [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:NO];
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
            [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
            return;
        }
        
        if (imageData) {
            [self processImageData:imageData];
        } else {
            [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processImageData:(NSData *)imageData {
    self.uploadInfo.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.asset.modificationDate];
    MEGANode *existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.originalFingerprint parent:self.cameraUploadNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }
    
    NSData *JPEGData = UIImageJPEGRepresentation([UIImage imageWithData:imageData], 1.0);
    self.uploadInfo.fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:JPEGData modificationTime:self.asset.modificationDate];
    existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.fingerprint parent:self.cameraUploadNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }

    NSURL *assetURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:self.asset.localIdentifier isDirectory:YES];
    if(![[NSFileManager defaultManager] createDirectoryAtURL:assetURL withIntermediateDirectories:YES attributes:nil error:nil]) {
        [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    self.uploadInfo.directoryURL = assetURL;
    self.uploadInfo.fileName = [[NSString mnz_fileNameWithDate:self.asset.creationDate] stringByAppendingPathExtension:@"jpg"];
    if ([JPEGData writeToURL:self.uploadInfo.fileURL atomically:YES]) {
        self.uploadInfo.fileSize = [JPEGData length];
        [self processUploadFile];
    } else {
        [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)processUploadFile {
    self.uploadInfo.mediaUpload = [[MEGASdkManager sharedMEGASdk] backgroundMediaUpload];
    NSString *urlSuffix;
    if ([self.uploadInfo.mediaUpload encryptFileAtPath:self.uploadInfo.fileURL.path startPosition:0 length:self.uploadInfo.fileSize outputFilePath:self.uploadInfo.encryptedURL.path urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"Camera Upload - Upload file encrypted with url suffix: %@", urlSuffix);
        self.uploadInfo.uploadURLStringSuffix = urlSuffix;
        [[MEGASdkManager sharedMEGASdk] requestBackgroundUploadURLWithFileSize:self.uploadInfo.fileSize mediaUpload:self.uploadInfo.mediaUpload delegate:self];
        [[MEGASdkManager sharedMEGASdk] createThumbnail:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.thumbnailURL.path];
        [[MEGASdkManager sharedMEGASdk] createPreview:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.previewURL.path];
    } else {
        MEGALogError(@"Camera Upload - File encryption failed for asset: %@", self.asset);
        [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)processExistingNode:(MEGANode *)node {
    if (node.parentHandle != self.cameraUploadNode.handle) {
        [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.cameraUploadNode];
    }
    
    [self finishOperationWithStatus:uploadStatusDone shouldUploadNextAsset:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        MEGALogError(@"Camera Upload - Upload requests upload url failed with error type: %ld", error.type);
        [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
    } else {
        self.uploadInfo.uploadURLString = [self.uploadInfo.mediaUpload uploadURLString];
        if (self.uploadInfo.uploadURL) {
            [self uploadFileToServer];
        } else {
            [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
        }
    }
}

#pragma mark - upload task

- (void)uploadFileToServer {
    MEGALogDebug(@"Camera Upload - Uploading file to server for asset: %@ to server: %@", self.asset, self.uploadInfo.uploadURL);
    
    NSURLSessionUploadTask *uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:self.uploadInfo.uploadURL fromFile:self.uploadInfo.encryptedURL completion:^(NSData * _Nullable token, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"Camera Upload - Error when to upload asset %@ %@", self.asset, error);
            [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
        } else {
//            [self.coordinator completeUploadWithInfo:self.uploadInfo uploadToken:token success:^(MEGANode * _Nonnull node) {
//                [self finishOperationWithStatus:uploadStatusDone shouldUploadNextAsset:YES];
//            } failure:^(MEGAError * _Nonnull error) {
//                [self finishOperationWithStatus:uploadStatusFailed shouldUploadNextAsset:YES];
//            }];
            
            [self archiveUploadInfoDataForBackgroundTransfer];
            
            NSURL *archivedURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:self.asset.localIdentifier isDirectory:NO];
            BOOL isDirectory = false;
            if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
                AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:archivedURL.path];
                NSLog(@"%@", uploadInfo);
            }
        }
    }];
    
    uploadTask.taskDescription = self.asset.localIdentifier;
    [uploadTask resume];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveUploadInfoDataForBackgroundTransfer) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - archive upload info

- (void)archiveUploadInfoDataForBackgroundTransfer {
    NSURL *archivedURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:self.asset.localIdentifier isDirectory:NO];
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
}

#pragma mark - finish operation

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset {
    MEGALogDebug(@"Camera Upload - Upload finishes for asset: %@, with status: %@", self.asset, status);
    
    [[NSFileManager defaultManager] removeItemAtURL:self.uploadInfo.directoryURL error:nil];
    
    [[AssetUploadRecordCoreDataManager shared] updateStatus:status forLocalIdentifier:self.asset.localIdentifier error:nil];
    
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
