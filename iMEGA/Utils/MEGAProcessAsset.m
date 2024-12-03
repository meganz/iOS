#import "MEGAProcessAsset.h"

#import "ChatVideoUploadQuality.h"
#import "ChatImageUploadQuality.h"
#import "MEGAReachabilityManager.h"
#import "NSDate+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "NSString+MNZCategory.h"

@import MEGAL10nObjc;

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@import SDAVAssetExportSession;

static void *ProcessAssetProgressContext = &ProcessAssetProgressContext;

static const NSUInteger DOWNSCALE_IMAGES_PX = 2000000;
static const float BPS_LOW = 1500000.0f;
static const float BPS_MEDIUM = 3000000.0f;

@interface MEGAProcessAsset ()

@property (nonatomic, copy) PHAsset *asset;
@property (nonatomic, copy) void (^filePath)(NSString *filePath);
@property (nonatomic, copy) void (^error)(NSError *error);

@property (nonatomic, strong) NSMutableArray <PHAsset *> *assets;
@property (nonatomic, copy) void (^filePaths)(NSArray <NSString *> *filePaths);
@property (nonatomic, copy) void (^errors)(NSArray <NSError *> *errors);
@property (nonatomic, strong) NSMutableArray <NSString *> *filePathsArray;
@property (nonatomic, strong) NSMutableArray <NSError *> *errorsArray;
@property (nonatomic) double totalDuration;
@property (nonatomic) double currentProgress;   // Duration of all videos processed
@property (nonatomic) BOOL cancelExportByUser;
@property (nonatomic) BOOL exportAssetFailed;

@property (nonatomic, assign) NSUInteger retries;
@property (nonatomic, getter=toShareThroughChat) BOOL shareThroughChat;

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic) UIAlertController *alertController;
@property (nonatomic) dispatch_semaphore_t semaphore;

@property (nonatomic, copy) AVAsset *avAsset;
@property (nonatomic) UIViewController *presenter;

@end

@implementation MEGAProcessAsset

- (instancetype)initWithAsset:(PHAsset *)asset
                    presenter:(nullable UIViewController *)presenter
                     filePath:(void (^)(NSString *filePath))filePath
                        error:(void (^)(NSError *error))error {
    self = [super init];
    
    if (self) {
        _asset = asset;
        _filePath = filePath;
        _error = error;
        _retries = 0;
        _presenter = presenter;
    }
    
    return self;
}

- (instancetype)initToShareThroughChatWithAssets:(NSArray<PHAsset *> *)assets
                                       presenter:(UIViewController *)presenter
                                       filePaths:(void (^)(NSArray<NSString *> *))filePaths
                                          errors:(void (^)(NSArray<NSError *> *))errors{
    self = [super init];
    
    if (self) {
        _semaphore = dispatch_semaphore_create(0);
        _assets = [[NSMutableArray alloc] initWithArray:assets];
        _filePaths = filePaths;
        _errors = errors;
        _retries = 0;
        _filePathsArray = [[NSMutableArray alloc] init];
        _errorsArray = [[NSMutableArray alloc] init];
        _shareThroughChat = YES;
        _presenter = presenter;
        for (PHAsset *asset in assets) {
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                _totalDuration += asset.duration;
            }
        }
    }
    
    return self;
    
}

- (instancetype)initToShareThroughChatWithVideoURL:(NSURL *)videoURL
                                         presenter:(UIViewController *)presenter
                                          filePath:(void (^)(NSString *))filePath
                                             error:(void (^)(NSError *))error {
    self = [super init];
    
    if (self) {
        _avAsset = [AVAsset assetWithURL:videoURL];
        _filePath = filePath;
        _error = error;
        _retries = 0;
        _shareThroughChat = YES;
        _presenter = presenter;
        _totalDuration = CMTimeGetSeconds(self.avAsset.duration);
    }
    
    return self;
    
}

- (instancetype)initToShareThroughChatWithVideoURL:(NSURL *)videoURL
                                          filePath:(void (^)(NSString *))filePath
                                             error:(void (^)(NSError *))error
                                         presenter:(UIViewController *)presenter {
    self = [super init];
    
    if (self) {
        _avAsset = [AVAsset assetWithURL:videoURL];
        _filePath = filePath;
        _error = error;
        _retries = 0;
        _shareThroughChat = YES;
        _totalDuration = CMTimeGetSeconds(self.avAsset.duration);
        _presenter = presenter;
    }
    
    return self;
    
}

