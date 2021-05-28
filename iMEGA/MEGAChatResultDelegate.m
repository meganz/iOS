#import "MEGAChatResultDelegate.h"

@interface MEGAChatResultDelegate ()

@property (nonatomic, copy) void (^completion)(MEGAChatSdk *api, uint64_t chatId , MEGAChatConnection newState);

@end

@implementation MEGAChatResultDelegate

- (instancetype)initWithCompletion:(void (^)(MEGAChatSdk *api, uint64_t chatId , MEGAChatConnection newState))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(MEGAChatConnection)newState {
    if (self.completion) {
        self.completion(api, chatId, newState);
    }
}

@end
