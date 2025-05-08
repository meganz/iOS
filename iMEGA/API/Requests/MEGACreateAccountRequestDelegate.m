#import "MEGACreateAccountRequestDelegate.h"
#import "MEGALoginRequestDelegate.h"

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

@import MEGAL10nObjc;
@import SAMKeychain;

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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (self.resumeCreateAccount) {
            MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
            loginRequestDelegate.confirmAccountInOtherClient = YES;
            loginRequestDelegate.isNewUserRegistration = YES;
            NSString *email = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
            NSString *password = [SAMKeychain passwordForService:@"MEGA" account:@"password"];
            [api loginWithEmail:email password:password delegate:loginRequestDelegate];
        } else {
            if (self.completion) {
                self.completion(error);
            }
            
            switch (error.type) {
                case MEGAErrorTypeApiEExist: {
                    NSString *message = LocalizedString(@"emailAlreadyRegistered", @"Error text shown when the users tries to create an account with an email already in use");
                    [SVProgressHUD showErrorWithStatus:message];
                    break;
                }
                    
                default: {
                    NSString *message = [NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")];
                    [SVProgressHUD showErrorWithStatus:message];
                    break;
                }
            }
        }
    } else {
        [SAMKeychain setPassword:request.sessionKey forService:@"MEGA" account:@"sessionId"];
        [SAMKeychain setPassword:request.email forService:@"MEGA" account:@"email"];
        [SAMKeychain setPassword:request.name forService:@"MEGA" account:@"name"];
        [SAMKeychain setPassword:request.password forService:@"MEGA" account:@"password"];
        
        if (self.completion) {
            self.completion(error);
        }
    }
}

@end
