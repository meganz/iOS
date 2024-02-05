#import "MediaInfoLoader.h"
#import "LoadMediaInfoOperation.h"
#import "MEGA-Swift.h"

@interface MediaInfoLoader ()

@property (strong, nonatomic) NSOperationQueue *mediaInfoLoadQueue;

@end

@implementation MediaInfoLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        _mediaInfoLoadQueue = [[NSOperationQueue alloc] init];
        _mediaInfoLoadQueue.name = @"mediaInfoLoadQueue";
        _mediaInfoLoadQueue.qualityOfService = NSQualityOfServiceUtility;
    }
    return self;
}

- (BOOL)isMediaInfoLoaded {
    return [MEGASdk.shared ensureMediaInfo];
}

- (void)loadMediaInfoWithTimeout:(NSTimeInterval)timeout completion:(void (^)(BOOL loaded))completion {
    if (self.isMediaInfoLoaded) {
        completion(YES);
    } else {
        LoadMediaInfoOperation *loadMediaInfoOperation = [[LoadMediaInfoOperation alloc] initWithExpireTimeInterval:timeout];
        NSBlockOperation *callBackOperation = [NSBlockOperation blockOperationWithBlock:^{
            completion(self.isMediaInfoLoaded);
        }];
        [callBackOperation addDependency:loadMediaInfoOperation];
        [self.mediaInfoLoadQueue addOperations:@[loadMediaInfoOperation, callBackOperation] waitUntilFinished:NO];
    }
}

@end
