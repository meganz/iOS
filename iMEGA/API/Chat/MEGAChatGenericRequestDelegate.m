#import "MEGAChatGenericRequestDelegate.h"

@interface MEGAChatGenericRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGAChatRequest *request, MEGAChatError *error);

@end

@implementation MEGAChatGenericRequestDelegate

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
