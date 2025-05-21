#import "MEGARemoveContactRequestDelegate.h"
#import "SVProgressHUD.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface MEGARemoveContactRequestDelegate ()
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGARemoveContactRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithCompletion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    MEGAUser *user = [api contactForEmail:request.email];
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        switch (error.type) {
            case MEGAErrorTypeApiEMasterOnly: {
                NSString *status = LocalizedString(@"You cannot remove %1$s as a contact because they are part of your Business account.", @"Error shown when a Business account user (sub-user or admin) tries to remove a contact which is part of the same Business account. Please, keep the placeholder, it will be replaced with the name or email of the account, for example: Jane Appleseed or ja@mega.nz");
                status = [status stringByReplacingOccurrencesOfString:@"%1$s" withString:user.mnz_displayName];
                [SVProgressHUD showErrorWithStatus:status];
                break;
            }
                
            default:
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
                break;
        }
        return;
    }
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    NSString *message = [NSString stringWithFormat:LocalizedString(@"removedContact", @"Success message shown when the selected contact has been removed. 'Contact {Name of contact} removed'"), user.mnz_displayName];
    [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudMinus"] status:message];
    
    if (self.completion) {
        self.completion();
    }
}

@end
