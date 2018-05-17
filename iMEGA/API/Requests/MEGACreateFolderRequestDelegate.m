
#import "MEGACreateFolderRequestDelegate.h"

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

@interface MEGACreateFolderRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request);

@end

@implementation MEGACreateFolderRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion {
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
    
    if (error.type) {
        if (error.type == MEGAErrorTypeApiEAccess) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"permissionTitle", @"Error title shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") message:AMLocalizedString(@"permissionMessage", @"Error message shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
        } else {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
        }
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
