#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AVViewModel;

@interface MEGAAVViewController : AVPlayerViewController

@property (nonatomic, strong, nonnull) AVViewModel *viewModel;
@property (nonatomic, strong, nonnull) UIActivityIndicatorView  *activityIndicator;
@property (nonatomic, assign) BOOL hasPlayedOnceBefore;
@property (nonatomic, assign) BOOL isEndPlaying;
@property (nonatomic, strong, nullable) MEGANode *node;
@property (nonatomic, strong, nullable) NSURL *fileUrl;
@property (nonatomic, strong, nullable) MEGASdk *apiForStreaming;
@property (nonatomic, assign) BOOL isFolderLink;
@property (nonatomic, strong, nonnull) NSMutableSet *subscriptions;

- (instancetype _Nonnull)initWithURL:(NSURL *_Nonnull)fileUrl;
- (instancetype _Nonnull)initWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming;
- (NSString *_Nullable)fileFingerprint;

@end