- (void)prepare {
    if (self.avAsset) {
        [self prepareAVAsset];
    } else if (self.assets) {
        for (NSUInteger i = 0; i < self.assets.count; i++) {
            PHAsset *asset = [self.assets objectAtIndex:i];
            switch (asset.mediaType) {
                case PHAssetMediaTypeImage: {
                    [self requestImageAsset:asset];
                    break;
                }
                    
                case PHAssetMediaTypeVideo: {
                    [self requestVideoAsset:asset];
                    break;
                }
                    
                default:
                    break;
            }
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.alertController dismissViewControllerAnimated:YES completion:^{
                if (self.exportAssetFailed) {
                    NSString *message = LocalizedString(@"shareExtensionUnsupportedAssets", @"Inform user that there were unsupported assets in the share extension.");
                    UIAlertController  *videoExportFailedController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
                    [videoExportFailedController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDestructive handler:nil]];
                    [UIApplication.mnz_presentingViewController presentViewController:videoExportFailedController animated:YES completion:nil];
                }
            }];
        });
        if (self.filePaths && self.filePathsArray.count) {
            self.filePaths(self.filePathsArray);
        }
        if (self.errors && self.errorsArray.count) {
            self.errors(self.errorsArray);
        }
    } else {
        switch (self.asset.mediaType) {
            case PHAssetMediaTypeImage:
                [self requestImageAsset:self.asset];
                break;
                
            case PHAssetMediaTypeVideo:
                [self requestVideoAsset:self.asset];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - Private

- (void)requestImageAsset:(PHAsset *)asset {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    if (self.retries < 10) {
        options.version = PHImageRequestOptionsVersionCurrent;
    } else {
        options.version = PHImageRequestOptionsVersionOriginal;
    }
    
    if (self.shareThroughChat) {
        ChatImageUploadQuality imageQuality = [NSUserDefaults.standardUserDefaults integerForKey:@"chatImageQuality"];
        
        switch (imageQuality) {
            case ChatImageUploadQualityAuto:
                if (!MEGAReachabilityManager.isReachableViaWiFi) {
                    [self compressedImageAsset:asset options:options];
                } else {
                    [self requestImageForAsset:asset options:options];
                }
                break;
                
            case ChatImageUploadQualityOriginal:
                [self requestImageForAsset:asset options:options];
                break;
                
            case ChatImageUploadQualityOptimised:
                [self compressedImageAsset:asset options:options];
                break;
                
            default:
                [self requestImageForAsset:asset options:options];
                break;
        }
    } else {
        [self requestImageForAsset:asset options:options];
    }
}

- (void)compressedImageAsset:(PHAsset *)asset options:(PHImageRequestOptions *)options {
    NSUInteger totalPixels = asset.pixelWidth * asset.pixelHeight;
    float factor = MIN(sqrtf((float)DOWNSCALE_IMAGES_PX / totalPixels), 1);
    if (factor >= 1) {
        [self requestImageForAsset:asset options:options];
    } else {
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        [PHImageManager.defaultManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth * factor, asset.pixelHeight * factor) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                NSData *imageData = UIImageJPEGRepresentation(result, 0.75);
                [self proccessImageData:imageData asset:asset withInfo:info];
            } else {
                NSError *error = [info objectForKey:@"PHImageErrorKey"];
                MEGALogError(@"[PA] Request image data for asset: %@ failed with error: %@", asset, error);
                if (self.retries < 20) {
                    self.retries++;
                    [self requestImageAsset:asset];
                } else {
                    if (self.error) {
                        MEGALogDebug(@"[PA] Max attempts reached");
                        self.error(error);
                    }
                    if (self.errors) {
                        MEGALogDebug(@"[PA] Max attempts reached");
                        [self.errorsArray addObject:error];
                        dispatch_semaphore_signal(self.semaphore);
                    }
                }
            }
        }];
    }
}

// Request image and don't downscale it
- (void)requestImageForAsset:(PHAsset *)asset options:(PHImageRequestOptions *)options {
    [[PHImageManager defaultManager]
     requestImageDataAndOrientationForAsset:asset
     options:options
     resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
        NSData *data;
        if (self.shareThroughChat && [dataUTI isEqualToString:@"public.heic"]) {
            UIImage *image = [UIImage imageWithData:imageData];
            data = UIImageJPEGRepresentation(image, 0.75);
        } else {
            data = imageData;
        }
        
        [self proccessImageData:data asset:asset withInfo:info];
    }];
}

