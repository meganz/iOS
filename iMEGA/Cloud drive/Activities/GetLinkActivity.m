#import "GetLinkActivity.h"

#import "CopyrightWarningViewController.h"
#import "GetLinkTableViewController.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface GetLinkActivity ()

@property (strong, nonatomic) NSArray *nodes;

@end

@implementation GetLinkActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    self = [super init];
    if (self) {
        _nodes = nodesArray;
    }
    return self;
}

- (NSString *)activityType {
    return @"GetLinkActivity";
}

- (NSString *)activityTitle {
    if ([self.nodes count] > 1) {
        return AMLocalizedString(@"getLinks", nil);
    }
    
    return AMLocalizedString(@"getLink", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_getLink"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.nodes != nil) {
            if ([[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"agreedCopywriteWarning"]) {
                UINavigationController *getLinkNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
                GetLinkTableViewController *getLinkTVC = getLinkNavigationController.childViewControllers[0];
                getLinkTVC.nodesToExport = self.nodes;
                [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:getLinkNavigationController animated:YES completion:nil];
            } else {
                UINavigationController *cwNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CopywriteWarningNavigationControllerID"];
                CopyrightWarningViewController *cwViewController = cwNavigationController.childViewControllers[0];
                [cwViewController setNodesToExport:self.nodes];
                [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:cwNavigationController animated:YES completion:nil];
            }
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
