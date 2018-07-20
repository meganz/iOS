#import "ItemListModel.h"
#import "MEGAChatListItem.h"
#import "MEGAUser+MNZCategory.h"
#import "UIImage+MNZCategory.h"

@interface ItemListModel ()

@property MEGAChatListItem *chat;
@property MEGAUser *user;

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
    } else {
        return self.user.mnz_firstName;
    }
}

- (uint64_t)handle {
    if (self.user) {
        return self.user.handle;
    } else {
        return self.chat.peerHandle;
    }
}

- (BOOL)isEqual:(ItemListModel *)item {
    return self.handle == item.handle;
}

- (id)model {
    if (self.user) {
        return self.user;
    } else {
        return self.chat;
    }
}

@end
