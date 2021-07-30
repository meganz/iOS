#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ContactsMode) {
    ContactsModeDefault = 0,
    ContactsModeShareFoldersWith = 1,
    ContactsModeFolderSharedWith = 2,
    ContactsModeChatStartConversation = 3,
    ContactsModeChatAddParticipant = 4,
    ContactsModeChatAttachParticipant = 5,
    ContactsModeChatCreateGroup = 6,
    ContactsModeChatNamingGroup = 7
};

@protocol ContatctsViewControllerDelegate <NSObject>
@optional
- (void)nodeEditCompleted:(BOOL)complete;
@end

@class ShareFolderActivity;

@interface ContactsViewController : UIViewController

@property (nonatomic) ContactsMode contactsMode;
@property (nonatomic) BOOL avoidPresentIncomingPendingContactRequests;
@property (nonatomic) BOOL getChatLinkEnabled;

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) ShareFolderActivity *shareFolderActivity;

@property (nonatomic, copy) void(^userSelected)(NSArray *);
@property (nonatomic, copy) void(^chatSelected)(uint64_t);
@property (nonatomic, copy) void(^createGroupChat)(NSArray *,  NSString *, BOOL, BOOL);

@property (strong, nonatomic) NSMutableDictionary *participantsMutableDictionary;
@property (nonatomic, weak) id<ContatctsViewControllerDelegate> contatctsViewControllerDelegate;

@end
