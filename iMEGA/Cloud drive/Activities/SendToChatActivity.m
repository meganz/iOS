
#import "SendToChatActivity.h"

#import "MEGANavigationController.h"
#import "SendToViewController.h"

@interface SendToChatActivity ()

@property (strong, nonatomic) NSArray *nodes;

@end

@implementation SendToChatActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    self = [super init];
    if (self) {
        _nodes = nodesArray;
    }
    
    return self;
}

- (NSString *)activityType {
    return MEGAUIActivityTypeSendToChat;
}

- (NSString *)activityTitle {
    return AMLocalizedString(@"sendToContact", @"");
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
    sendToViewController.nodes = self.nodes;
    sendToViewController.sendMode = SendModeCloud;
    
    return navigationController;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
