
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGALoginRequestDelegate.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

@interface MEGACreateAccountRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGAError *error);

@end

@implementation MEGACreateAccountRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGAError *error))completion {
    self = [super init];
    if (self) {
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
    
    if (error.type) {
        if (self.resumeCreateAccount) {
            MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
            loginRequestDelegate.confirmAccountInOtherClient = YES;
            NSString *email = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
            NSString *base64pwkey = [SAMKeychain passwordForService:@"MEGA" account:@"base64pwkey"];
            NSString *stringHash = [api hashForBase64pwkey:base64pwkey email:email];
            [api fastLoginWithEmail:email stringHash:stringHash base64pwKey:base64pwkey delegate:loginRequestDelegate];
        } else {
            if (self.completion) {
                self.completion(error);
            }
            
            switch (error.type) {
                case MEGAErrorTypeApiEExist: {
                    NSString *message = AMLocalizedString(@"emailAlreadyRegistered", @"Error text shown when the users tries to create an account with an email already in use");
                    [SVProgressHUD showErrorWithStatus:message];
                    break;
                }
                    
                case MEGAErrorTypeApiEArgs: {
                    NSString *message = AMLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used");

                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                    
                    [[UIApplication mnz_visibleViewController] presentViewController:alertController animated:YES completion:nil];
                    break;
                }
                    
                default: {
                    NSString *message = [NSString stringWithFormat:@"%@ %@", request.requestString, error.name];
                    [SVProgressHUD showErrorWithStatus:message];
                    break;
                }
            }
        }
    } else {
        [SAMKeychain setPassword:request.sessionKey forService:@"MEGA" account:@"sessionId"];
        [SAMKeychain setPassword:request.email forService:@"MEGA" account:@"email"];
        [SAMKeychain setPassword:request.name forService:@"MEGA" account:@"name"];
        NSString *base64pwkey = [api base64pwkeyForPassword:request.password];
        [SAMKeychain setPassword:base64pwkey forService:@"MEGA" account:@"base64pwkey"];
        
        if (self.completion) {
            self.completion(error);
        }
    }
}

@end
