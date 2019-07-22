
#import "MEGARemoveContactRequestDelegate.h"

#import "SVProgressHUD.h"

#import "MEGAUser+MNZCategory.h"

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

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    MEGAUser *user = [api contactForEmail:request.email];
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        switch (error.type) {
            case MEGAErrorTypeApiEMasterOnly: {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"You cannot remove %@ as a contact as they are part of your Business account.", @"Error shown when a Business account user (sub-user or admin) tries to remove a contact which is part of the same Business account. %@ will be replaced with the name or email of the account, for example: Jane Appleseed or ja@mega.nz"), user.mnz_fullName]];
                break;
            }
                
            default:
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
                break;
        }
        return;
    }
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    NSString *message = [NSString stringWithFormat:AMLocalizedString(@"removedContact", @"Success message shown when the selected contact has been removed. 'Contact {Name of contact} removed'"), user.mnz_fullName];
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
    
    if (self.completion) {
        self.completion();
    }
}

@end
