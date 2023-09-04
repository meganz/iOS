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
}

@end
