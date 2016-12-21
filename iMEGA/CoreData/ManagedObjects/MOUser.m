#import "MOUser.h"

@implementation MOUser

// Insert code here to add functionality to your managed object subclass
- (NSString *)description {    
    return [NSString stringWithFormat:@"<%@: base64Handle=%@, firstname=%@, lastname=%@, email=%@>",
            [self class], self.base64userHandle, self.firstname, self.lastname, self.email];
}

@end
