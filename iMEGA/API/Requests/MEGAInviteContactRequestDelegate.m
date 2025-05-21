#import "MEGAInviteContactRequestDelegate.h"

#import <ContactsUI/ContactsUI.h>

#import "SVProgressHUD.h"
#import "CustomModalAlertViewController.h"
#import "UIApplication+MNZCategory.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;
@import MEGAAppSDKRepo;

@interface MEGAInviteContactRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGAInviteContactRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
    }
    
    return self;
}

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests presentSuccessOver:(UIViewController *)viewController completion:(void (^ _Nullable)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
        _viewController = viewController;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        switch (error.type) {
            case MEGAErrorTypeApiEArgs:
                if ([request.email isEqualToString:MEGASdk.currentUserEmail]) {
                    [SVProgressHUD showErrorWithStatus:LocalizedString(@"noNeedToAddYourOwnEmailAddress", @"Add contacts and share dialog error message when user try to add your own email address")];
                }
                break;
                
            case MEGAErrorTypeApiEExist: {
                MEGAUser *user = [api contactForEmail:request.email];
                if (user && user.visibility == MEGAUserVisibilityVisible) {
                    
                    [SVProgressHUD showErrorWithStatus:({
                        [LocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.") stringByReplacingOccurrencesOfString:@"%s" withString:request.email];
                    })];
                    
                } else {
                    BOOL isInOutgoingContactRequest = NO;
                    MEGAContactRequestList *outgoingContactRequestList = [api outgoingContactRequests];
                    for (NSInteger i = 0; i < outgoingContactRequestList.size; i++) {
                        MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
                        if ([request.email isEqualToString:contactRequest.targetEmail]) {
                            isInOutgoingContactRequest = YES;
                            break;
                        }
                    }
                    if (isInOutgoingContactRequest) {
                        NSString *statusText = LocalizedString(@"dialog.inviteContact.outgoingContactRequest", @"Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user");
                        statusText = [statusText stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
                        [SVProgressHUD showErrorWithStatus:statusText];
                    }
                    
                }
                
                break;
            }
                
            default:
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
                break;
        }
        
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        
        NSString *detailText;
        if (self.totalRequests > 1) {
            detailText = LocalizedString(@"theUsersHaveBeenInvited", @"Success message shown when some contacts have been invited");
        } else {
            detailText = LocalizedString(@"dialog.inviteContact.outgoingContactRequest", @"Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user");
            detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
        }
        
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.image = [UIImage megaImageWithNamed:@"contactInviteSent"];
        customModalAlertVC.viewTitle = LocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
        customModalAlertVC.detail = detailText;
        customModalAlertVC.boldInDetail = request.email;
        customModalAlertVC.firstButtonTitle = LocalizedString(@"close", @"");
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.firstCompletion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:^{
                if (self.completion) {
                    self.completion();
                }
            }];
        };
        
        if (self.viewController) {
            [self.viewController presentViewController:customModalAlertVC animated:YES completion:nil];
        } else {
            [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
        }
    }
}

@end
