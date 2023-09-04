#import "MEGAChatAttachVoiceClipRequestDelegate.h"

@interface MEGAChatAttachVoiceClipRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGAChatRequest *request, MEGAChatError *error);

@end

@implementation MEGAChatAttachVoiceClipRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithCompletion:(void (^)(MEGAChatRequest *request, MEGAChatError *error))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    [super onChatRequestFinish:api request:request error:error];
    
    if (self.completion) {
        self.completion(request, error);
    }
}

@end
