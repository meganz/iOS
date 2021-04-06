
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
//        _networkQuality = session.networkQuality;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"peerid=%llu clientid=%llu video=%@, audio=%@", self.peerId, self.clientId, self.video ? @"YES" : @"NO", self.audio ? @"YES" : @"NO"];
}

- (BOOL)isEqualToPeer:(MEGAGroupCallPeer *)peer {
    return self.peerId == peer.peerId && self.clientId == peer.clientId;
}

@end
