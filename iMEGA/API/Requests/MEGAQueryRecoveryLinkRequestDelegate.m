#import "MEGAQueryRecoveryLinkRequestDelegate.h"

#import "SVProgressHUD.h"

#import "ChangePasswordViewController.h"
#import "MEGASdkManager.h"
#import "MEGANavigationController.h"
#import "MEGALinkManager.h"
#import "NSString+MNZCategory.h"
#import "LoginViewController.h"
#import "TwoFactorAuthenticationViewController.h"
#import "UIApplication+MNZCategory.h"
#import "UITextField+MNZCategory.h"

@import SAMKeychain;

@interface MEGAQueryRecoveryLinkRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);
@property (nonatomic) URLType urlType;

@property (nonatomic) NSString *link;
@property (nonatomic) NSString *email;

@end

@implementation MEGAQueryRecoveryLinkRequestDelegate

- (instancetype)initWithRequestCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType {
    self = [super init];
    if (self) {
        _completion = requestCompletion;
        _urlType = urlType;
    }
    return self;
}

#pragma mark - Private

- (void)presentChangeViewType:(ChangeType)changeType email:(NSString *)email masterKey:(NSString *)masterKey link:(NSString *)link {
    ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"ChangeCredentials" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
    changePasswordVC.changeType = changeType;
    changePasswordVC.email = email;
    changePasswordVC.masterKey = masterKey;
    changePasswordVC.link = link;
    
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:changePasswordVC];
    [navigationController addRightCancelButton];
    
    UIViewController *visibleViewController = UIApplication.mnz_presentingViewController;
    if ([visibleViewController isKindOfClass:UIAlertController.class]) {
        [visibleViewController dismissViewControllerAnimated:YES completion:^{
            [visibleViewController presentViewController:navigationController animated:YES completion:nil];
        }];
    } else {
        [visibleViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)alertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if ([alertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEExpired: {
                NSString *alertTitle;
                if (MEGALinkManager.urlType == URLTypeCancelAccountLink) {
                    alertTitle = NSLocalizedString(@"cancellationLinkHasExpired", @"During account cancellation (deletion)");
                } else if (MEGALinkManager.urlType == URLTypeRecoverLink) {
                    alertTitle = NSLocalizedString(@"recoveryLinkHasExpired", @"Message shown during forgot your password process if the link to reset password has expired");
                }
                UIAlertController *linkHasExpiredAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
                [linkHasExpiredAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_presentingViewController presentViewController:linkHasExpiredAlertController animated:YES completion:nil];
                break;
            }
                
            case MEGAErrorTypeApiENoent: {
                [MEGALinkManager showLinkNotValid];
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil) message:NSLocalizedString(@"This link is not related to this account. Please log in with the correct account.", @"Error message shown when opening a link with an account that not corresponds to the link") preferredStyle:UIAlertControllerStyleAlert];
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDestructive handler:nil]];

                [UIApplication.mnz_visibleViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
                break;
            }
                
            default: {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, NSLocalizedString(error.name, nil)]];
                break;
            }
        }
    } else {
        if (MEGALinkManager.urlType == URLTypeChangeEmailLink) {
            [MEGALinkManager presentConfirmViewWithURLType:URLTypeChangeEmailLink link:request.link email:request.email];
        } else if (MEGALinkManager.urlType == URLTypeCancelAccountLink) {
            [MEGALinkManager presentConfirmViewWithURLType:URLTypeCancelAccountLink link:request.link email:request.email];
        } else if (MEGALinkManager.urlType == URLTypeRecoverLink) {
            if (request.flag) {
                UIAlertController *masterKeyLoggedInAlertController;
                if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"]) {
                    masterKeyLoggedInAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:NSLocalizedString(@"youRecoveryKeyIsGoingTo", @"Text of the alert after opening the recovery link to reset pass being logged.") preferredStyle:UIAlertControllerStyleAlert];
                } else {
                    masterKeyLoggedInAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:NSLocalizedString(@"pleaseEnterYourRecoveryKey", @"A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.") preferredStyle:UIAlertControllerStyleAlert];
                    [masterKeyLoggedInAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.placeholder = NSLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
                        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                            return !textField.text.mnz_isEmpty;
                        };
                    }];
                }
                
                [masterKeyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                
                UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    NSString *masterKey = masterKeyLoggedInAlertController.textFields.count ? masterKeyLoggedInAlertController.textFields.firstObject.text : MEGASdkManager.sharedMEGASdk.masterKey;
                    [self presentChangeViewType:ChangeTypeResetPassword email:MEGALinkManager.emailOfNewSignUpLink masterKey:masterKey link:request.link];
                    MEGALinkManager.emailOfNewSignUpLink = nil;
                }];
                okAlertAction.enabled = !masterKeyLoggedInAlertController.textFields.count;
                [masterKeyLoggedInAlertController addAction:okAlertAction];
                
                MEGALinkManager.emailOfNewSignUpLink = request.email;
                
                [UIApplication.mnz_presentingViewController presentViewController:masterKeyLoggedInAlertController animated:YES completion:nil];
            } else {
                [self presentChangeViewType:ChangeTypeParkAccount email:request.email masterKey:nil link:request.link];
            }
        }
    }
}

@end
