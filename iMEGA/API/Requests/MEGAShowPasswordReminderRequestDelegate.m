
#import "MEGAShowPasswordReminderRequestDelegate.h"

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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type && error.type != MEGAErrorTypeApiENoent) {
        return;
    }
    
    if (request.flag) {
        if (self.isLoggingOut) {
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"PasswordReminderNavigationControllerID"];
            PasswordReminderViewController *passwordReminderViewController = (PasswordReminderViewController *) navigationController.viewControllers.firstObject;
            passwordReminderViewController.logout = self.isLoggingOut;
            [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
        } else {
            PasswordReminderViewController *passwordReminderViewController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"PasswordReminderViewControllerID"];
            passwordReminderViewController.logout = self.isLoggingOut;
            [UIApplication.mnz_presentingViewController presentViewController:passwordReminderViewController animated:YES completion:nil];
        }
    } else {
        if (self.isLoggingOut) {
            [api logout];
        }
    }
}

@end
