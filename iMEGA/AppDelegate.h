#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MEGARequestDelegate, MEGATransferDelegate, MEGAGlobalDelegate, MEGAChatRequestDelegate> {

    UIBackgroundTaskIdentifier bgTask;
}

@property (strong, nonatomic) UIWindow *window;

@end
