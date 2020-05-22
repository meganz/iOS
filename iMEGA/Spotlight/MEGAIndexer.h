
#import <Foundation/Foundation.h>

@interface MEGAIndexer : NSObject

@property (assign, nonatomic) BOOL enableSpotlight;

+ (instancetype)sharedIndexer;
- (void)reindexSpotlightIfNeeded;
- (void)generateAndSaveTree;
- (void)indexTree;
- (BOOL)index:(MEGANode *)node;
- (void)stopIndexing;
@end
