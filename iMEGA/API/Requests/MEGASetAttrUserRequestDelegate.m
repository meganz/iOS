#import "MEGASetAttrUserRequestDelegate.h"

@interface MEGASetAttrUserRequestDelegate ()

@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGASetAttrUserRequestDelegate

- (instancetype)initWithCompletion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (self.completion) {
        self.completion();
    }
}

@end
