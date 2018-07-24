
#import "MEGAExportRequestDelegate.h"

#import "SVProgressHUD.h"

@interface MEGAExportRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);
@property (nonatomic) BOOL multipleLinks;

@end

@implementation MEGAExportRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks {
    self = [super init];
    if (self) {
        _completion = completion;
        _multipleLinks = multipleLinks;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];

    if (request.access) {
        NSString *status = self.multipleLinks ? AMLocalizedString(@"generatingLinks", @"Message shown when some links to files and/or folders are being generated") : AMLocalizedString(@"generatingLink", @"Message shown when some links to files and/or folders are being generated");
        [SVProgressHUD showWithStatus:status];
    } else {
        [SVProgressHUD show];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];

    if (error.type) {
        [SVProgressHUD showErrorWithStatus:error.name];
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
