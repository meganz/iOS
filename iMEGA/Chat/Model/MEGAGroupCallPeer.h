
#import <Foundation/Foundation.h>

#import "CallPeerAudio.h"
#import "CallPeerVideo.h"

@class MEGAChatSession;

NS_ASSUME_NONNULL_BEGIN

@interface MEGAGroupCallPeer : NSObject

@property (assign, nonatomic) uint64_t peerId;
@property (assign, nonatomic) uint64_t clientId;
@property (assign, nonatomic) CallPeerVideo video;
@property (assign, nonatomic) CallPeerAudio audio;
@property (assign, nonatomic) NSUInteger networkQuality;
@property (strong, nonatomic) NSString *name;

- (instancetype)initWithSession:(MEGAChatSession *)session;

- (BOOL)isEqualToPeer:(MEGAGroupCallPeer *)peer;

@end

NS_ASSUME_NONNULL_END
