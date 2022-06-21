
#import <UIKit/UIKit.h>

@interface MEGAApplication : UIApplication

@end

@protocol MEGAApplicationDelegate <UIApplicationDelegate>

- (void)application:(MEGAApplication *)application willSendTouchEvent:(UIEvent *)event;

@end
