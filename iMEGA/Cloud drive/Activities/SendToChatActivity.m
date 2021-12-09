
#import "SendToChatActivity.h"

#import "MEGANavigationController.h"
#import "SendToViewController.h"

@interface SendToChatActivity () <SendToChatActivityDelegate>

@property (strong, nonatomic) NSArray *nodes;
@property (strong, nonatomic) NSString *text;

@end

@implementation SendToChatActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    self = [super init];
    if (self) {
        _nodes = nodesArray;
    }
    
    return self;
}

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        _text = text;
    }
    
    return self;
}

- (NSString *)activityType {
    return MEGAUIActivityTypeSendToChat;
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"sendToContact", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_sendToContact"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (UIViewController *)activityViewController {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"SendToNavigationControllerID"];
    SendToViewController *sendToViewController = navigationController.viewControllers.firstObject;
    sendToViewController.sendToChatActivityDelegate = self;
    if (self.text) {
        sendToViewController.sendMode = SendModeText;
    } else if (self.nodes) {
        sendToViewController.nodes = self.nodes;
        sendToViewController.sendMode = SendModeCloud;
    }
    
    return navigationController;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

#pragma mark - SendToChatActivityDelegate

- (void)sendToViewController:(SendToViewController *)viewController didFinishActivity:(BOOL)completed {
    [self activityDidFinish:completed];
}

- (NSString *)textToSend {
    return self.text;
}

@end
