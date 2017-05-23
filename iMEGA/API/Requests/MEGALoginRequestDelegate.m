
#import "MEGALoginRequestDelegate.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "LaunchViewController.h"

@interface MEGALoginRequestDelegate ()

@property (nonatomic, getter=hasSession) BOOL session;

@end

@implementation MEGALoginRequestDelegate

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    }
    
    return self;
}

#pragma mark - Private

- (NSString *)timeFormatted:(NSUInteger)totalSeconds {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:totalSeconds];
    
    return [formatter stringFromDate:date];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
    
    if (!self.hasSession) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD show];
    }

}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    
    if (error.type) {
        NSString *message;
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs:
            case MEGAErrorTypeApiENoent:
                message = AMLocalizedString(@"invalidMailOrPassword", @"Message shown when the user writes a wrong email or password on login");
                break;
                
            case MEGAErrorTypeApiETooMany:
                message = [NSString stringWithFormat:AMLocalizedString(@"tooManyAttemptsLogin", @"Error message when to many attempts to login"), [self timeFormatted:3600]];
                break;
                
            case MEGAErrorTypeApiEIncomplete:
                message = AMLocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess");
                break;
                
            case MEGAErrorTypeApiEBlocked:
                message = AMLocalizedString(@"accountBlocked", @"Error message when trying to login and the account is suspended");
                break;
                
            default:
                message = [NSString stringWithFormat:@"%@ %@", request.requestString, error.name];
                break;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    if (!self.hasSession) {
        NSString *session = [api dumpSession];
        [SAMKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
        
        LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        [UIView transitionWithView:window duration:0.5 options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent) animations:^{
            [window setRootViewController:launchVC];
        } completion:nil];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
}

@end
