
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGALoginRequestDelegate.h"

#import "SAMKeychain.h"

@interface MEGACreateAccountRequestDelegate ()

@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGACreateAccountRequestDelegate

- (instancetype)initWithCompletion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    return self;
}


#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type) {
        NSString *message = [NSString stringWithFormat:@"%@ %@", request.requestString, error.name];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        if (self.resumeCreateAccount) {
            MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
            loginRequestDelegate.confirmAccountInOtherClient = YES;
            NSString *email = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
            NSString *password = [SAMKeychain passwordForService:@"MEGA" account:@"password"];
            [api loginWithEmail:email password:password delegate:loginRequestDelegate];
        }
        
        return;
    } else {
        self.completion();
    }
}

@end
