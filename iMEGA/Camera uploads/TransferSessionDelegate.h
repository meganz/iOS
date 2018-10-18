
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TransferSessionTaskDelegate;

@interface TransferSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)addDelegate:(TransferSessionTaskDelegate *)delegate forTask:(NSURLSessionTask *)task;

@end

NS_ASSUME_NONNULL_END
