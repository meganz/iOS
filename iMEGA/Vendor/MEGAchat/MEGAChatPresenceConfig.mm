
#import "MEGAChatPresenceConfig.h"
#import "megachatapi.h"
#import "MEGAChatPresenceConfig+init.h"

using namespace megachat;

@interface MEGAChatPresenceConfig ()

@property MegaChatPresenceConfig *megaChatPresenceConfig;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatPresenceConfig

- (instancetype)initWithMegaChatPresenceConfig:(megachat::MegaChatPresenceConfig *)megaChatPresenceConfig cMemoryOwn:(BOOL)cMemoryOwn {
    NSParameterAssert(megaChatPresenceConfig);
    self = [super init];
    
    if (self != nil) {
        _megaChatPresenceConfig = megaChatPresenceConfig;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn) {
        delete _megaChatPresenceConfig;
    }
}

- (instancetype)clone {
    return self.megaChatPresenceConfig ? [[MEGAChatPresenceConfig alloc] initWithMegaChatPresenceConfig:self.megaChatPresenceConfig cMemoryOwn:YES] : nil;
}

- (MegaChatPresenceConfig *)getCPtr {
    return self.megaChatPresenceConfig;
}

- (MEGAChatStatus)onlineStatus {
    return (MEGAChatStatus)(self.megaChatPresenceConfig ? self.megaChatPresenceConfig->getOnlineStatus() : 0);
}

- (BOOL)isAutoAwayEnabled {
    return self.megaChatPresenceConfig ? self.megaChatPresenceConfig->isAutoawayEnabled() : NO;
}

- (NSDate *)autoAwayTimeout {
    return self.megaChatPresenceConfig ? [[NSDate alloc] initWithTimeIntervalSince1970:self.megaChatPresenceConfig->getAutoawayTimeout()] : nil;
}

- (BOOL)isPersist {
    return self.megaChatPresenceConfig ? self.megaChatPresenceConfig->isPersist() : NO;
}

- (BOOL)isPending {
    return self.megaChatPresenceConfig ? self.megaChatPresenceConfig->isPending() : NO;
}

- (BOOL)isSignalActivityRequired {
    return self.megaChatPresenceConfig ? self.megaChatPresenceConfig->isSignalActivityRequired() : NO;
}

@end
