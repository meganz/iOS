/**
 * @file ShareFolderActivity.m
 * @brief UIActivity for sharing a folder with a contact
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

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

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    
}

- (void)performActivity {
    
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end

