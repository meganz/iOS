
#import "MEGAShowPasswordReminderRequestDelegate.h"
#import "PasswordReminderViewController.h"
#import "UIApplication+MNZCategory.h"
#import "Helper.h"

@interface MEGAShowPasswordReminderRequestDelegate ()

@property (assign) BOOL logout;

@end

@implementation MEGAShowPasswordReminderRequestDelegate

- (instancetype)initWithLogout:(BOOL)logout {
    self = [super init];
    if(self) {
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
    
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    
    if (request.flag) {
        PasswordReminderViewController *passwordReminderViewController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"PasswordReminderViewControllerID"];
        passwordReminderViewController.logout = self.logout;
        [[UIApplication mnz_visibleViewController] presentViewController:passwordReminderViewController animated:YES completion:nil];

    } else {
        if (self.logout) {
            [Helper logoutAfterPasswordReminder];
        }
    }
    
}

@end
