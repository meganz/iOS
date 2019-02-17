
#import "AttributeFileUploadOperation.h"
#import "NSFileManager+MNZCategory.h"

@implementation AttributeFileUploadOperation

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node expiresAfterTimeInterval:(NSTimeInterval)timeInterval {
    self = [super initWithExpirationTimeInterval:timeInterval];
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

- (void)moveAttributeToDirectoryURL:(NSURL *)directoryURL newFileName:(NSString *)fileName {
    NSError *error;
    if ([NSFileManager.defaultManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSURL *cacheURL = [directoryURL URLByAppendingPathComponent:fileName isDirectory:NO];
        [NSFileManager.defaultManager removeItemIfExistsAtURL:cacheURL];
        if ([NSFileManager.defaultManager moveItemAtURL:self.attributeURL toURL:cacheURL error:&error]) {
        } else {
            MEGALogDebug(@"[Camera Upload] %@ error when to copy attribute to cache %@", self, error);
        }
    } else {
        MEGALogDebug(@"[Camera Upload] %@ error when to create attribute cache directory %@", self, error);
    }
}

- (void)finishOperation {
    [super finishOperation];
    
    MEGALogDebug(@"[Camera Upload] %@ operation finished", self);
}

@end
