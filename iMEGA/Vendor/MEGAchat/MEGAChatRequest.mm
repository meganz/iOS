#import "MEGAChatRequest.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatRequest()

@property MegaChatRequest *megaChatRequest;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatRequest

- (instancetype)initWithMegaChatRequest:(MegaChatRequest *)megaChatRequest cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatRequest = megaChatRequest;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatRequest;
    }
}

- (instancetype)clone {
    return  self.megaChatRequest ? [[MEGAChatRequest alloc] initWithMegaChatRequest:self.megaChatRequest->copy() cMemoryOwn:YES] : nil;
}

- (MegaChatRequest *)getCPtr {
    return self.megaChatRequest;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: requestString=%@, type=%@>",
            [self class], self.requestString, @(self.type)];
}

- (MEGAChatRequestType)type {
    return (MEGAChatRequestType) (self.megaChatRequest ? self.megaChatRequest->getType() : -1);
}

- (NSString *)requestString {
    return self.megaChatRequest->getRequestString() ? [[NSString alloc] initWithUTF8String:self.megaChatRequest->getRequestString()] : nil;
}

@end
