
#import "MEGAGetFolderInfoRequestDelegate.h"

@interface MEGAGetFolderInfoRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);

@end

@implementation MEGAGetFolderInfoRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
    self = [super init];
    if(self) {
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
    
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    if (self.completion) {
        self.completion(request);
    }
}

@end
