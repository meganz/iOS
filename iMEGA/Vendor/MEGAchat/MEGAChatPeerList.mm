#import "MEGAChatPeerList.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatPeerList ()

@property MegaChatPeerList *megaChatPeerList;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatPeerList

- (instancetype)initWithMegaChatPeerList:(megachat::MegaChatPeerList *)megaChatPeerList cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatPeerList = megaChatPeerList;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatPeerList;
    }
}

- (instancetype)clone {
    return self.megaChatPeerList ? [[MEGAChatPeerList alloc] initWithMegaChatPeerList:self.megaChatPeerList cMemoryOwn:YES] : nil;
}

- (MegaChatPeerList *)getCPtr {
    return self.megaChatPeerList;
}

- (NSInteger)size {
    return self.megaChatPeerList->size();
}

- (void)addPeerWithHandle:(uint64_t)hande privilege:(NSInteger)privilege {
    self.megaChatPeerList->addPeer(hande, (int)privilege);
}

- (uint64_t)peerHandleAtIndex:(NSInteger)index {
    return self.megaChatPeerList->getPeerHandle((int)index);
}

- (NSInteger)peerPrivilegeAtIndex:(NSInteger)index {
    return self.megaChatPeerList->getPeerPrivilege((int)index);
}

@end
