
#import "MediaInfoLoader.h"
#import "MEGASdkManager.h"
#import "LoadMediaInfoOperation.h"

@interface MediaInfoLoader ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation MediaInfoLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

- (BOOL)isMediaInfoLoaded {
    return [MEGASdkManager.sharedMEGASdk ensureMediaInfo];
}

- (void)loadMediaInfoWithTimeout:(NSTimeInterval)timeout completion:(void (^)(BOOL loaded))completion {
    if (self.isMediaInfoLoaded) {
        completion(YES);
    } else {
        LoadMediaInfoOperation *loadMediaInfoOperation = [[LoadMediaInfoOperation alloc] initWithExpirationTimeInterval:timeout];
        NSBlockOperation *callBackOperation = [NSBlockOperation blockOperationWithBlock:^{
            completion(self.isMediaInfoLoaded);
        }];
        [callBackOperation addDependency:loadMediaInfoOperation];
        [self.operationQueue addOperations:@[loadMediaInfoOperation, callBackOperation] waitUntilFinished:NO];
    }
}

@end
