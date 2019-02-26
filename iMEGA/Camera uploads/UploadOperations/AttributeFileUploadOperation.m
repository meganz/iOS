
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

@end
