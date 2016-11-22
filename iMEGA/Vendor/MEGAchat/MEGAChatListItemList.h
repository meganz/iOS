#import <Foundation/Foundation.h>
#import "MEGAChatListItem.h"

@interface MEGAChatListItemList : NSObject


@property (readonly, nonatomic) NSUInteger size;

- (instancetype)clone;

- (MEGAChatListItem *)chatListItemAtIndex:(NSUInteger)index;

@end
