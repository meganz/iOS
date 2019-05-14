
#import "MEGASdk+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import <objc/runtime.h>

static const void *mnz_accountDetailsKey = &mnz_accountDetailsKey;

@implementation MEGASdk (MNZCategory)

#pragma mark - properties

- (MEGAAccountDetails *)mnz_accountDetails {
    return objc_getAssociatedObject(self, mnz_accountDetailsKey);
}

- (void)mnz_setAccountDetails:(MEGAAccountDetails *)newAccountDetails {
    objc_setAssociatedObject(self, &mnz_accountDetailsKey, newAccountDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mnz_isProAccount {
    return [self.mnz_accountDetails type] > MEGAAccountTypeFree;
}

#pragma mark - methods

- (void)handleAccountBlockedEvent:(MEGAEvent *)event {
    AccountSuspensionType suspensionType = (AccountSuspensionType)event.number;
    SMSState state = [self smsAllowedState];
    if (suspensionType == AccountSuspensionTypeSMSVerification && state != SMSStateNotAllowed) {
        UIViewController *verificationController = [[UIStoryboard storyboardWithName:@"SMSVerification" bundle:nil] instantiateInitialViewController];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:verificationController];
        
        [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:AMLocalizedString(@"accountBlocked", @"Error message when trying to login and the account is blocked") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self logout];
        }]];
        
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

@end
