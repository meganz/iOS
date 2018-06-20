
#import "MEGAGetAttrUserRequestDelegate.h"

@interface MEGAGetAttrUserRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);
@property (nonatomic, copy) void (^onError)(MEGAError *error);

@end

@implementation MEGAGetAttrUserRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion onError:(void (^)(MEGAError *error))onError{
    self = [super init];
    if (self) {
        _completion = completion;
        _onError = onError;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type) {
        if (self.onError) {
            self.onError(error);
        }
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
