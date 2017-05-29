
#import "MEGASendSignupLinkRequestDelegate.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

@implementation MEGASendSignupLinkRequestDelegate

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type) {
        NSString *message = [NSString stringWithFormat:@"%@ %@", request.requestString, error.name];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    } else {
        [SAMKeychain setPassword:request.email forService:@"MEGA" account:@"email"];
        [SAMKeychain setPassword:request.name forService:@"MEGA" account:@"name"];
        [SAMKeychain setPassword:request.password forService:@"MEGA" account:@"password"];
        [SVProgressHUD showInfoWithStatus:AMLocalizedString(@"pleaseCheckYourEmail", nil)];
    }
}

@end
