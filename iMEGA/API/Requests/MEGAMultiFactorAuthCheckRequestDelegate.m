#import "MEGAMultiFactorAuthCheckRequestDelegate.h"

@interface MEGAMultiFactorAuthCheckRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);

@end

@implementation MEGAMultiFactorAuthCheckRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (self.completion) {
        self.completion(request, error);
    }
}

@end
