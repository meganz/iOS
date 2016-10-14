#import <Foundation/Foundation.h>

@interface MEGAChatPeerList : NSObject

@property (readonly, nonatomic) NSInteger size;

- (instancetype)clone;

- (void)addPeerWithHandle:(uint64_t)hande privilege:(NSInteger)privilege;
- (uint64_t)peerHandleAtIndex:(NSInteger)index;
- (NSInteger)peerPrivilegeAtIndex:(NSInteger)index;

@end
