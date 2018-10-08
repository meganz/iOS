
#import "MEGAGroupCallPeer.h"

#import "MEGAChatSession.h"

@implementation MEGAGroupCallPeer

- (instancetype)initWithSession:(MEGAChatSession *)session {
    self = [super init];
    if (self) {
        _peerId = session.peerId;
        _video = session.hasVideo;
        _audio = session.hasAudio;
        _networkQuality = session.networkQuality;
    }
    return self;
}

- (void)updateWithSession:(MEGAChatSession *)session {
    self.video = session.hasVideo;
    self.audio = session.hasAudio;
    self.networkQuality = session.networkQuality;
}

@end
