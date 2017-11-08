
#import "MEGABaseRequestDelegate.h"

@interface MEGARemoveRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithMode:(NSInteger)mode numberOfFilesAndFolders:(NSArray *)numberOfFilesAndFoldersArray completion:(void (^)(void))completion;

@end
