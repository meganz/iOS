#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface RemoveLinkActivity : UIActivity

- (instancetype)initWithNode:(MEGANode *)nodeCopy;
- (instancetype)initWithNodes:(NSArray *)nodesArray;

@end
