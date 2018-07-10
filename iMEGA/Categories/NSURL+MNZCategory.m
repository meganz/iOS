
#import "NSURL+MNZCategory.h"

@implementation NSURL (MNZCategory)

- (URLType)mnz_type {
    URLType type = URLTypeDefault;
    
    if ([self.absoluteString rangeOfString:@"file:///"].location != NSNotFound) {
        return URLTypeOpenInLink;
    }
    
    NSString *afterSlashesString = [self mnz_afterSlashesString];
    
    if (afterSlashesString.length < 2) {
        return URLTypeDefault;
    }
    
    if (afterSlashesString.length >= 2 && [[afterSlashesString substringToIndex:2] isEqualToString:@"#!"]) {
        return URLTypeFileLink;
    }
    
    if (afterSlashesString.length >= 3 && [[afterSlashesString substringToIndex:3] isEqualToString:@"#F!"]) {
        return URLTypeFolderLink;
    }
    
    if (afterSlashesString.length >= 3 && [[afterSlashesString substringToIndex:3] isEqualToString:@"#P!"]) {
        return URLTypeEncryptedLink;
    }
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#confirm"]) {
        return URLTypeConfirmationLink;
    }
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"confirm"]) {
        return URLTypeConfirmationLink;
    }
    
    if (afterSlashesString.length >= 10 && [[afterSlashesString substringToIndex:10] isEqualToString:@"#newsignup"]) {
        return URLTypeNewSignUpLink;
    }
    
    if ((afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#backup"]) || (afterSlashesString.length >= 6 && [[afterSlashesString substringToIndex:6] isEqualToString:@"backup"])) {
        return URLTypeBackupLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#fm/ipc"]) {
        return URLTypeIncomingPendingContactsLink;
    }
    
    if (afterSlashesString.length >= 6 && [[afterSlashesString substringToIndex:6] isEqualToString:@"fm/ipc"]) {
        return URLTypeIncomingPendingContactsLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#verify"]) {
        return URLTypeChangeEmailLink;
    }
    
    if (afterSlashesString.length >= 7 && [[afterSlashesString substringToIndex:7] isEqualToString:@"#cancel"]) {
        return URLTypeCancelAccountLink;
    }
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#recover"]) {
        return URLTypeRecoverLink;
    }
    
    if (afterSlashesString.length >= 3 && [[afterSlashesString substringToIndex:3] isEqualToString:@"#C!"]) {
        return URLTypeContactLink;
    }
    if (afterSlashesString.length >= 2 && [[afterSlashesString substringToIndex:2] isEqualToString:@"C!"]) {
        return URLTypeContactLink;
    }
    
    if (afterSlashesString.length >= 8 && [[afterSlashesString substringToIndex:8] isEqualToString:@"#fm/chat"]) {
        return URLTypeChatLink;
    }
    
    if (afterSlashesString.length >= 14 && [[afterSlashesString substringToIndex:14] isEqualToString:@"#loginrequired"]) {
        return URLTypeLoginRequiredLink;
    }
    
    if (afterSlashesString.length >= 1 && [afterSlashesString hasPrefix:@"#"]) {
        return URLTypeHandleLink;
    }
    
    if (afterSlashesString.length >= 12 && [[afterSlashesString substringToIndex:12] isEqualToString:@"achievements"]) {
        return URLTypeAchievementsLink;
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
        if (afterSlashesString.length > 0) {
            afterSlashesString = [afterSlashesString substringToIndex:(afterSlashesString.length - 1)];
        }
    }
    
    return afterSlashesString;
}

@end
