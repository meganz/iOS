#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface MEGAActivityItemProvider : UIActivityItemProvider

- (instancetype)initWithPlaceholderString:(NSString*)placeholder node:(MEGANode *)node;

@end
