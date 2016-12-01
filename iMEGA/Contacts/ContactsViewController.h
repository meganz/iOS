#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ContactsMode) {
    Contacts = 0,
    ContactsShareFolderWith,
    ContactsShareFolderWithEmail,
    ContactsShareFoldersWith,
    ContactsShareFoldersWithEmail,
    ContactsFolderSharedWith
};

@class ShareFolderActivity;

@interface ContactsViewController : UIViewController

@property (nonatomic) ContactsMode contactsMode;

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) ShareFolderActivity *shareFolderActivity;

@end
