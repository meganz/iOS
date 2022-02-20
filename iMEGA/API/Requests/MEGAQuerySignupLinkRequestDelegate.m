
#import "MEGAQuerySignupLinkRequestDelegate.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "CreateAccountViewController.h"
#import "LoginViewController.h"
#import "MEGALinkManager.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGASdkManager.h"
#import "OnboardingViewController.h"
#import "UIApplication+MNZCategory.h"

@import SAMKeychain;

@interface MEGAQuerySignupLinkRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);
@property (nonatomic) URLType urlType;

@property (nonatomic) NSString *email;

@end

@implementation MEGAQuerySignupLinkRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType {
    self = [super init];
    if (self) {
        _completion = requestCompletion;
        _urlType = urlType;
    }
    
    return self;
}

#pragma mark - Private

- (void)manageQuerySignupLinkRequest:(MEGARequest *)request {
    if (self.urlType == URLTypeConfirmationLink) {
        if (request.flag) {
            NSString *ephemeralEmail = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionId"] && [request.email isEqualToString:ephemeralEmail]) {                
                MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:nil];
                if (chatInit != MEGAChatInitWaitingNewSession) {
                    MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
                    [[MEGASdkManager sharedMEGAChatSdk] logout];
                }
                
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                loginRequestDelegate.confirmAccountInOtherClient = YES;
                NSString *password = [SAMKeychain passwordForService:@"MEGA" account:@"password"];
                [MEGASdkManager.sharedMEGASdk loginWithEmail:request.email password:password delegate:loginRequestDelegate];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    UIViewController *rootViewController = UIApplication.mnz_keyWindow.rootViewController;
                    if ([rootViewController isKindOfClass:OnboardingViewController.class]) {
                        UINavigationController *loginNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginNavigationControllerID"];
                        LoginViewController *loginVC = loginNC.viewControllers.firstObject;
                        loginVC.emailString = request.email;
                        loginVC.modalPresentationStyle = UIModalPresentationFullScreen;
                        
                        [UIApplication.mnz_presentingViewController presentViewController:loginNC animated:YES completion:nil];
                    }
                }]];
                
                if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionId"]) {
                    [MEGASdkManager.sharedMEGASdk cancelCreateAccount];
                    [Helper clearEphemeralSession];
                    [UIApplication.mnz_visibleViewController dismissViewControllerAnimated:YES completion:^{
                        [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
                    }];
                } else {
                    [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
                }
                
                [MEGALinkManager resetLinkAndURLType];
            }
        } else {
            [MEGALinkManager presentConfirmViewWithURLType:URLTypeConfirmationLink link:MEGALinkManager.linkURL.absoluteString email:self.email];
        }
    } else if (self.urlType == URLTypeNewSignUpLink && MEGALinkManager.emailOfNewSignUpLink)  {
        UIViewController *rootViewController = UIApplication.mnz_keyWindow.rootViewController;
        if ([rootViewController isKindOfClass:OnboardingViewController.class]) {
            UINavigationController *createNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CreateAccountNavigationControllerID"];
            CreateAccountViewController *createAccountVC = createNC.viewControllers.firstObject;
            createAccountVC.emailString = MEGALinkManager.emailOfNewSignUpLink;
            createAccountVC.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [UIApplication.mnz_presentingViewController presentViewController:createNC animated:YES completion:nil];
            
            MEGALinkManager.emailOfNewSignUpLink = nil;
        }
        
        [MEGALinkManager resetLinkAndURLType];
    }
    
    self.email = nil;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEArgs:
            case MEGAErrorTypeApiEIncomplete:
                [MEGALinkManager showLinkNotValid];
                break;
                
            case MEGAErrorTypeApiEExpired:
            case MEGAErrorTypeApiENoent: {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Your confirmation link is no longer valid. Your account may already be activated or you may have cancelled your registration.", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
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
        
        [MEGALinkManager resetLinkAndURLType];
    } else {
        self.email = request.email;
        MEGALinkManager.linkURL = [NSURL URLWithString:request.link];
        MEGALinkManager.emailOfNewSignUpLink = request.email;
        
        [self manageQuerySignupLinkRequest:request];
    }
}

@end
