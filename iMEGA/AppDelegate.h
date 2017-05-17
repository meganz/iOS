#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"
#import "MEGAApplication.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MEGAApplicationDelegate, MEGARequestDelegate, MEGATransferDelegate, MEGAGlobalDelegate, MEGAChatRequestDelegate, MEGAChatDelegate> {

    UIBackgroundTaskIdentifier bgTask;
}

@property (strong, nonatomic) UIWindow *window;

@end
