
#import <Foundation/Foundation.h>

#import "MEGABaseRequestDelegate.h"

@interface MEGALoginRequestDelegate : MEGABaseRequestDelegate

@property (nonatomic, copy) void (^errorCompletion)(MEGAError *error);

@property (nonatomic) BOOL confirmAccountInOtherClient;

@end