- (void)requestVideoAsset:(PHAsset *)asset {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionCurrent;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager]
     requestAVAssetForVideo:asset
     options:options resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
        if (avAsset) {
            if ([avAsset isKindOfClass:[AVURLAsset class]]) {
                NSURL *avassetUrl = [(AVURLAsset *)avAsset URL];
                NSDictionary *fileAtributes = [[NSFileManager defaultManager] attributesOfItemAtPath:avassetUrl.path error:nil];
                __block NSString *filePath = [self filePathWithInfo:info asset:asset];
                [NSFileManager.defaultManager mnz_removeItemAtPath:filePath];
                long long fileSize = [[fileAtributes objectForKey:NSFileSize] longLongValue];
                
                if ([self hasFreeSpaceOnDiskForWriteFile:fileSize]) {
                    ChatVideoUploadQuality videoQuality = [self chatVideoUploadQuality];
                    
                    AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
                    
                    BOOL shouldEncodeVideo = [self shouldEncodeVideoTrack:videoTrack videoQuality:videoQuality extension:filePath.pathExtension];
                    
                    if (shouldEncodeVideo) {
                        SDAVAssetExportSession *encoder = [self configureEncoderWithAVAsset:avAsset videoQuality:videoQuality filePath:filePath];
                        [self downscaleVideoAsset:asset encoder:encoder];
                    } else {
                        NSError *error;
                        self.currentProgress += asset.duration;
                        if ([[NSFileManager defaultManager] copyItemAtPath:avassetUrl.path toPath:filePath error:&error]) {
                            if (asset.creationDate != nil) {
                                NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:asset.creationDate forKey:NSFileModificationDate];
                                if (![[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:filePath error:&error]) {
                                    MEGALogError(@"[PA] Set attributes failed with error: %@", error);
                                }
                            }
                            
                            if (self.filePath) {
                                filePath = filePath.mnz_relativeLocalPath;
                                self.filePath(filePath);
                            }
                            if (self.filePaths) {
                                filePath = filePath.mnz_relativeLocalPath;
                                [self.filePathsArray addObject:filePath];
                                dispatch_semaphore_signal(self.semaphore);
                            }
                        } else {
                            MEGALogError(@"[PA] Copy item at path failed with error: %@", error);
                            if (self.error) {
                                self.error(error);
                            }
                            if (self.errors) {
                                MEGALogDebug(@"[PA] Max attempts reached");
                                [self.errorsArray addObject:error];
                                dispatch_semaphore_signal(self.semaphore);
                            }
                        }
                    }
                }
            } else if ([avAsset isKindOfClass:[AVComposition class]]) {
                float realDuration = [self realDurationForAVAsset:avAsset];
                self.totalDuration = self.totalDuration - asset.duration + realDuration;
                NSString *filePath = [self filePathWithInfo:info asset:asset];
                [NSFileManager.defaultManager mnz_removeItemAtPath:filePath];
                ChatVideoUploadQuality videoQuality = [self chatVideoUploadQuality];
                
                SDAVAssetExportSession *encoder = [self configureEncoderWithAVAsset:avAsset videoQuality:videoQuality filePath:filePath];
                [self downscaleVideoAsset:asset encoder:encoder];
                
            }
        } else {
            NSError *error = [info objectForKey:@"PHImageErrorKey"];
            MEGALogError(@"[PA] Request AVAsset %@ failed with error: %@", asset, error);
            if (self.retries < 10) {
                self.retries++;
                [self requestVideoAsset:asset];
            } else {
                if (self.error) {
                    MEGALogDebug(@"[PA] Max attempts reached");
                    self.error(error);
                }
                if (self.errors) {
                    MEGALogDebug(@"[PA] Max attempts reached");
                    [self.errorsArray addObject:error];
                    dispatch_semaphore_signal(self.semaphore);
                }
            }
        }
    }];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context == ProcessAssetProgressContext) {
        NSNumber *newProgress = [change objectForKey:NSKeyValueChangeNewKey];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            double progress = (self.currentProgress + newProgress.floatValue) / self.totalDuration;
            if (progress > self.progressView.progress) {
                self.progressView.progress = progress;
            }
        });
    }
}

