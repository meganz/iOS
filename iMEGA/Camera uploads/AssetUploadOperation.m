
#import "AssetUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadFile.h"
@import Photos;

@interface AssetUploadOperation () <MEGARequestDelegate>

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) AssetUploadFile *uploadFile;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUploader;

@end

@implementation AssetUploadOperation

- (instancetype)initWithAsset:(PHAsset *)asset {
    self = [super init];
    if (self) {
        _asset = asset;
    }
    
    return self;
}

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier {
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
    return [self initWithAsset:asset];
}

- (void)start {
    [super start];
    
    if (self.asset == nil) {
        // TODO: delete the local upload record
        [self finishOperation];
        return;
    }
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }
        
        if (imageData) {
            [self processImageData:imageData];
        } else {
            // TODO: make the job as failed or not started
            [self finishOperation];
        }
    }];
}

- (void)processImageData:(NSData *)imageData {
    NSData *JPEGData = UIImageJPEGRepresentation([UIImage imageWithData:imageData], 1.0);
    NSString *fileName = [[NSString mnz_fileNameWithDate:self.asset.creationDate] stringByAppendingPathExtension:@"jpg"];
    NSURL *fileURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:fileName];
    self.uploadFile = [[AssetUploadFile alloc] initWithName:fileName URL:fileURL];
    if ([JPEGData writeToURL:fileURL atomically:YES]) {
        [self processUploadFile];
    } else {
        // TODO: make the job as failed or not started
        [self finishOperation];
    }
}

- (void)processUploadFile {
    self.mediaUploader = [[MEGASdkManager sharedMEGASdk] prepareBackgroundMediaUploadWithDelegate:self];
    NSString *urlSuffix;
    if ([self.mediaUploader encryptFileAtPath:[self.uploadFile.fileURL path] outputFilePath:[self.uploadFile.encryptedURL path] urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"url suffix %@", urlSuffix);
        self.uploadFile.uploadURLStringSuffix = urlSuffix;
        [self.mediaUploader requestUploadURLString];
    } else {
        MEGALogError(@"file encryption failed for asset: %@", self.asset);
        [self finishOperation];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        MEGALogError(@"camera upload sdk request failed");
        // TODO: update local record status
        [self finishOperation];
    } else {
        self.uploadFile.uploadURLString = [self.mediaUploader uploadURLString];
        MEGALogDebug(@"upload url string: %@", self.uploadFile.uploadURLString);
        [self startUploading];
    }
}

#pragma mark - transfer tasks

- (void)startUploading {
    if (self.uploadFile.uploadURL == nil) {
        // TODO: update status
        [self finishOperation];
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.uploadFile.uploadURL];
    request.HTTPMethod = @"POST";
    NSURLSessionUploadTask *uploadTask = [[TransferSessionManager shared].photoSession uploadTaskWithRequest:request fromFile:self.uploadFile.encryptedURL];
    [uploadTask resume];
    
    [self finishOperation];
}

@end
