#import <Foundation/Foundation.h>

@class MEGAChatListItem;

@interface ItemListModel : NSObject

@property MEGAUser *user;

@property (readonly) BOOL isGroup;
@property (readonly) NSString *name;
@property (readonly) uint64_t handle;
@property (readonly) id model;
@property (readonly) BOOL isNoteToSelf;
@property (readonly) UIImage *noteToSelfImage;

- (instancetype)initWithChat:(MEGAChatListItem *)chat;

- (instancetype)initWithUser:(MEGAUser *)user;

- (instancetype)initWithEmail:(NSString *)email;

- (BOOL)isEqual:(ItemListModel *)item;

@end
