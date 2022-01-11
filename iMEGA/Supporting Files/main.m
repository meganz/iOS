#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MEGAApplication.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc,
                                 argv,
                                 NSStringFromClass([MEGAApplication class]),
                                 NSStringFromClass(NSClassFromString(@"TestingAppDelegate")?: [AppDelegate class]));
    }
}
