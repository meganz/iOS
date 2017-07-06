

#import "MEGAGetThumbnailRequestDelegate.h"

@interface MEGAGetThumbnailRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);

@end

@implementation MEGAGetThumbnailRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
    self = [super init];
    if(self) {
        _completion = completion;
    }
    return self;
}

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    if (self.completion) {
        self.completion(request);
    }
}

@end
