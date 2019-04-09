
#import "AttributeUploadOperation.h"

@implementation AttributeUploadOperation

- (instancetype)initWithAttributeURL:(NSURL *)URL node:(MEGANode *)node {
    self = [super init];
    if (self) {
        _node = node;
        _attributeURL = URL;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", NSStringFromClass([self class]), self.attributeURL, self.node.name];
}

- (void)start {
    [super start];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:self.attributeURL.path]) {
        MEGALogError(@"[Camera Upload] attribute file doesn't exist %@", self);
        [self finishOperation];
        return;
    }
    
    unsigned long long fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:self.attributeURL.path error:nil].fileSize;
    if (![MEGASdkManager.sharedMEGASdk testAllocationByAllocationCount:3 allocationSize:(NSUInteger)(fileSize * 4.0 / 3.0)]) {
        MEGALogError(@"[Camera Upload] no memory to upload the attribute %@", self);
        [self finishOperation];
        return;
    }
}

@end
