
#import <Foundation/Foundation.h>

@interface MEGAIndexer : NSObject

- (void)generateAndSaveTree;
- (void)indexTree;
- (BOOL)index:(MEGANode *)node;
- (void)stopIndexing;
- (void)presentNodeFromSpotlight:(MEGANode *)node inNavigationController:(UINavigationController *)navigationController;

@end
