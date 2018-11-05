
#import "MEGATransactionOperation.h"

@implementation MEGATransactionOperation

- (void)start {
    [super start];
    
    for (NSOperation *operation in self.dependencies) {
        if (operation.isCancelled) {
            [self cancelOperation];
            return;
        }
        
        if ([operation isKindOfClass:[MEGATransactionOperation class]] && [(MEGATransactionOperation *)operation didFinishWithError]) {
            [self cancelOperation];
            return;
        }
    }
}

@end
