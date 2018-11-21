
#import "AttributeUploadOperation.h"
#import "NSFileManager+MNZCategory.h"

@interface AttributeUploadOperation ()

@property (strong, nonatomic) NSTimer *watchTimer;
@property (nonatomic) NSTimeInterval expireTimeInterval;

@end

@implementation AttributeUploadOperation

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node expiresAfterTimeInterval:(NSTimeInterval)timeInterval {
    self = [super init];
    if (self) {
        _node = node;
        _attributeURL = URL;
        _expireTimeInterval = timeInterval;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:self.attributeURL.path]) {
        MEGALogDebug(@"[Camera Upload] No attribute file found at URL %@", self.attributeURL);
        [self finishOperation];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    self.watchTimer = [NSTimer scheduledTimerWithTimeInterval:self.expireTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
        MEGALogDebug(@"[Camera Upload] %@ expired with watch timer", NSStringFromClass(weakSelf.class));
        [weakSelf finishOperation];
    }];
}

- (void)cacheAttributeToURL:(NSURL *)cacheURL {
    NSError *error;
    if ([NSFileManager.defaultManager createDirectoryAtURL:cacheURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        [NSFileManager.defaultManager removeItemIfExistsAtURL:cacheURL];
        if ([NSFileManager.defaultManager copyItemAtURL:self.attributeURL toURL:cacheURL error:&error]) {
            MEGALogDebug(@"[Camera Upload] %@ Copy attribute to cache succeeded", NSStringFromClass(self.class));
        } else {
            MEGALogDebug(@"[Camera Upload] %@ Copy attribute to cache error %@", NSStringFromClass(self.class), error);
        }
    } else {
        MEGALogDebug(@"[Camera Upload] %@ Create attribute cache directory error %@", NSStringFromClass(self.class), error);
    }
}

- (void)finishOperation {
    [super finishOperation];
    
    MEGALogDebug(@"[Camera Upload] %@ operation finished", NSStringFromClass(self.class));
    [self.watchTimer invalidate];
}

@end
