#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, ContactDetailsMode) {
    ContactDetailsModeDefault = 0,
    ContactDetailsModeFromChat,
};

@interface ContactDetailsViewController : UIViewController

@property (nonatomic) ContactDetailsMode contactDetailsMode;

@property (nonatomic) uint64_t chatId;

@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic) uint64_t userHandle;

@end
