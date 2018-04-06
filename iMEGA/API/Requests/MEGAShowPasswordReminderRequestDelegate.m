
#import "MEGAShowPasswordReminderRequestDelegate.h"

#import "Helper.h"
#import "UIApplication+MNZCategory.h"

#import "PasswordReminderViewController.h"

@interface MEGAShowPasswordReminderRequestDelegate ()

@property (assign, getter=isLoggingOut) BOOL logout;

@end

@implementation MEGAShowPasswordReminderRequestDelegate

- (instancetype)initToLogout:(BOOL)logout {
    self = [super init];
    if (self) {
        self.logout = logout;
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
        return;
    }
    
    if (YES) {
        PasswordReminderViewController *passwordReminderViewController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"PasswordReminderViewControllerID"];
        passwordReminderViewController.logout = self.isLoggingOut;
        
        [[UIApplication mnz_visibleViewController] presentViewController:passwordReminderViewController animated:YES completion:nil];
    } else {
        if (self.isLoggingOut) {
            [Helper logoutAfterPasswordReminder];
        }
    }
}

@end
