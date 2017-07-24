
#import <Foundation/Foundation.h>

@interface MEGAIndexer : NSObject

- (void)generateAndSaveTree;
- (void)saveTree;
- (void)indexTree;
- (BOOL)index:(MEGANode *)node;

@end
