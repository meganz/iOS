#import <Foundation/Foundation.h>
#import "MEGAChatRoom.h"

@interface MEGAChatRoomList : NSObject

@property (readonly, nonatomic) NSInteger size;

- (instancetype)clone;

- (MEGAChatRoom *)chatRoomAtIndex:(NSUInteger)index;

@end
