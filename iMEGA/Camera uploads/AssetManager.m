
#import "AssetManager.h"
@import Photos;

@interface AssetManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation AssetManager

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
    }
    return self;
}

#pragma mark - camera scanning
- (void)startScanning {
    
}

- (void)fetchAssetsWithCompletion:(void (^)(PHFetchResult<PHAsset *> *))completion {
    [self.operationQueue addOperationWithBlock:^{
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        completion(fetchResult);
    }];
}

@end
