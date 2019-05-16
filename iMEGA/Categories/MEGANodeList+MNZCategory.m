
#import "MEGANodeList+MNZCategory.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

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

- (BOOL)mnz_existsFileWithName:(NSString *)name {
    BOOL fileAlreadyExists = NO;
    for (NSUInteger i = 0; i < self.size.unsignedIntegerValue; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        if (node.isFile && [node.name isEqualToString:name]) {
            fileAlreadyExists = YES;
            break;
        }
    }
    
    return fileAlreadyExists;
    
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

- (NSMutableArray *)mnz_mediaNodesMutableArrayFromNodeList {
    NSUInteger nodeListCount = self.size.unsignedIntegerValue;
    NSMutableArray *mediaNodesMutableArray = [[NSMutableArray alloc] initWithCapacity:nodeListCount];
    for (NSUInteger i = 0; i < nodeListCount; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
            [mediaNodesMutableArray addObject:node];
        }
    }
    
    return mediaNodesMutableArray;
}

- (BOOL)mnz_containsNodeWithParentFolderName:(NSString *)name {
    BOOL hasMatchedNode = NO;
    for (NSUInteger i = 0; i < self.size.unsignedIntegerValue; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        MEGANode *parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:node.parentHandle];
        if (parentNode.isFolder && [parentNode.name isEqualToString:name]) {
            hasMatchedNode = YES;
            break;
        }
    }
    
    return hasMatchedNode;
}


- (BOOL)mnz_containsNodeWithRestoreFolderName:(NSString *)name {
    BOOL hasMatchedNode = NO;
    for (NSUInteger i = 0; i < self.size.unsignedIntegerValue; i++) {
        MEGANode *node = [self nodeAtIndex:i];
        MEGANode *restoreNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:node.restoreHandle];
        if (restoreNode.isFolder && [restoreNode.name isEqualToString:name]) {
            hasMatchedNode = YES;
            break;
        }
    }
    
    return hasMatchedNode;
}

@end
