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
    if (request.access) {
        NSString *status = self.multipleLinks ? NSLocalizedString(@"generatingLinks", @"Message shown when some links to files and/or folders are being generated") : NSLocalizedString(@"generatingLink", @"Message shown when some links to files and/or folders are being generated");
        [SVProgressHUD showWithStatus:status];
    } else {
        [SVProgressHUD show];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (error.type == MEGAErrorTypeApiEBusinessPastDue) {
            [SVProgressHUD dismiss];
        } else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(error.name, nil)];
        }
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
