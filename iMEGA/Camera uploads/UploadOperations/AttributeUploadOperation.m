
#import "AttributeUploadOperation.h"
#import "NSFileManager+MNZCategory.h"

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
    
    [self beginBackgroundTaskWithExpirationHandler:^{
        MEGALogDebug(@"[Camera Upload] %@ background task expired", self);
        [self finishOperation];
    }];
}

@end
