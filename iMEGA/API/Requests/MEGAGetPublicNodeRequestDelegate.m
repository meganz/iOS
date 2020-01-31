
#import "MEGAGetPublicNodeRequestDelegate.h"

@interface MEGAGetPublicNodeRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);

@end

@implementation MEGAGetPublicNodeRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type == MEGAErrorTypeApiOk && self.savePublicHandle && request.publicNode) {
        [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:request.publicNode.handle] forKey:MEGALastPublicHandleAccessed];
        [NSUserDefaults.standardUserDefaults setInteger:AffiliateTypeFileFolder forKey:MEGALastPublicTypeAccessed];
        [NSUserDefaults.standardUserDefaults setDouble:NSDate.date.timeIntervalSince1970 forKey:MEGALastPublicTimestampAccessed];
    }
    
    if (self.completion) {
        self.completion(request, error);
    }
}

@end
