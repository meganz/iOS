#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ContactsMode) {
    ContactsModeDefault = 0,
    ContactsModeShareFoldersWith,
    ContactsModeShareFoldersWithEmail,
    ContactsModeFolderSharedWith,
    ContactsModeChatStartConversation,
    ContactsModeChatAddParticipant
};

@class ShareFolderActivity;

@interface ContactsViewController : UIViewController

@property (nonatomic) ContactsMode contactsMode;

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) ShareFolderActivity *shareFolderActivity;

@property (nonatomic, copy) void(^userSelected)(NSArray *);

@property (strong, nonatomic) NSMutableDictionary *participantsMutableDictionary;

@end
