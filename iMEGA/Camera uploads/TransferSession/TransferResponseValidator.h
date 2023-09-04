#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TransferResponseValidator : NSObject

- (BOOL)validateURLResponse:(NSURLResponse *)URLResponse data:(nullable NSData *)data error:(NSError *__autoreleasing  _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
