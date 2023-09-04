#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@protocol MEGAAVViewControllerDelegate;

@interface MEGAAVViewController : AVPlayerViewController

@property (nonatomic, weak, nullable) id<MEGAAVViewControllerDelegate> avViewControllerDelegate;

- (instancetype _Nonnull)initWithURL:(NSURL *_Nonnull)fileUrl;
- (instancetype _Nonnull)initWithNode:(MEGANode * _Nonnull)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk * _Nonnull)apiForStreaming;
- (NSString *_Nullable)fileFingerprint;

@end
