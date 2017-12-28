
#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface MEGAAVViewController : UIViewController

@property (nonatomic) BOOL peekAndPop;

- (instancetype)initWithURL:(NSURL *)path;
- (instancetype)initWithNode:(MEGANode *)node folderLink:(BOOL)folderLink;

@end
