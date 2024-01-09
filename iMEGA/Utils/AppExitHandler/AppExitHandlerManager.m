#import <Foundation/Foundation.h>
#import "AppExitHandlerManager.h"

@implementation AppExitHandlerManager

- (void)registerExitHandler:(void (^)(void))action {
    atexit_b(^{
        action();
    });
}
@end