- (void)prepareAVAsset {
    NSURL *avassetUrl = [(AVURLAsset *)self.avAsset URL];
    __block NSString *filePath = [[avassetUrl.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"];
    NSDictionary *fileAtributes = [[NSFileManager defaultManager] attributesOfItemAtPath:avassetUrl.path error:nil];
    [NSFileManager.defaultManager mnz_removeItemAtPath:filePath];
    long long fileSize = [[fileAtributes objectForKey:NSFileSize] longLongValue];
    
    if ([self hasFreeSpaceOnDiskForWriteFile:fileSize]) {
        ChatVideoUploadQuality videoQuality = [self chatVideoUploadQuality];
        
        AVAssetTrack *videoTrack = [self.avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        BOOL shouldEncodeVideo = [self shouldEncodeVideoTrack:videoTrack videoQuality:videoQuality extension:avassetUrl.pathExtension];
        
        if (shouldEncodeVideo) {
            SDAVAssetExportSession *encoder = [self configureEncoderWithAVAsset:self.avAsset videoQuality:videoQuality filePath:filePath];
            
            if (!self.alertController) {
                NSString *title = [LocalizedString(@"preparing...", @"Label for the status of a transfer when is being preparing - (String as short as possible.") stringByAppendingString:@"\n"];
                self.alertController = [UIAlertController alertControllerWithTitle:title message:@"\n" preferredStyle:UIAlertControllerStyleAlert];
                [self.alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    MEGALogDebug(@"[PA] User cancelled the export session");
                    [encoder cancelExport];
                    NSDictionary *dict = @{NSLocalizedDescriptionKey:@"User cancels export"};
                    NSError *error = [NSError errorWithDomain:MEGAProcessAssetErrorDomain code:-3 userInfo:dict];
                    if (self.error) {
                        self.error(error);
                    }
                }]];
            }
            
            MEGALogDebug(@"[PA] Export session started");
            [encoder exportAsynchronouslyWithCompletionHandler:^{
                if (encoder.status == AVAssetExportSessionStatusCompleted) {
                    MEGALogDebug(@"[PA] Export session finished");
                    self.currentProgress += CMTimeGetSeconds(self.avAsset.duration);
                    if (self.filePath) {
                        if (self.presenter) {
                            self.filePath(filePath);
                        } else {
                            filePath = encoder.outputURL.path.mnz_relativeLocalPath;
                            self.filePath(filePath);
                        }
                    }
                }
                else if (encoder.status == AVAssetExportSessionStatusCancelled) {
                    MEGALogDebug(@"[PA] Export session cancelled");
                }
                else {
                    MEGALogDebug(@"[PA] Export session failed with error: %@ (%ld)", encoder.error.localizedDescription, (long)encoder.error.code);
                }
                [encoder removeObserver:self forKeyPath:@"progress" context:ProcessAssetProgressContext];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.alertController dismissViewControllerAnimated:YES completion:nil];
                });
            }];
            if (UIApplication.mnz_presentingViewController != self.alertController) {
                if (self.presenter) {
                    [self.presenter presentViewController:self.alertController animated:YES completion:^{
                        [self addProgressViewToAlertController];
                    }];
                } else {
                    [UIApplication.mnz_presentingViewController.presentingViewController presentViewController:self.alertController animated:YES completion:^{
                        [self addProgressViewToAlertController];
                    }];
                }
            }
        } else {
            self.currentProgress += CMTimeGetSeconds(self.avAsset.duration);
            if (self.filePath) {
                filePath = avassetUrl.path.mnz_relativeLocalPath;
                self.filePath(filePath);
            }
        }
    }
}

