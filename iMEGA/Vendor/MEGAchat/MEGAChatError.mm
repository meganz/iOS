#import "MEGAChatError.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatError()

@property MegaChatError *megaChatError;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatError

- (instancetype)initWithMegaChatError:(MegaChatError *)megaChatError cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatError = megaChatError;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn) {
        delete _megaChatError;
    }
}

- (instancetype)clone {
    return self.megaChatError ? [[MEGAChatError alloc] initWithMegaChatError:self.megaChatError->copy() cMemoryOwn:YES] : nil;
}

- (MegaChatError *)getCPtr {
    return self.megaChatError;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: name=%@, type=%@>",
            [self class], self.name, @(self.type)];
}

- (MEGAChatErrorType)type {
    return (MEGAChatErrorType) (self.megaChatError ? self.megaChatError->getErrorCode() : 0);
}

- (NSString *)name {
    return self.megaChatError->getErrorString() ? [[NSString alloc] initWithUTF8String:self.megaChatError->getErrorString()] : nil;
}

@end
