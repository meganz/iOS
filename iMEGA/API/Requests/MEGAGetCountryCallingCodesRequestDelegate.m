
#import "MEGAGetCountryCallingCodesRequestDelegate.h"

@interface MEGAGetCountryCallingCodesRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);

@end

@implementation MEGAGetCountryCallingCodesRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion {
    self = [super init];
    if (self) {
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
    
    if (self.completion) {
        self.completion(request, error);
    }
}

@end
