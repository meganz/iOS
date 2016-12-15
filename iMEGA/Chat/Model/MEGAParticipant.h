#import <Foundation/Foundation.h>

#import "MEGAChatRoom.h"

@interface MEGAParticipant : NSObject

@property (nonatomic) uint64_t handle;

@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSString *email;

@property (nonatomic, readonly) MEGAChatRoomPrivilege chatRoomPrivilege;

#pragma mark - Initialization

- (id)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)name email:(NSString *)email handle:(uint64_t)handle chatRoomPrivilege:(MEGAChatRoomPrivilege)chatRoomPrivilege;

@end
