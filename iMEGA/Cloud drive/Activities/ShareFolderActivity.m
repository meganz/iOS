#import "ShareFolderActivity.h"

#import "MEGANavigationController.h"
#import "ContactsViewController.h"

@interface ShareFolderActivity ()

@property (strong, nonatomic) NSArray<MEGANode *> *nodes;

@end

@implementation ShareFolderActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    self = [super init];
    if (self) {
        _nodes = nodesArray;
    }
    return self;
}

- (NSString *)activityType {
    return MEGAUIActivityTypeShareFolder;
}

- (NSString *)activityTitle {
    if ([self.nodes count] == 1 && (self.nodes.firstObject).isShared) {
        return NSLocalizedString(@"Manage Share", @"Text indicating to the user the action that will be executed on tap.");
    }
    
    NSString *titleFormat = NSLocalizedString(@"general.menuAction.shareFolder.title", @"Title of folder menu action that allows sharing of folder/s to selected contacts e.g Share folder, Share folders");
    NSString *title = [NSString stringWithFormat:titleFormat, self.nodes.count];
    return title;
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_shareFolder"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (UIViewController *)activityViewController {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC;
    
    if ([self.nodes count] == 1 && (self.nodes.firstObject).isShared) {
        contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
        contactsVC.node = self.nodes.firstObject;
        contactsVC.contactsMode = ContactsModeFolderSharedWith;        
        [navigationController pushViewController:contactsVC animated:YES];
    } else {
        contactsVC = navigationController.viewControllers.firstObject;
        contactsVC.nodesArray = self.nodes;
        contactsVC.contactsMode = ContactsModeShareFoldersWith;
    }
    contactsVC.shareFolderActivity = self;
    
    return navigationController;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
