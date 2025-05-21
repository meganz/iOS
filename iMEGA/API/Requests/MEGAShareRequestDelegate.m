#import "MEGAShareRequestDelegate.h"
#import "SVProgressHUD.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif
@import MEGAL10nObjc;

@interface MEGAShareRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic, getter=isChangingPermissions) BOOL changingPermissions;
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGAShareRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
        _changingPermissions = NO;
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initToChangePermissionsWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
        _changingPermissions = YES;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    self.numberOfRequests--;
    
    if (error.type) {
        if (error.type != MEGAErrorTypeApiEBusinessPastDue) {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
        } else {
            [SVProgressHUD dismiss];
        }
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        if (self.isChangingPermissions) {
            if (request.access == MEGANodeAccessLevelAccessUnknown) {
                if (self.totalRequests > 1) {
                    [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudForbidden"] status:LocalizedString(@"sharesRemoved", @"Message shown when some shares have been removed")];
                } else {
                    [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudForbidden"] status:LocalizedString(@"shareRemoved", @"Message shown when a share have been removed")];
                }
            } else {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"permissionsChanged", @"Message shown when you have changed the permissions of a shared folder")];
            }
        } else {
            NSString *statusMessage = [NSString stringWithFormat:LocalizedString(@"general.menuAction.shareFolders.successMessage", @"Success message for sharing single or multiple folders."), self.totalRequests];
            [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudSharedFolder"] status:statusMessage];
        }
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
