
#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface MEGAAVViewController : AVPlayerViewController

- (instancetype)initWithURL:(NSURL *)fileUrl;
- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink apiForStreaming:(MEGASdk *)apiForStreaming;

@end
