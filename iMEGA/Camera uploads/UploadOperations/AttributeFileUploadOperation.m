
#import "AttributeFileUploadOperation.h"
#import "NSFileManager+MNZCategory.h"

@implementation AttributeFileUploadOperation

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node {
    self = [super init];
    if (self) {
        _node = node;
        _attributeURL = URL;
    }
    
    return self;
}

- (void)start {
    [super start];

    [self beginBackgroundTaskWithExpirationHandler:^{
        [self finishOperation];
    }];
}

- (void)moveAttributeToDirectoryURL:(NSURL *)directoryURL newFileName:(NSString *)fileName {
    NSError *error;
    if ([NSFileManager.defaultManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSURL *cacheURL = [directoryURL URLByAppendingPathComponent:fileName isDirectory:NO];
        [NSFileManager.defaultManager removeItemIfExistsAtURL:cacheURL];
        if ([NSFileManager.defaultManager moveItemAtURL:self.attributeURL toURL:cacheURL error:&error]) {
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to copy attribute to cache %@", self, error);
        }
    } else {
        MEGALogError(@"[Camera Upload] %@ error when to create attribute cache directory %@", self, error);
    }
}

@end
