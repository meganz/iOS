
#import "MEGANodeList+MNZCategory.h"

@implementation MEGANodeList (MNZCategory)

- (NSArray *)mnz_numberOfFilesAndFolders {
    NSUInteger numberOfFiles = 0;
    NSUInteger numberOfFolders = 0;
    for (NSUInteger i = 0; i < self.size.unsignedIntegerValue; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        if (node.isFile) {
            numberOfFiles++;
        } else if (node.isFolder) {
            numberOfFolders++;
        }
    }
    
    return @[[NSNumber numberWithUnsignedInteger:numberOfFiles], [NSNumber numberWithUnsignedInteger:numberOfFolders]];
}

- (BOOL)mnz_existsFolderWithName:(NSString *)name {
    BOOL folderAlreadyExists = NO;
    for (NSUInteger i = 0; i < self.size.unsignedIntegerValue; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        if (node.isFolder && [node.name isEqualToString:name]) {
            folderAlreadyExists = YES;
            break;
        }
    }
    
    return folderAlreadyExists;
}

- (NSArray *)mnz_nodesArrayFromNodeList {
    NSUInteger nodeListCount = self.size.unsignedIntegerValue;
    NSMutableArray *nodesMutableArray = [[NSMutableArray alloc] initWithCapacity:nodeListCount];
    for (NSUInteger i = 0; i < nodeListCount; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        [nodesMutableArray addObject:node];
    }
    
    return nodesMutableArray;
}

@end
