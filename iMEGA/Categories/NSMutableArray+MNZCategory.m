
#import "NSMutableArray+MNZCategory.h"

@implementation NSMutableArray (MNZCategory)

- (NSArray *)mnz_numberOfFilesAndFolders {
    NSUInteger numberOfFiles = 0;
    NSUInteger numberOfFolders = 0;
    for (NSUInteger i = 0; i < self.count; i++) {
        MEGANode *node = [self objectAtIndex:i];
        if (node.isFile) {
            numberOfFiles++;
        } else if (node.isFolder) {
            numberOfFolders++;
        }
    }
    
    return @[[NSNumber numberWithUnsignedInteger:numberOfFiles], [NSNumber numberWithUnsignedInteger:numberOfFolders]];
}

@end
