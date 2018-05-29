
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, URLType) {
    URLTypeDefault,
    URLTypeFileLink,
    URLTypeFolderLink,
    URLTypeEncryptedLink,
    URLTypeConfirmationLink,
    URLTypeOpenInLink,
    URLTypeNewSignUpLink,
    URLTypeBackupLink,
    URLTypeIncomingPendingContactsLink,
    URLTypeChangeEmailLink,
    URLTypeCancelAccountLink,
    URLTypeRecoverLink,
    URLTypeContactLink,
    URLTypeChatLink,
    URLTypeLoginRequiredLink,
    URLTypeHandleLink
};

@interface NSURL (MNZCategory)

- (URLType)mnz_type;
- (NSString *)mnz_MEGAURL;
- (NSString *)mnz_afterSlashesString;

- (void)mnz_showLinkView;

@end
