#import "ShareFolderActivity.h"

#import "MEGANavigationController.h"
#import "ContactsViewController.h"

@interface ShareFolderActivity ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSArray *nodes;

@property (nonatomic) ContactsMode contactsMode;

@end

@implementation ShareFolderActivity

- (instancetype)initWithNode:(MEGANode *)nodeCopy {
    _node = nodeCopy;
    _contactsMode = ContactsShareFolderWith;
    
    return self;
}

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    _nodes = nodesArray;
    _contactsMode = ContactsShareFoldersWith;
    
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
    if (self.contactsMode == ContactsShareFolderWith) {
        [contactsVC setNode:self.node];
    } else if (self.contactsMode == ContactsShareFoldersWith) {
        [contactsVC setNodesArray:self.nodes];
    }
    [contactsVC setContactsMode:self.contactsMode];
    [contactsVC setShareFolderActivity:self];
    
    return navigationController;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
