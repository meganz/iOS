#import <UIKit/UIKit.h>

@interface MEGAActivityItemProvider : UIActivityItemProvider

- (instancetype)initWithPlaceholderString:(NSString *)placeholder node:(MEGANode *)node api:(MEGASdk *)api;

@end