- (BOOL)hasFreeSpaceOnDiskForWriteFile:(long long)fileSize {
    uint64_t freeSpace = NSFileManager.defaultManager.mnz_fileSystemFreeSize;
    
    if (fileSize > freeSpace) {
        NSDictionary *dict = @{NSLocalizedDescriptionKey:LocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")};
        NSError *error = [NSError errorWithDomain:MEGAProcessAssetErrorDomain code:-2 userInfo:dict];
        if (self.error) {
            self.error(error);
        }
        if (self.errors) {
            [self.errorsArray addObject:error];
            dispatch_semaphore_signal(self.semaphore);
        }
        return NO;
    }
    return YES;
}

- (NSString *)filePathWithInfo:(NSDictionary *)info asset:(PHAsset *)asset {
    MEGALogDebug(@"[PA] Asset %@\n%@", asset, info);
    NSString *name;
    
    if (self.originalName) {
        NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
        for (PHAssetResource *assetResource in assetResources) {
            if (asset.mediaType == PHAssetMediaTypeImage && (assetResource.type == PHAssetResourceTypePhoto || assetResource.type == PHAssetResourceTypeAlternatePhoto || assetResource.type == PHAssetResourceTypeFullSizePhoto || assetResource.type == PHAssetResourceTypeAdjustmentBasePhoto)) {
                name = assetResource.originalFilename;
                break;
            } else if (asset.mediaType == PHAssetMediaTypeVideo && (assetResource.type == PHAssetResourceTypeVideo || assetResource.type == PHAssetResourceTypeFullSizeVideo)) {
                name = assetResource.originalFilename;
                break;
            }
        }
        
        if (self.shareThroughChat && [name.pathExtension.lowercaseString isEqualToString:@"heic"]) {
            name = [[name stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
        } else {
            name = [FileExtensionOCWrapper fileNameWithLowercaseExtensionFrom:name];
        }
        if (!name) {
            NSString *extension = [self extensionWithInfo:info asset:asset];
            name = [[asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByAppendingPathExtension:extension];
        }
    } else {
        NSString *extension = [self extensionWithInfo:info asset:asset];
        name = [asset.creationDate.mnz_formattedDefaultNameForMedia stringByAppendingPathExtension:extension];
    }
    
    NSString *filePath = [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:name];
    return filePath;
}

- (NSString *)extensionWithInfo:(NSDictionary *)info asset:(PHAsset *)asset {
    if (self.shareThroughChat && asset.mediaType == PHAssetMediaTypeImage) {
        return @"jpg";
    }
    
    return [asset mnz_fileExtensionFromAssetInfo:info uniformTypeIdentifier:nil];
}

- (void)proccessImageData:(NSData *)imageData asset:(PHAsset *)asset withInfo:(NSDictionary *)info {
    if (imageData) {
        NSString *filePath = [self filePathWithInfo:info asset:asset];
        [NSFileManager.defaultManager mnz_removeItemAtPath:filePath];
        long long imageSize = imageData.length;
        if ([self hasFreeSpaceOnDiskForWriteFile:imageSize]) {
            NSError *error;
            if ([imageData writeToFile:filePath options:NSDataWritingFileProtectionNone error:&error]) {
                if (asset.creationDate != nil) {
                    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:asset.creationDate forKey:NSFileModificationDate];
                    if (![[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:filePath error:&error]) {
                        MEGALogError(@"[PA] Set attributes failed with error: %@", error);
                    }
                }
                
                if (self.filePath) {
                    filePath = filePath.mnz_relativeLocalPath;
                    self.filePath(filePath);
                }
                if (self.filePaths) {
                    filePath = filePath.mnz_relativeLocalPath;
                    [self.filePathsArray addObject:filePath];
                    dispatch_semaphore_signal(self.semaphore);
                }
            } else {
                if (self.error) {
                    MEGALogError(@"[PA] Write to file failed with error %@", error);
                    self.error(error);
                }
                if (self.errors) {
                    MEGALogDebug(@"[PA] Max attempts reached");
                    [self.errorsArray addObject:error];
                    dispatch_semaphore_signal(self.semaphore);
                }
            }
        }
    } else {
        NSError *error = [info objectForKey:@"PHImageErrorKey"];
        MEGALogError(@"[PA] Request image data for asset: %@ failed with error: %@", asset, error);
        if (self.retries < 20) {
            self.retries++;
            [self requestImageAsset:asset];
        } else {
            if (self.error) {
                MEGALogDebug(@"[PA] Max attempts reached");
                self.error(error);
            }
            if (self.errors) {
                MEGALogDebug(@"[PA] Max attempts reached");
                dispatch_semaphore_signal(self.semaphore);
                [self.errorsArray addObject:error];
            }
        }
    }
}

- (CGSize)sizeByVideoTrack:(AVAssetTrack *)videoTrack videoQuality:(ChatVideoUploadQuality)videoQuality {
    CGAffineTransform transform = videoTrack.preferredTransform;
    
    CGFloat width, height;
    CGFloat videoAngleInDegree  = atan2(transform.b, transform.a) * 180 / M_PI;
    if (videoAngleInDegree == 0 || videoAngleInDegree == 180) {
        width = videoTrack.naturalSize.width;
        height = videoTrack.naturalSize.height;
    } else { // Source video recorded in portrait
        width = videoTrack.naturalSize.height;
        height = videoTrack.naturalSize.width;
    }
    
    if (videoQuality < ChatVideoUploadQualityHigh) {
        CGFloat shortSideByQuality = (videoQuality == ChatVideoUploadQualityLow) ? 480.0f : 720.0f;
        CGFloat shortSide = (width > height) ? height : width;
        if (shortSide > shortSideByQuality) {
            if (width > height) {
                width = width * shortSideByQuality / height;
                height = shortSideByQuality;
            } else {
                height = height * shortSideByQuality / width;
                width = shortSideByQuality;
            }
        }
    }
    
    return CGSizeMake(width, height);
}

- (BOOL)shouldEncodeVideoTrack:(AVAssetTrack *)videoTrack videoQuality:(ChatVideoUploadQuality)videoQuality extension:(NSString *)extension {
    if (self.shareThroughChat && videoQuality < ChatVideoUploadQualityOriginal) {
        if ([extension.lowercaseString isEqualToString:@"mp4"]) {
            if (videoQuality < ChatVideoUploadQualityHigh) {
                CGFloat shorterSize = (videoTrack.naturalSize.width > videoTrack.naturalSize.height) ? videoTrack.naturalSize.height : videoTrack.naturalSize.width;
                
                CGFloat shortSideByQuality = (videoQuality == ChatVideoUploadQualityLow) ? 480.0f : 720.0f;
                
                if (shorterSize > shortSideByQuality) {
                    return YES;
                }
            }
        } else {
            return YES;
        }
    }
    
    return NO;
}

- (float)bpsByVideoTrack:(AVAssetTrack *)videoTrack videoQuality:(ChatVideoUploadQuality)videoQuality {
    float bpsByQuality;
    switch (videoQuality) {
        case ChatVideoUploadQualityLow:
            bpsByQuality = BPS_LOW;
            break;
            
        case ChatVideoUploadQualityMedium:
            bpsByQuality = BPS_MEDIUM;
            break;
            
        default:
            bpsByQuality = videoTrack.estimatedDataRate;
            break;
    }
    
    if (videoTrack.estimatedDataRate < bpsByQuality) {
        bpsByQuality = videoTrack.estimatedDataRate;
    }
    
    return (bpsByQuality <= 0) ? BPS_MEDIUM : bpsByQuality;
}

- (void)exportSessionCancelledOrFailed {
    for (NSString *filePath in self.filePathsArray) {
        [NSFileManager.defaultManager mnz_removeItemAtPath:filePath];
    }
    [self.filePathsArray removeAllObjects];
    [self.errorsArray removeAllObjects];
    [self.assets removeAllObjects];
    if (self.semaphore) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (SDAVAssetExportSession *)configureEncoderWithAVAsset:(AVAsset *)avAsset videoQuality:(ChatVideoUploadQuality)videoQuality filePath:(NSString *)filePath {
    if (![filePath.pathExtension isEqualToString:@"mp4"]) {
        filePath = [filePath stringByDeletingPathExtension];
        filePath = [filePath stringByAppendingPathExtension:@"mp4"];
    }
    [NSFileManager.defaultManager mnz_removeItemAtPath:filePath];
    
    AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    CGSize videoSize = [self sizeByVideoTrack:videoTrack videoQuality:videoQuality];
    float bps = [self bpsByVideoTrack:videoTrack videoQuality:videoQuality];
    float fps = 30;
    if (videoTrack.nominalFrameRate < 30 || videoQuality == ChatVideoUploadQualityHigh) {
        fps = videoTrack.nominalFrameRate;
    }
    
    SDAVAssetExportSession *encoder = [[SDAVAssetExportSession alloc] initWithAsset:avAsset];
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = [NSURL fileURLWithPath:filePath];
    encoder.videoSettings = @{AVVideoCodecKey:AVVideoCodecTypeH264, AVVideoWidthKey:@(videoSize.width), AVVideoHeightKey:@(videoSize.height), AVVideoCompressionPropertiesKey:@{AVVideoAverageBitRateKey:@(bps), AVVideoAverageNonDroppableFrameRateKey:@(fps), AVVideoProfileLevelKey:AVVideoProfileLevelH264BaselineAutoLevel, }, };
    
    encoder.audioSettings = @
    {
        AVFormatIDKey:@(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey:@1,
        AVSampleRateKey:@44100,
        AVEncoderBitRateKey:@128000,
        AVEncoderBitRateStrategyKey:AVAudioBitRateStrategy_Variable,
    };
    
    [encoder addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:ProcessAssetProgressContext];
    
    return encoder;
}

- (void)downscaleVideoAsset:(PHAsset *)asset encoder:(SDAVAssetExportSession *)encoder {
    if (!self.alertController) {
        NSString *title = [LocalizedString(@"preparing...", @"Label for the status of a transfer when is being preparing - (String as short as possible.") stringByAppendingString:@"\n"];
        self.alertController = [UIAlertController alertControllerWithTitle:title message:@"\n" preferredStyle:UIAlertControllerStyleAlert];
        [self.alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            MEGALogDebug(@"[PA] User cancelled the export session");
            self.cancelExportByUser = YES;
            [self exportSessionCancelledOrFailed];
            [encoder cancelExport];
        }]];
    }
    
    MEGALogDebug(@"[PA] Export session started");
    [encoder exportAsynchronouslyWithCompletionHandler:^{
        if (encoder.status == AVAssetExportSessionStatusCompleted) {
            MEGALogDebug(@"[PA] Export session finished");
            if ([encoder.asset isKindOfClass:[AVURLAsset class]]) {
                self.currentProgress += asset.duration;
            } else if ([encoder.asset isKindOfClass:[AVComposition class]]) {
                float realDuration = [self realDurationForAVAsset:encoder.asset];
                self.currentProgress += realDuration;
            }
            
            NSError *error;
            NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:asset.creationDate forKey:NSFileModificationDate];
            if (![[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:encoder.outputURL.path error:&error]) {
                MEGALogError(@"[PA] Set attributes failed with error: %@", error);
            }
            if (self.filePath) {
                NSString *filePath = encoder.outputURL.path.mnz_relativeLocalPath;
                self.filePath(filePath);
            }
            if (self.filePaths) {
                NSString *filePath = encoder.outputURL.path.mnz_relativeLocalPath;
                [self.filePathsArray addObject:filePath];
                dispatch_semaphore_signal(self.semaphore);
            }
        } else if (encoder.status == AVAssetExportSessionStatusCancelled) {
            MEGALogDebug(@"[PA] Export session cancelled");
            if (!self.cancelExportByUser) {
                [self exportSessionCancelledOrFailed];
            }
        }
        else {
            MEGALogDebug(@"[PA] Export session failed with error: %@ (%ld)", encoder.error.localizedDescription, (long)encoder.error.code);
            [self exportSessionCancelledOrFailed];
            self.exportAssetFailed = YES;
        }
        [encoder removeObserver:self forKeyPath:@"progress" context:ProcessAssetProgressContext];
    }];
    
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (UIApplication.mnz_presentingViewController != self.alertController) {
            [UIApplication.mnz_presentingViewController presentViewController:self.alertController animated:YES completion:^{
                [self addProgressViewToAlertController];
            }];
        }
    });
}

- (void)addProgressViewToAlertController {
    CGFloat margin = 20.0;
    CGRect rect = CGRectMake(margin, 72.0, self.alertController.view.frame.size.width - margin * 2.0 , 2.0);
    self.progressView = [[UIProgressView alloc] initWithFrame:rect];
    self.progressView.progress = 0.0;
    self.progressView.tintColor = [UIColor supportSuccessColor];
    [self.alertController.view addSubview:self.progressView];
}

/* The real duration for AVAsset when it is kind of class AVComposition */
- (float)realDurationForAVAsset:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    AVAssetTrackSegment *segment = videoTrack.segments[videoTrack.segments.count - 1];
    float start = CMTimeGetSeconds(segment.timeMapping.target.start);
    float duration = CMTimeGetSeconds(segment.timeMapping.target.duration);
    return start + duration;
}

- (ChatVideoUploadQuality)chatVideoUploadQuality {
    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    ChatVideoUploadQuality videoQuality = [[sharedUserDefaults objectForKey:@"ChatVideoQuality"] unsignedIntegerValue];
    if (!videoQuality) {
        [sharedUserDefaults setObject:@(ChatVideoUploadQualityMedium) forKey:@"ChatVideoQuality"];
        videoQuality = ChatVideoUploadQualityMedium;
    }
    return videoQuality;
}

@end
