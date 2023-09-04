#import "MEGAGenericRequestDelegate.h"

@interface MEGAGenericRequestDelegate ()

@property (nonatomic, copy) void (^start)(MEGARequest *request);
@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);

@end

@implementation MEGAGenericRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initWithStart:(void (^)(MEGARequest *request))start completion:(void (^)(MEGARequest *request, MEGAError *error))completion {
    self = [super init];
    if (self) {
        _start = start;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if (self.start) {
        self.start(request);
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (self.completion) {
        self.completion(request, error);
    }
}

@end
