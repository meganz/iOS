
#import "AttributeUploadOperation.h"
#import "NSFileManager+MNZCategory.h"

@implementation AttributeUploadOperation

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node expiresAfterTimeInterval:(NSTimeInterval)timeInterval {
    self = [super initWithExpireTimeInterval:timeInterval];
    if (self) {
        _node = node;
        _attributeURL = URL;
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
}

- (void)cacheAttributeToDirectoryURL:(NSURL *)directoryURL fileName:(NSString *)fileName {
    NSError *error;
    if ([NSFileManager.defaultManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSURL *cacheURL = [directoryURL URLByAppendingPathComponent:fileName isDirectory:NO];
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
    MEGALogDebug(@"[Camera Upload] %@ operation finished", NSStringFromClass(self.class));
    [super finishOperation];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:self.attributeURL];
}

@end
