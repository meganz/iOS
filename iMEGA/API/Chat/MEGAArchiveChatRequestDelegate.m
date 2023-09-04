#import "MEGAArchiveChatRequestDelegate.h"

@interface MEGAArchiveChatRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGAChatRoom *);

@end

@implementation MEGAArchiveChatRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGAChatRoom *))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    [super onChatRequestFinish:api request:request error:error];
    
    if (error.type) return;
    
    if (self.completion) {
        MEGAChatRoom *chatRoom = [api chatRoomForChatId:request.chatHandle];
        self.completion(chatRoom);
    }
}

@end
