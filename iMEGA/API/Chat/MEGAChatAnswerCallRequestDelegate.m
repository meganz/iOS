#import "MEGAChatAnswerCallRequestDelegate.h"

@interface MEGAChatAnswerCallRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGAChatError *error);

@end

@implementation MEGAChatAnswerCallRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion {
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
        self.completion(error);
    }
}

@end
