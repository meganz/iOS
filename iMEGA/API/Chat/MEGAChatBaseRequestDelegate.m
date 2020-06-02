
#import "MEGAChatBaseRequestDelegate.h"

#import "SVProgressHUD.h"
#import "LocalizationSystem.h"

@implementation MEGAChatBaseRequestDelegate

- (void)onChatRequestStart:(MEGAChatSdk *)api request:(MEGAChatRequest *)request {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    if (error.type) {
        if (request.type == MEGAChatRequestTypeChatLinkHandle && error.type == MEGAErrorTypeApiENoent) {
            return;
        }
        if (request.type == MEGAChatRequestTypeLoadPreview && (error.type == MEGAErrorTypeApiEExist || request.userHandle == MEGAInvalidHandle)) {
            return;
        }

        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, AMLocalizedString(error.name, nil)]];
    }
}

@end
