
#import "PHFetchResult+CameraUpload.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "SavedIdentifierParser.h"
#import "PHAsset+CameraUpload.h"

@implementation PHFetchResult (CameraUpload)

- (NSArray<PHAsset *> *)findNewAssetsBySortedUploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    return [self findNewAssetsBySortedUploadRecords:records forLivePhoto:NO];
}

- (NSArray<PHAsset *> *)findNewLivePhotoAssetsBySortedUploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    return [self findNewAssetsBySortedUploadRecords:records forLivePhoto:YES];
}

- (NSArray<PHAsset *> *)findNewAssetsBySortedUploadRecords:(NSArray<MOAssetUploadRecord *> *)records forLivePhoto:(BOOL)livePhoto {
    if (self.count == 0) {
        return @[];
    }
    
    NSMutableArray<NSString *> *sortedLocalIds = [NSMutableArray arrayWithCapacity:records.count];
    for (MOAssetUploadRecord *record in records) {
        if (record.localIdentifier) {
            [sortedLocalIds addObject:record.localIdentifier];
        }
    }
    NSComparator localIdComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    SavedIdentifierParser *identifierParser = [[SavedIdentifierParser alloc] init];
    
    NSMutableArray<PHAsset *> *newAssets = [NSMutableArray array];
    for (PHAsset *asset in self) {
        NSString *identifier = asset.localIdentifier;
        if (livePhoto) {
            if (!asset.mnz_isLivePhoto) {
                continue;
            }
            
            identifier = [identifierParser savedIdentifierForLocalIdentifier:identifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
        }
        
        NSUInteger matchingIndex = [sortedLocalIds indexOfObject:identifier inSortedRange:NSMakeRange(0, sortedLocalIds.count) options:NSBinarySearchingFirstEqual usingComparator:localIdComparator];
        if (matchingIndex == NSNotFound) {
            [newAssets addObject:asset];
        }
    }
    
    return [newAssets copy];
}


@end
