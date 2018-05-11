
#import "MEGASendSignupLinkRequestDelegate.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

@implementation MEGASendSignupLinkRequestDelegate

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type) {
        NSString *message;
        switch (error.type) {
            case MEGAErrorTypeApiEExist:
                message = AMLocalizedString(@"emailAlreadyRegistered", @"Error text shown when the users tries to create an account with an email already in use");
                break;
                
            case MEGAErrorTypeApiEArgs:
                message = AMLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used");
                break;
                
            default:
                message = [NSString stringWithFormat:@"%@ %@", request.requestString, error.name];
                break;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        
        [[UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    } else {
        [SAMKeychain setPassword:request.email forService:@"MEGA" account:@"email"];
        [SVProgressHUD showInfoWithStatus:AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email")];
    }
}

@end
