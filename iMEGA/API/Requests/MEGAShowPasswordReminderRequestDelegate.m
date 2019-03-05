
#import "MEGAShowPasswordReminderRequestDelegate.h"

#import "Helper.h"
#import "MEGANavigationController.h"
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
    
    if (error.type && error.type != MEGAErrorTypeApiENoent) {
        return;
    }
    
    if (request.flag) {
        PasswordReminderViewController *passwordReminderViewController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"PasswordReminderViewControllerID"];
        passwordReminderViewController.logout = self.isLoggingOut;

        if (self.isLoggingOut) {
            passwordReminderViewController.modalPresentationStyle = UIModalPresentationFullScreen;

            MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:passwordReminderViewController];
            [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
        } else {
            [UIApplication.mnz_presentingViewController presentViewController:passwordReminderViewController animated:YES completion:nil];
        }
    } else {
        if (self.isLoggingOut) {
            [Helper logoutAfterPasswordReminder];
        }
    }
}

@end
