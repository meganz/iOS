
#import "MEGAInviteContactRequestDelegate.h"

#import <ContactsUI/ContactsUI.h>

#import "SVProgressHUD.h"
#import "CustomModalAlertViewController.h"
#import "UIApplication+MNZCategory.h"

@interface MEGAInviteContactRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;

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

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        switch (error.type) {
            case MEGAErrorTypeApiEArgs:
                if ([request.email isEqualToString:api.myEmail]) {
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noNeedToAddYourOwnEmailAddress", @"Add contacts and share dialog error message when user try to add your own email address")];
                }
                break;
                
            case MEGAErrorTypeApiEExist: {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"alreadyHaveAContactWithThatEmailAddress", @"Add contacts and share dialog error message when user try to add already existing email address.")];
                break;
            }
                
            default:
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
                break;
        }
        
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        
        NSString *detailText;
        if (self.totalRequests > 1) {
            detailText = AMLocalizedString(@"theUsersHaveBeenInvited", @"Success message shown when some contacts have been invited");
        } else {
            detailText = AMLocalizedString(@"theUserHasBeenInvited", @"Success message shown when a contact has been invited");
            detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
        }
        
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        customModalAlertVC.image = @"inviteSent";
        customModalAlertVC.viewTitle = AMLocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
        customModalAlertVC.detail = detailText;
        customModalAlertVC.boldInDetail = request.email;
        customModalAlertVC.action = AMLocalizedString(@"close", nil);
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        if ([[UIApplication mnz_visibleViewController] isKindOfClass:CNContactPickerViewController.class] ||
            [[UIApplication mnz_visibleViewController] isKindOfClass:CustomModalAlertViewController.class]) {
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:customModalAlertVC animated:YES completion:nil];
        } else {
            [[UIApplication mnz_visibleViewController] presentViewController:customModalAlertVC animated:YES completion:nil];
        }
    }
}

@end
