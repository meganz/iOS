#import "MEGACopyRequestDelegate.h"

#import "SVProgressHUD.h"

#import "LocalizationHelper.h"

@interface MEGACopyRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);

@end

@implementation MEGACopyRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {    
    if (error.type) {
        // OverQuota errors are handled in AppDelegate::onRequestFinish by showing an alert, no need to show error with this HUD
        if (error.type != MEGAErrorTypeApiEOverQuota) {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
        }
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
