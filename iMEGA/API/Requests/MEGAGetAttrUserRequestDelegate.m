#import "MEGAGetAttrUserRequestDelegate.h"

@interface MEGAGetAttrUserRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);
@property (nonatomic, copy) void (^error)(MEGARequest *request, MEGAError *error);

@end

@implementation MEGAGetAttrUserRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion error:(void (^)(MEGARequest *request, MEGAError *error))error {
    self = [super init];
    if (self) {
        _completion = completion;
        _error = error;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (self.error) {
            self.error(request, error);
        }
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
