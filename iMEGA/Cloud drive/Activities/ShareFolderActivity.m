#import "ShareFolderActivity.h"

#import "MEGANavigationController.h"
#import "ContactsViewController.h"

@interface ShareFolderActivity ()

@property (strong, nonatomic) NSArray *nodes;

@end

@implementation ShareFolderActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    _nodes = nodesArray;
    
    return self;
}

- (NSString *)activityType {
    return @"ShareFolderActivity";
}

- (NSString *)activityTitle {
    if ([self.nodes count] > 1) {
        return AMLocalizedString(@"shareFolders", nil);
    }
    
    return AMLocalizedString(@"shareFolder", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_shareFolder"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (UIViewController *)activityViewController {
    
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.nodesArray = self.nodes;
    contactsVC.contactsMode = ContactsShareFoldersWith;
    [contactsVC setShareFolderActivity:self];
    
    return navigationController;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
