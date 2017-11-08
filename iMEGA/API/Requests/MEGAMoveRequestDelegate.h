
#import "MEGABaseRequestDelegate.h"

@interface MEGAMoveRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithNumberOfFilesAndFolders:(NSArray *)numberOfFilesAndFoldersArray completion:(void (^)(void))completion;
- (instancetype)initToMoveToTheRubbishBinWithNumberOfFilesAndFolders:(NSArray *)numberOfFilesAndFoldersArray completion:(void (^)(void))completion;

@end
