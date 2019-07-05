
#import "CameraUploadStore.h"
#import "NSURL+CameraUpload.h"

@interface CameraUploadStore ()

@property (strong, nonatomic) MEGAStoreStack *storeStack;

@end

@implementation CameraUploadStore

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
        _storeStack = [[MEGAStoreStack alloc] initWithModelName:@"CameraUpload" storeURL:[self storeURL]];
    }
    
    return self;
}

- (NSURL *)storeURL {
    return [NSURL.mnz_cameraUploadURL URLByAppendingPathComponent:@"CameraUpload.sqlite"];
}

@end
