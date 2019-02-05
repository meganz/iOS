
#import <Foundation/Foundation.h>

@class MEGAChatSession;

NS_ASSUME_NONNULL_BEGIN

@interface MEGAGroupCallPeer : NSObject

@property (assign, nonatomic) uint64_t peerId;
@property (assign, nonatomic) uint64_t clientId;
@property (assign, nonatomic) BOOL video;
@property (assign, nonatomic) BOOL audio;
@property (assign, nonatomic) NSUInteger networkQuality;

- (instancetype)initWithSession:(MEGAChatSession *)session;

- (BOOL)isEqualToPeer:(MEGAGroupCallPeer *)peer;

@end

NS_ASSUME_NONNULL_END
