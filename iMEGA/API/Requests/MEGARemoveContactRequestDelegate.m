
#import "MEGARemoveContactRequestDelegate.h"

#import "SVProgressHUD.h"

#import "MEGAUser+MNZCategory.h"

@interface MEGARemoveContactRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGARemoveContactRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
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
    
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        NSString *message;
        if (self.totalRequests <= 1) {
            MEGAUser *user = [api contactForEmail:request.email];
            message = [NSString stringWithFormat:AMLocalizedString(@"removedContact", @"Success message shown when the selected contact has been removed. 'Contact {Name of contact} removed'"), user.mnz_displayName];
        } else {
            message = [NSString stringWithFormat:AMLocalizedString(@"removedContacts", @"Success message shown when the selected contacts have been removed"), self.totalRequests];
        }
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
