#import "ItemListModel.h"
#import "MEGAChatListItem.h"
#import "MEGAUser+MNZCategory.h"
#import "UIImage+MNZCategory.h"

@interface ItemListModel ()

@property MEGAChatListItem *chat;
@property MEGAUser *user;
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

- (BOOL)isGroup {
    if (self.chat) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)name {
    if (self.chat) {
        return self.chat.title;
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
