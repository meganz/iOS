#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface MEGAAVViewController : AVPlayerViewController

@property (nonatomic, strong, nonnull) UIActivityIndicatorView  *activityIndicator;
@property (nonatomic, assign) BOOL hasPlayedOnceBefore;
@property (nonatomic, assign) BOOL isEndPlaying;
@property (nonatomic, strong, nullable) MEGANode *node;
@property (nonatomic, strong, nullable) NSURL *fileUrl;
@property (nonatomic, strong, nullable) MEGASdk *apiForStreaming;

- (instancetype _Nonnull)initWithURL:(NSURL *_Nonnull)fileUrl;
- (instancetype _Nonnull)initWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming;
- (NSString *_Nullable)fileFingerprint;

@end
