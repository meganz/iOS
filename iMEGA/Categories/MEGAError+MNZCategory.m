
#import "MEGAError+MNZCategory.h"

@implementation MEGAError (MNZCategory)

- (NSError *)nativeError {
    return [NSError errorWithDomain:@"nz.mega.MEGAError" code:self.type userInfo:@{NSLocalizedDescriptionKey : self.name ?: @""}];
}

@end
