#import "MEGACreateFolderRequestDelegate.h"

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

@import MEGAL10nObjc;

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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (error.type == MEGAErrorTypeApiEAccess) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"permissionTitle", @"Error title shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") message:LocalizedString(@"permissionMessage", @"Error message shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
            [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        } else if (error.type != MEGAErrorTypeApiEBusinessPastDue) {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
        }
        return;
    }
    
    if (self.completion) {
        self.completion(request);
    }
}

@end
