
#import "GetLinkActivity.h"

#import "SVProgressHUD.h"

#import "CopyrightWarningViewController.h"
#import "GetLinkTableViewController.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "UIApplication+MNZCategory.h"

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
    BOOL areExportedNodes = YES;
    for (MEGANode *node in self.nodes) {
        if (!node.isExported) {
            areExportedNodes = NO;
            break;
        }
    }
    
    NSString *activityTitle;
    if (self.nodes.count > 1) {
        activityTitle = areExportedNodes ? AMLocalizedString(@"manageLinks", @"A menu item in the right click context menu in the Cloud Drive. This menu item will take the user to a dialog where they can manage the public folder/file links which they currently have selected.") : AMLocalizedString(@"getLinks", @"Title shown under the action that allows you to get several links to files and/or folders");
    } else {
        activityTitle = areExportedNodes ? AMLocalizedString(@"manageLink", @"Item menu option upon right click on one or multiple files.") : AMLocalizedString(@"getLink", @"Title shown under the action that allows you to get a link to file or folder");
    }
    
    return activityTitle;
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_getLink"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [CopyrightWarningViewController presentGetLinkViewControllerForNodes:self.nodes inViewController:UIApplication.mnz_visibleViewController];
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
