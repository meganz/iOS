
#import "MEGASendSignupLinkRequestDelegate.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

@implementation MEGASendSignupLinkRequestDelegate

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type) {
        NSString *title;
        NSString *message;
        switch (error.type) {
            case MEGAErrorTypeApiEExist:
                title = @"";
                message = NSLocalizedString(@"emailAlreadyRegistered", @"Error text shown when the users tries to create an account with an email already in use");
                break;
                
            case MEGAErrorTypeApiEFailed:
                title = @"";
                message = NSLocalizedString(@"emailAddressChangeAlreadyRequested", @"Error message shown when you try to change your account email to one that you already requested.");
                break;
                
            default:
                title = NSLocalizedString(@"error", nil);
                message = [NSString stringWithFormat:@"%@ %@", request.requestString, NSLocalizedString(error.name, nil)];
                break;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    } else {
        [SAMKeychain setPassword:request.email forService:@"MEGA" account:@"email"];
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email")];
    }
}

@end
