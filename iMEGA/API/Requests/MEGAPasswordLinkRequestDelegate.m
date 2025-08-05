#import "MEGAPasswordLinkRequestDelegate.h"

#import "SVProgressHUD.h"
#import "LocalizationHelper.h"

@interface MEGAPasswordLinkRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);
@property (nonatomic, copy) void (^onError)(MEGARequest *request);
@property (nonatomic) BOOL multipleLinks;
@property (nonatomic) BOOL forDecryption;

@end

@implementation MEGAPasswordLinkRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks {
    self = [super init];
    if(self) {
        _completion = completion;
        _multipleLinks = multipleLinks;
        _forDecryption = NO;
    }
    return self;
}

- (instancetype)initForDecryptionWithCompletion:(void (^)(MEGARequest *request))completion onError:(void (^)(MEGARequest *request))onError {
    self = [super init];
    if(self) {
        _completion = completion;
        _onError = onError;
        _forDecryption = YES;
    }
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if (!self.forDecryption) {
        NSString *status = self.multipleLinks ? LocalizedString(@"generatingLinks", @"") : LocalizedString(@"generatingLink", @"");
        [SVProgressHUD showWithStatus:status];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type] && !self.forDecryption) {
        [SVProgressHUD showErrorWithStatus:LocalizedString(error.name, @"")];
        return;
    }
    
    if ([error type] && error.type == MEGAErrorTypeApiEKey && self.forDecryption && self.onError) {
        self.onError(request);
        return;
    }

    if (self.completion) {
        self.completion(request);
    }
}

@end
