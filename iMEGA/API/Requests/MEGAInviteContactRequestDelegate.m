
#import "MEGAInviteContactRequestDelegate.h"

#import "SVProgressHUD.h"

@interface MEGAInviteContactRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;

@end

@implementation MEGAInviteContactRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        switch (error.type) {
            case MEGAErrorTypeApiEArgs:
                if ([request.email isEqualToString:api.myEmail]) {
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noNeedToAddYourOwnEmailAddress", @"Add contacts and share dialog error message when user try to add your own email address")];
                }
                break;
                
            case MEGAErrorTypeApiEExist: {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"alreadyHaveAContactWithThatEmailAddress", @"Add contacts and share dialog error message when user try to add already existing email address.")];
                break;
            }
                
            default:
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
                break;
        }
        
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        
        NSString *alertTitle;
        if (self.totalRequests > 1) {
            alertTitle = AMLocalizedString(@"theUsersHaveBeenInvited", @"Success message shown when some contacts have been invited");
        } else {
            alertTitle = AMLocalizedString(@"theUserHasBeenInvited", @"Success message shown when a contact has been invited");
            alertTitle = [alertTitle stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

@end
