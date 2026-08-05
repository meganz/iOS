#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AVViewModel;
@class VideoMetricsTracker;

@interface MEGAAVViewController : AVPlayerViewController

@property (nonatomic, strong, nonnull) AVViewModel *viewModel;
@property (nonatomic, strong, nonnull) UIActivityIndicatorView  *activityIndicator;
@property (nonatomic, assign) BOOL hasPlayedOnceBefore;
@property (nonatomic, assign) BOOL isEndPlaying;
@property (nonatomic, strong, nullable) MEGANode *node;
@property (nonatomic, strong, nullable) NSURL *fileUrl;
@property (nonatomic, strong, nullable) MEGASdk *apiForStreaming;
@property (nonatomic, assign) BOOL isFolderLink;
@property (nonatomic, copy, nullable) NSString *fileLink;
@property (nonatomic, assign) BOOL isFromAlbumLink;
@property (nonatomic, strong, nonnull) NSMutableSet *subscriptions;
/// Holds the single `AVPlayer.rate` observer that keeps the streaming throttle in sync with playback speed.
/// Typed `id` because it stores a Swift `AnyCancellable`, which has no Objective-C representation.
/// Kept out of `subscriptions` so a re-registration replaces the observer in place instead of stacking another one.
@property (nonatomic, strong, nullable) id throttleRateSubscription;
@property (nonatomic, assign) NSTimeInterval startTimeStamp;
@property (nonatomic, strong, nullable) VideoMetricsTracker *metricsTracker;

- (instancetype _Nonnull)initWithURL:(NSURL *_Nonnull)fileUrl;
- (instancetype _Nonnull)initWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming;
- (NSString *_Nullable)fileFingerprint;

@end
