
#import "MEGAPasswordLinkRequestDelegate.h"

#import "SVProgressHUD.h"

@interface MEGAPasswordLinkRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);
@property (nonatomic) BOOL multipleLinks;

@end

@implementation MEGAPasswordLinkRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks {
    self = [super init];
    if(self) {
        _completion = completion;
        _multipleLinks = multipleLinks;
    }
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
    
    NSString *status = self.multipleLinks ? AMLocalizedString(@"generatingLinks", nil) : AMLocalizedString(@"generatingLink", nil);
    [SVProgressHUD showWithStatus:status];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if ([error type]) {
        [SVProgressHUD showErrorWithStatus:error.name];
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
