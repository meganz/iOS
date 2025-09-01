#import "MEGAQuerySignupLinkRequestDelegate.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGALinkManager.h"
#import "MEGALoginRequestDelegate.h"
#import "UIApplication+MNZCategory.h"
#import "MEGAChatSdk.h"
#import "MEGA-Swift.h"

#import "LocalizationHelper.h"
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
                MEGAChatInit chatInit = [MEGAChatSdk.shared initKarereWithSid:nil];
                if (chatInit != MEGAChatInitWaitingNewSession) {
                    MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
                    [MEGAChatSdk.shared logout];
                }
                
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                loginRequestDelegate.confirmAccountInOtherClient = YES;
                loginRequestDelegate.isNewUserRegistration = YES;
                NSString *password = [SAMKeychain passwordForService:@"MEGA" account:@"password"];
                [MEGASdk.shared loginWithEmail:request.email password:password delegate:loginRequestDelegate];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self showLoginFromOnboardingWithEmail:request.email];
                }]];
                
                if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionId"]) {
                    [MEGASdk.shared cancelCreateAccount];
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
        [self showRegistrationFromOnboarding];
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:LocalizedString(@"Your confirmation link is no longer valid. Your account may already be activated or you may have cancelled your registration.", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"error", @"") message:LocalizedString(@"This link is not related to this account. Please log in with the correct account.", @"Error message shown when opening a link with an account that not corresponds to the link") preferredStyle:UIAlertControllerStyleAlert];
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDestructive handler:nil]];

                [UIApplication.mnz_visibleViewController presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
                break;
            }
                
            default: {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
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
