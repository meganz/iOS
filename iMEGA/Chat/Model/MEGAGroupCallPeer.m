
#import "MEGAGroupCallPeer.h"

#import "MEGAChatSession.h"

@implementation MEGAGroupCallPeer

- (instancetype)initWithSession:(MEGAChatSession *)session {
    self = [super init];
    if (self) {
        _peerId = session.peerId;
        _clientId = session.clientId;
        _video = session.hasVideo;
        _audio = session.hasAudio;
        _networkQuality = session.networkQuality;
    }
    return self;
}

- (BOOL)isEqualToPeer:(MEGAGroupCallPeer *)peer {
    return self.peerId == peer.peerId && self.clientId == peer.clientId;
}

@end
