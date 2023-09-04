#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TransferSessionTaskDelegate, TransferSessionManager;

@interface TransferSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (instancetype)initWithSessionManager:(TransferSessionManager *)manager;

- (void)addDelegate:(TransferSessionTaskDelegate *)delegate forTask:(NSURLSessionTask *)task;

@end

NS_ASSUME_NONNULL_END
