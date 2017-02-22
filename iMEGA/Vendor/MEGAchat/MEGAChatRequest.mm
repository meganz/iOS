#import "MEGAChatRequest.h"
#import "megachatapi.h"
#import "MEGAChatPeerList+init.h"

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
    if (!self.megaChatRequest) return nil;
    const char *ret = self.megaChatRequest->getRequestString();
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (NSInteger)tag {
    return self.megaChatRequest ? self.megaChatRequest->getTag() : 0;
}

- (long long)number {
    return self.megaChatRequest ? self.megaChatRequest->getNumber() : 0;
}

- (BOOL)isFlag {
    return self.megaChatRequest ? self.megaChatRequest->getFlag() : NO;
}

- (MEGAChatPeerList *)megaChatPeerList {
    return self.megaChatRequest->getMegaChatPeerList() ? [[MEGAChatPeerList alloc] initWithMegaChatPeerList:self.megaChatRequest->getMegaChatPeerList() cMemoryOwn:YES] : nil;
}

- (uint64_t)chatHandle {
    return self.megaChatRequest ? self.megaChatRequest->getChatHandle() : MEGACHAT_INVALID_HANDLE;
}

- (uint64_t)userHandle {
    return self.megaChatRequest ? self.megaChatRequest->getUserHandle() : MEGACHAT_INVALID_HANDLE;
}

- (NSInteger)privilege {
    return self.megaChatRequest ? self.megaChatRequest->getPrivilege() : 0;
}

- (NSString *)text {
    if (!self.megaChatRequest) return nil;
    const char *ret = self.megaChatRequest->getText();
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

@end
