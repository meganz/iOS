#import "MEGAChatBaseRequestDelegate.h"

#import "SVProgressHUD.h"

@import MEGAL10nObjc;

@implementation MEGAChatBaseRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
        
    if (error.type) {
#ifndef MNZ_NOTIFICATION_EXTENSION
        if (request.type == MEGAChatRequestTypeChatLinkHandle && error.type == MEGAChatErrorTypeNoEnt) {
            return;
        }
        if (request.type == MEGAChatRequestTypeGetPeerAttributes) {
            return;
        }
        if (request.type == MEGAChatRequestTypeLoadPreview && (error.type == MegaChatErrorTypeExist || request.userHandle == MEGAInvalidHandle)) {
            return;
        }
        if ((request.type == MEGAChatRequestTypeAnswerChatCall || request.type == MEGAChatRequestTypeStartChatCall) && error.type == MEGAChatErrorTooMany) {
            [SVProgressHUD showErrorWithStatus:LocalizedString(@"Error. No more participants are allowed in this group call.", @"Message show when a call cannot be established because there are too many participants in the group call")];
            return;
        }
        if ((request.type == MEGAChatRequestTypeAutojoinPublicChat && error.type == MEGAChatErrorTypeArgs)
            || (request.type == MEGAChatRequestTypeAnswerChatCall && error.type == MegaChatErrorTypeExist)) {
            return;
        }

        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
#endif
    }
}

@end
