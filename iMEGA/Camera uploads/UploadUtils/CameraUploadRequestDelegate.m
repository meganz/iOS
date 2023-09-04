#import "CameraUploadRequestDelegate.h"

@interface CameraUploadRequestDelegate ()

@property (copy, nonatomic) CameraUploadRequestCompletion completion;

@end

@implementation CameraUploadRequestDelegate

- (instancetype)initWithCompletion:(CameraUploadRequestCompletion)completion {
    self = [super init];
    if (self) {
        _completion = completion;
    }
    
    return self;
}


- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        if (self.completion) {
            self.completion(request, error);
        }
    });
}

@end
