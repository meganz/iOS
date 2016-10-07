#import <Foundation/Foundation.h>

@protocol MEGAChatLoggerDelegate <NSObject>

@optional

- (void)logWithLevel:(NSInteger)logLevel message:(NSString *)message;

@end
