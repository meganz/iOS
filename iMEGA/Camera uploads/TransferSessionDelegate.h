
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TransferSessionManager;

@interface TransferSessionDelegate : NSObject <NSURLSessionDataDelegate>

@property (weak, nullable, nonatomic) TransferSessionManager *manager;

- (instancetype)initWithManager:(TransferSessionManager *)manager;

@end

NS_ASSUME_NONNULL_END
