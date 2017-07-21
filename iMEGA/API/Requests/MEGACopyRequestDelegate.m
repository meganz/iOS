
#import "MEGACopyRequestDelegate.h"

#import "SVProgressHUD.h"

@interface MEGACopyRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;

@property (nonatomic, getter=toAttachToChat) BOOL attachToChat;

@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGACopyRequestDelegate

#pragma mark - Initialization

- (instancetype)initToAttachToChatWithCompletion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = 1;
        _totalRequests = 1;
        _attachToChat = YES;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}
- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
        return;
    }
    
    if (self.numberOfRequests == 0) {
        if (self.completion) {
            self.completion();
        }
    }
}

@end
