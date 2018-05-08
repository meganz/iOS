#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ContactsMode) {
    ContactsModeDefault = 0,
    ContactsModeShareFoldersWith,
    ContactsModeFolderSharedWith,
    ContactsModeChatStartConversation,
    ContactsModeChatAddParticipant,
    ContactsModeChatAttachParticipant,
    ContactsModeChatCreateGroup,
    ContactsModeChatNamingGroup
};

@class ShareFolderActivity;

@interface ContactsViewController : UIViewController

@property (nonatomic) ContactsMode contactsMode;

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) ShareFolderActivity *shareFolderActivity;

@property (nonatomic, copy) void(^userSelected)(NSArray *,  NSString *);

@property (strong, nonatomic) NSMutableDictionary *participantsMutableDictionary;

@end
