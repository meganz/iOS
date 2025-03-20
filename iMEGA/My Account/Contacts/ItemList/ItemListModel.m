#import "ItemListModel.h"
#import "MEGAChatListItem.h"
#import "MEGAUser+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#elif MNZ_WIDGET_EXTENSION
#import "MEGAWidgetExtension-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface ItemListModel ()

@property MEGAChatListItem *chat;
@property NSString *email;

@end

@implementation ItemListModel

- (instancetype)initWithChat:(MEGAChatListItem *)chat {
    self = [super init];
    if (self) {
        self.chat = chat;
    }
    return self;
}

- (instancetype)initWithUser:(MEGAUser *)user {
    self = [super init];
    if (self) {
        self.user = user;
    }
    return self;
}

- (instancetype)initWithEmail:(NSString *)email {
    self = [super init];
    if (self) {
        self.email = email;
    }
    return self;
}

- (BOOL)isNoteToSelf {
    if (self.chat) {
        return self.chat.isNoteToSelf;
    } else {
        return NO;
    }
}

- (BOOL)isGroup {
    if (self.chat) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)name {
    if (self.chat) {
        return self.chat.chatTitle;
    } else if (self.user) {
        NSString *nickname = self.user.mnz_nickname;
        if (nickname.length > 0) {
            return nickname;
        }
        
        return self.user.mnz_firstName;
    } else {
        return self.email;
    }
}

- (UIImage *)noteToSelfImage {
    return self.chat.noteToSelfImage;
}

- (uint64_t)handle {
    if (self.user) {
        return self.user.handle;
    } else if (self.chat) {
        return self.chat.chatId;
    } else {
        return MEGAInvalidHandle;
    }
}

- (BOOL)isEqual:(ItemListModel *)item {
    if (self.email) {
        return [self.email isEqualToString:item.email];
    } else {
        return self.handle == item.handle;
    }
}

- (id)model {
    if (self.user) {
        return self.user;
    } else if (self.chat) {
        return self.chat;
    } else {
        return self.email;
    }
}

@end
