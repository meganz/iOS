#import "MEGAChatMessage.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatMessage ()

@property MegaChatMessage *megaChatMessage;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatMessage

- (instancetype)initWithMegaChatMessage:(megachat::MegaChatMessage *)megaChatMessage cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatMessage = megaChatMessage;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatMessage;
    }
}

- (instancetype)clone {
    return self.megaChatMessage ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatMessage cMemoryOwn:YES] : nil;
}

- (MegaChatMessage *)getCPtr {
    return self.megaChatMessage;
}

- (NSInteger)status {
    return self.megaChatMessage->getStatus();
}

- (uint64_t)messageId {
    return self.megaChatMessage->getMsgId();
}

- (uint64_t)temporalId {
    return self.megaChatMessage->getTempId();
}

- (NSInteger)messageIndex {
    return self.megaChatMessage->getMsgIndex();
}

- (uint64_t)userHande {
    return self.megaChatMessage->getUserHandle();
}

- (MEGAChatMessageChangeType)type {
    return (MEGAChatMessageChangeType) self.megaChatMessage->getType();
}

- (NSDate *)timestamp {
    return [[NSDate alloc] initWithTimeIntervalSince1970:self.megaChatMessage->getTimestamp()];
}

- (NSString *)content {
    return [[NSString alloc] initWithUTF8String:self.megaChatMessage->getContent()];
}

- (NSInteger)changes {
    return self.megaChatMessage->getChanges();
}

- (BOOL)hasChangedForType:(MEGAChatMessageChangeType)changeType {
    return self.megaChatMessage->hasChanged((int)changeType);
}

@end
