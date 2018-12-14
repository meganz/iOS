
#import "MEGAGenericRequestDelegate.h"

@interface MEGAGenericRequestDelegate ()

@property (nonatomic, copy) void (^errorCompletion)(MEGARequest *request, MEGAError *error);
@property (nonatomic, copy) void (^requestCompletion)(MEGARequest *request);

@end

@implementation MEGAGenericRequestDelegate

- (instancetype)initWithRequestCompletion:(void (^)(MEGARequest *request))requestCompletion errorCompletion:(void (^)(MEGARequest *request, MEGAError *error))errorCompletion {
    self = [super init];
    if (self) {
        _requestCompletion = requestCompletion;
        _errorCompletion = errorCompletion;
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
        if (self.errorCompletion) {
            self.errorCompletion(request, error);
        }
    } else {
        if (self.requestCompletion) {
            self.requestCompletion(request);
        }
    }
}

@end
