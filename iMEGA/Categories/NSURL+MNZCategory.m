
#import "NSURL+MNZCategory.h"

@implementation NSURL (MNZCategory)

- (URLType)mnz_type {
    URLType type = URLTypeDefault;
    
    if ([self.absoluteString rangeOfString:@"file:///"].location != NSNotFound) {
        return URLTypeOpenInLink;
    }
    
    NSString *afterSlashesString = [self mnz_afterSlashesString];
    
    if ([[afterSlashesString substringToIndex:2] isEqualToString:@"#!"]) {
        return URLTypeFileLink;
    }
    
    if ([[afterSlashesString substringToIndex:3] isEqualToString:@"#F!"]) {
        return URLTypeFolderLink;
    }
    
    if ([[afterSlashesString substringToIndex:3] isEqualToString:@"#P!"]) {
        return URLTypeEncryptedLink;
    }
    
    if ([[afterSlashesString substringToIndex:8] isEqualToString:@"#confirm"] || [[afterSlashesString substringToIndex:7] isEqualToString:@"confirm"]) {
        return URLTypeConfirmationLink;
    }
    
    if ([[afterSlashesString substringToIndex:10] isEqualToString:@"#newsignup"]) {
        return URLTypeNewSignUpLink;
    }
    
    if ([[afterSlashesString substringToIndex:7] isEqualToString:@"#backup"]) {
        return URLTypeBackupLink;
    }
    
    if ([[afterSlashesString substringToIndex:7] isEqualToString:@"#fm/ipc"]) {
        return URLTypeIncomingPendingContactsLink;
    }
    
    if ([[afterSlashesString substringToIndex:7] isEqualToString:@"#verify"]) {
        return URLTypeChangeEmailLink;
    }
    
    if ([[afterSlashesString substringToIndex:7] isEqualToString:@"#cancel"]) {
        return URLTypeCancelAccountLink;
    }
    
    if ([[afterSlashesString substringToIndex:8] isEqualToString:@"#recover"]) {
        return URLTypeRecoverLink;
    }
    
    if ([[afterSlashesString substringToIndex:8] isEqualToString:@"#fm/chat"]) {
        return URLTypeChatLink;
    }
    
    if ([[afterSlashesString substringToIndex:14] isEqualToString:@"#loginrequired"]) {
        return URLTypeLoginRequiredLink;
    }
    
    if ([afterSlashesString hasPrefix:@"#"]) {
        return URLTypeHandleLink;
    }
    
    return type;
}

- (NSString *)mnz_MEGAURL {
    NSString *afterSlashesString = [self mnz_afterSlashesString];
    if ([afterSlashesString hasPrefix:@"#"]) {
        return [NSString stringWithFormat:@"https://mega.nz/%@", [self mnz_afterSlashesString]];
    } else {
        return [NSString stringWithFormat:@"https://mega.nz/#%@", [self mnz_afterSlashesString]];
    }
}

- (NSString *)mnz_afterSlashesString {
    NSString *afterSlashesString;
    
    if ([self.scheme isEqualToString:@"mega"]) {
        // mega://<afterSlashesString>
        afterSlashesString = [self.absoluteString substringFromIndex:7];
    } else {
        // http(s)://(www.)mega(.co).nz/<afterSlashesString>
        NSArray<NSString *> *components = [self.absoluteString componentsSeparatedByString:@"/"];
        afterSlashesString = @"";
        for (NSUInteger i = 3; i < components.count; i++) {
            afterSlashesString = [NSString stringWithFormat:@"%@%@/", afterSlashesString, [components objectAtIndex:i]];
        }
        afterSlashesString = [afterSlashesString substringToIndex:(afterSlashesString.length - 1)];
    }
    
    return afterSlashesString;
}

@end
