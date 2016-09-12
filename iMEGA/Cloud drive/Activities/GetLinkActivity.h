#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface GetLinkActivity : UIActivity

- (instancetype)initWithNode:(MEGANode *)nodeCopy;
- (instancetype)initWithNodes:(NSArray *)nodesArray;

@end
