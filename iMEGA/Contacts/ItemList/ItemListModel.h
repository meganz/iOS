#import <Foundation/Foundation.h>

@class MEGAChatListItem;

@interface ItemListModel : NSObject

@property (readonly) BOOL isGroup;
@property (readonly) NSString *name;
@property (readonly) uint64_t handle;
@property (readonly) id model;

- (instancetype)initWithChat:(MEGAChatListItem *)chat;

- (instancetype)initWithUser:(MEGAUser *)user;

- (BOOL)isEqual:(ItemListModel *)item;

@end
