#import "MEGAParticipant.h"

@implementation MEGAParticipant

#pragma mark - Initialization

- (instancetype)initWithName:(NSString *)name email:(NSString *)email handle:(uint64_t)handle chatRoomPrivilege:(MEGAChatRoomPrivilege)chatRoomPrivilege {
    self = [super init];
    
    if (self) {
        _name  = name;
        _email = email;
        _handle = handle;
        _chatRoomPrivilege = chatRoomPrivilege;
    }
    
    return self;
}

@end
