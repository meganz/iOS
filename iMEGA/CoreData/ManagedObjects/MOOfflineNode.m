#import "MOOfflineNode.h"


@implementation MOOfflineNode

@dynamic base64Handle;
@dynamic localPath;
@dynamic parentBase64Handle;
@dynamic fingerprint;

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: base64Handle=%@, localpath=%@, parentBase64Handle=%@, fingerprint=%@>",
            [self class], self.base64Handle, self.localPath, self.parentBase64Handle, self.fingerprint];
}

@end
