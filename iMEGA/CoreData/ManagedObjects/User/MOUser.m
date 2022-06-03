#import "MOUser.h"
#import "NSString+MNZCategory.h"

@implementation MOUser

// Insert code here to add functionality to your managed object subclass
- (NSString *)description {
#ifdef DEBUG
    return [NSString stringWithFormat:@"<%@: base64Handle=%@, email=%@, firstname=%@, lastname=%@, nickname=%@ interactedWith=%@>",
            self.class, self.base64userHandle, self.email, self.firstname, self.lastname, self.nickname, self.interactedwith];
#else
    return [NSString stringWithFormat:@"<%@: base64Handle=%@>",
            self.class, self.base64userHandle];
#endif
}

- (NSString *)fullName {
    NSString *fullName;
    if (self) {
        if (self.firstname) {
            fullName = self.firstname;
            if (self.lastname && !self.lastname.mnz_isEmpty) {
                fullName = [[fullName stringByAppendingString:@" "] stringByAppendingString:self.lastname];
            }
        } else {
            if (self.lastname) {
                fullName = self.lastname;
            }
        }
    }
    
    if (fullName.mnz_isEmpty) {
        fullName = nil;
    }
    
    return fullName ?: self.email;
}

- (NSString *)firstName {
    NSString *firstname;
    if (self) {
        if (self.firstname) {
            firstname = self.firstname;
        }
    }
    
    return firstname;
}

- (NSNumber *)interactedWith {
    NSNumber * interactedWith = [NSNumber numberWithBool:NO];
    if (self) {
        if (self.interactedwith != nil) {
            interactedWith = self.interactedwith;
        }
    }
    
    return interactedWith;
}

- (NSString *)displayName {
    if (self.nickname != nil && !self.nickname.mnz_isEmpty) {
        return self.nickname;
    }
    
    return self.fullName;
}

@end
